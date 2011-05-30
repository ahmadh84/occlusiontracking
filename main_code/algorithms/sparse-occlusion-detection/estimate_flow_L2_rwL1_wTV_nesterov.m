function [uv, e, ebar, report] ...
	   = estimate_motion_L2_rwL1_wTV_nesterov(I0, I1, pyrlevels, pyrfactor, warps, params)
% ESTIMATE_MOTION_L2_RWL1_WTV_NESTEROV Sets the default parameters for the flow estimation
%                                      and starts the estimation. 
% 
% [UV, E, REPORT] = ESTIMATE_MOTION_L2_RWL1_WTV_NESTEROV(I0, I1, PYRLEVELS, PYRFACTOR, WARPS, PARAMS)
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
	if nargin < 4
		pyrfactor = .5;
		warps = 5;
		pyrlevels =  5;
	end
	
	if nargin < 6
		% ALPHA is the coefficient of the regularizer. When the option DO_VARYING_ALPHA is selected, 
		% for each pyramid level, its value varies between the values ALPHA0 and ALPHAMAX with the 
		% multiplier ALPHAMULT at each warping step.
		params.do_varying_alpha = true;
		if(params.do_varying_alpha)
			params.alpha0 = 0.006;
			params.alphamult = 5;
			params.alphamax = .8;
		else
			params.alpha = 0.2;
		end
		params.rwalpha = 12;
		
		% LAMBDA is the coefficient of the sparse error term |We|_1 
		params.lambda = 0.004;
		
		% The threshold for Huber-L1 norm for data term/sparse residual term and regularizer.
		params.mu_e = 0.01;	
		params.mu_tv = 0.01;
		params.mu_data = 0.01;
		
		% The gradients are weighted with w(x) = NU - (1-NU) exp(-BETA |\nabla I(x)|^2_2)
		params.beta = 30;
		params.nu = 0.01;
		
		% Apply structure/texture decomposition? 
		params.do_decomposition = true;
		
		params.maxiters = 1500;  % max number of iterations for each minimization problem
		params.maxrwiters = 4;   % max number of reweighting steps
		params.display = true;	 % switch of to display the results
	end
	
	pyrfactor
	warps
	pyrlevels	
	params
	
	[uv, e, ebar, report] ...
		= L2_rwL1_wTV_nesterov_pyramid(I0, I1, pyrlevels, pyrfactor, warps, params);

end
