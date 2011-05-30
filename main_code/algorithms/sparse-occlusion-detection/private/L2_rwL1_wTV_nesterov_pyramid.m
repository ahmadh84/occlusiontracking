function [uv, e, ebar, report] ...
		= L2_rwL1_wTV_nesterov_pyramid(I0, I1, pyrlevels, pyrfactor, warps, params)
% L2_RWL1_WTV_NESTEROV_PYRAMID Computes the flow field UV registering image I0 to I1
% 
% [UV, E, REPORT] = L2_RWL1_WTV_NESTEROV_PYRAMID(I0, I1, PYRLEVELS, PYRFACTOR, WARPS, PARAMS)
% INPUT: 
%   I0,I1     : The images at time t and t+dt
%   PYRLEVELS : # of levels at the pyramid
%   PYRFACTOR : pyramid factor
%   WARPS     : # of warps at each pyramid level
%   PARAMS    : Parameter set
%
% OUTPUT: 
%   UV     : Estimated flow field
%   E      : The weighted error term (We)
%   EBAR   : The error term (e)
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

	[uv,e,report] = Huber_L1_wTV_nesterov_pyramid(I0, I1, pyrlevels, pyrfactor, warps, params);
	report.HuberL1wTV.uv = uv; 
	report.HuberL1wTV.e = e;
	u = uv(:,:,1); v = uv(:,:,2);
	
	% DEBUG CODE
	% save('temp_', 'u', 'v');
	% env = load('temp_'); u = env.u; v = env.v; 
	% report = [];

	if (size(I0,3) > 1); iscolor = true; else iscolor = false; end;
	params.iscolor = iscolor;

	%% Convert images to grayscale if they are not. Also scale intensity values to [0,1]
	if(iscolor)
		I0color = I0; I1color = I1;
		I0 = rgb2gray(I0); 
		I1 = rgb2gray(I1); 
	end
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%                                                                         REWEIGHTING	

	% the size of the image at the current level
	I0 = double(I0)/255; I1 = double(I1)/255; 
	[M N] = size(I0); MN = M * N;
	ebar = compute_residual(I0, I1, cat(3,u,v));
	ebar(isnan(ebar)) = 0;
	e = zeros(M,N);
	
	u0 = u; v0 = v; I0_ = I0; I1_ = I1;
	if iscolor; params.I0color = I0color; end
	
	idx = repmat([1:N], M,1); idy = repmat([1:M]',1,N);
	
	%% Compute the spatial derivatives
	mask = [1 -8 0 8 -1]/12; 
	
	Ix = imfilter(I0_, mask, 'replicate');
  Iy = imfilter(I0_, mask','replicate');

	params.alpha = params.rwalpha * params.lambda;
		
	%% Repeat the reweighting iterations till it converge or reaches the 
	%% maximum number of itrations
	k = 1; stop = false; 
	params.doreweighted = true;
	while k < params.maxrwiters & ~stop
		fprintf('Reweighting warp %d\n', k);
		
    %% Apply median filterin on the motion field
    u0 = medfilt2(u, [5 5], 'symmetric'); 
    v0 = medfilt2(v, [5 5], 'symmetric');
		e0 = e;
		ebar0 = ebar;

    idxx = idx + u0; idyy = idy + v0;

		%% Compute the temporal derivative
    I1warped = interp2(I1_, idxx, idyy,'linear');
    It = I1warped - I0_;

    %% boundary handling
    m = (idxx > N) | (idxx < 1) | (idyy > M) | (idyy < 1);
    Ix(m) = 0.0; Iy(m) = 0.0; It(m) = 0.0;
		
		%% Estimate the motion from I0 to warped I
		[u, v, e, ebar] = L2_rwL1_wTV_nesterov(I0_, I1warped, u0, v0, e0, ebar0, Ix, Iy, It, params);

		if norm(vec(e-e0) / MN, 1) < 1e-5
			stop = true;
		end

		k = k+1;
		
	end
	
	uv = cat(3, u, v);	
end
