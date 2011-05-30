function [u, v] = Huber_L1_wTV_nesterov(I0, I1warped, u0, v0, Ix, Iy, It, params)
% HUBER_L1_WTV_NESTEROV Computes the flow field (u,v) warping image I0 to I1
%                       minimizing the Huber-L1-weighted-TV model
% 
% [U, V] = HUBER_L1_WTV_NESTEROV(I0, I1WARPED, U0, V0, IX, IY, IT, PARAMS)
% INPUT: 
%   I0         : Initial image
%   I1WARPED   : I1 warped under the flow field (u0,v0)
%   U0, V0     : Initial flow field
%   IX, IY, IT : Image derivatives
%	
% OUTPUT: 
%   U,V : Flow field
%
% Copyright (C) 2010 Alper Ayvaci, Michalis Raptis
%
% This file is available under the terms of the
% GNU GPLv2, or (at your option) any later version.
%
% ------------------------------------------------------- 
% AUTHOR Alper Ayvaci, Michalis Raptis (UCLA Vision Lab)
% -------------------------------------------------------

  [M N] = size(I0); 

  A = [diag(sparse(vec(Ix))) diag(sparse(vec(Iy)))];  
  b  = vec(It);

	%% Compute weighted derivative operators to regularize the field
	if params.iscolor
		[D1 D2] = weighted_derivative_ops_color(M, N, params.I0color, params.beta, params.nu);
		D = [D1; D2];
	else
		[D1 D2] = weighted_derivative_ops_grayscale(M, N, I0, params.beta, params.nu);
		D = [D1; D2];
	end

  %% Solve the minimization problemoptimize
  x = Huber_L1_wTV_nesterov_core(A, b, vec(u0), vec(v0), D, M, N, params);

  x = reshape(x, [M*N 2]);
  u = reshape(x(:,1), [M N]);
  v = reshape(x(:,2), [M N]);
end
