function [uv, e, report] ...
		= Huber_L1_wTV_nesterov_pyramid(I0, I1, pyrlevels, pyrfactor, warps, params)
% HUBER_L1_WTV_NESTEROV_PYRAMID Computes the flow field UV registering image I0 to I1
% 
% [UV, E, REPORT] = HUBER_L1_WTV_NESTEROV_PYRAMID(I0, I1, PYRLEVELS, PYRFACTOR, WARPS, PARAMS)
% INPUT: 
%   I0,I1     : The images at time t and t+dt
%   PYRLEVELS : # of levels at the pyramid
%   PYRFACTOR : pyramid factor
%   WARPS     : # of warps at each pyramid level
%   PARAMS    : Parameter set
%
% OUTPUT: 
%   UV     : Estimated flow field
%   E      : The residual
%   REPORT : Additional information generated during the estimation 
%
% Copyright (C) 2010 Alper Ayvaci, Michalis Raptis
%
% This file is available under the terms of the
% GNU GPLv2, or (at your option) any later version.
%
% ------------------------------------------------------- 
% AUTHOR Alper Ayvaci, Michalis Raptis (UCLA Vision Lab)
% -------------------------------------------------------
 
	if (size(I0,3) > 1); iscolor = true; else iscolor = false; end;
	params.iscolor = iscolor;
	
	%% Convert images to grayscale if they are not. Also scale intensity values to [0,1]
	if(iscolor)
		I0color = I0; I1color = I1;
		I0 = rgb2gray(I0); I0orig = I0;
		I1 = rgb2gray(I1); I1orig = I1;
	else
		I0orig = I0; I1orig = I1;
	end
	
	%% Do structure/texture decomposition
	if(params.do_decomposition)
		[Itext Istruct]  = structure_texture_decomposition_rof(cat(3,double(I0), double(I1)), 1/8, 100, 0.95);
		I0 = Itext(:,:,1); 
		I1 = Itext(:,:,2);
	end
	
	%% Scale intensity values to [0,1]
	I0 = double(I0) / 255;
	I1 = double(I1) / 255;
	
	%% Construct the image pyramid
	I0pyr = construct_image_pyramid(I0, pyrlevels, pyrfactor);
	I1pyr = construct_image_pyramid(I1, pyrlevels, pyrfactor);
	
	if (iscolor)
		I0colorpyr = construct_image_pyramid(I0color, pyrlevels, pyrfactor);
	end
		
	%% For each pyramid level
	for level = pyrlevels:-1:1
	
		% the size of the image at the current level
		[M N] = size(I0pyr{level});
	
		if level == pyrlevels
			% initialize motion with zero
			u = zeros(M,N); v = zeros(M,N);
	  	else
			% compute scaling factor for motion field and prolongate them to a
			% finer grid
			rescale_u = size(I0pyr{level+1}, 2) / N;
			rescale_v = size(I0pyr{level+1}, 1) / M;
	  	
	    	u = imresize(u, [M N], 'bicubic') / rescale_u;    
	    	v = imresize(v, [M N], 'bicubic') / rescale_v;
	  	end
		
		u0 = u; v0 = v; I0_ = I0pyr{level}; I1_ = I1pyr{level};
		if iscolor; params.I0color = I0colorpyr{level}; end
		
		idx = repmat([1:N], M,1); idy = repmat([1:M]',1,N);
		
		%% Compute the spatial derivatives
		mask = [1 -8 0 8 -1]/12; 
		%mask = [-1 0 1] /2; %alternative
		
		Ix = imfilter(I0_, mask, 'replicate');
	  Iy = imfilter(I0_, mask','replicate');
	
		if params.do_varying_alpha
			params.alpha = params.alpha0;
		end
		
		%% At each pyramid level warp the image several times
		for i=1:warps
				
			fprintf('Pyramid level %d, Warp %d \n', level, i);
			
	    %% Apply median filterin on the motion field
	    u0 = medfilt2(u, [5 5], 'symmetric'); 
	    v0 = medfilt2(v, [5 5], 'symmetric');
	
	    idxx = idx + u0; idyy = idy + v0;
	
			%% Compute the temporal derivative
	    I1warped = interp2(I1_, idxx, idyy,'linear');
	    It = I1warped - I0_;
	
	    % boundary handling
	    m = (idxx > N) | (idxx < 1) | (idyy > M) | (idyy < 1);
	    Ix(m) = 0.0; Iy(m) = 0.0; It(m) = 0.0;
	
			%% Estimate the motion from I0 to warped I
			[u, v] = Huber_L1_wTV_nesterov(I0_, I1warped, u0, v0, Ix, Iy, It, params);
	
			if params.do_varying_alpha
				params.alpha = min(params.alphamult * params.alpha, params.alphamax);
			end
	
		end
	
	end
	
	uv = cat(3, u, v);
	e = compute_residual(double(I0orig)/255, double(I1orig)/255, cat(3,u,v));
	
	report = [];	
end
