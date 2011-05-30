function [xk report] = L2_rwL1_wTV_nesterov_core(A, b, u0, v0, e0, D, M, N, params)
% L2_RWL1_WTV_NESTEROV_CORE The core function minimizing the problem
%                           |A[u, v] + b + We|^2_L2 + |e|_L1 + |u+u0|_wTV + |v+v0|_wTV 
% 
% XK = L2_RWL1_WTV_NESTEROV_CORE(A, B, U0, V0, D, M, N, PARAMS)
% INPUT: 
%   A     : The structure matrix [diag(Ix) diag(Iy) diag(W)]
%   B     : Temporal derivative It
%   U0,V0 : Initial flow fields
%   E0    : Initial sparse error term
%   D     : Weighted derivative operators
%   M,N   : Size of the original image
%   PARAMS: Parameter set
%
% OUTPUT: 
%   XK : The minimizer
%
% Copyright (C) 2010 Alper Ayvaci, Michalis Raptis
%
% This file is available under the terms of the
% GNU GPLv2, or (at your option) any later version.
%
% ------------------------------------------------------- 
% AUTHOR Alper Ayvaci, Michalis Raptis (UCLA Vision Lab)
% -------------------------------------------------------

	MN = size(u0,1); MN2 = 2*MN; MN3 = 3*MN; % number of variables
	
	%% Precompute 

  At = A';
  Atb = At*b;
  AtA = At * A;
  AAt = A * At;
  normAtA = max(diag(AAt));
  
  D1 = D(1:MN, :);
  D2 = D(MN+1:end, :);
  Dt = D';
	
	%% Parameters
	alpha = params.alpha;
	lambda = params.lambda;
	mu_tv = params.mu_tv;	
	mu_e = params.mu_e;
	
  %% Initialize
  x0 = [zeros(MN2,1); e0];
  xk = x0;
	xold = xk;
	
	%% Compute the Lipschitz constant
	L = compute_lipschitz_constant(normAtA, alpha, lambda, mu_tv, mu_e);
	
	%% Solve the problem iteratively
	stats.f= zeros(1, params.maxiters);
	stats.energy = zeros(1, params.maxiters);
	stats.conver = zeros(1, params.maxiters);
	
	k = 0; iter = 1; stop = false; wdf = 0; 
	while ~stop & iter < params.maxiters 

		%% step (1) compute the derivative
    [df f] = compute_df(xk, A, b, AtA, Atb, Dt, D1, D2, u0, v0, alpha, lambda, mu_tv, mu_e);

    %% step (2) update yk
    yk = xk - (1/L)*df;

    %% step (3) update zk
    alphak = (k+1) / 2;
    wdf = wdf + alphak*df;
    zk = x0 - (1/L) * wdf;

    %% step (4) blend yk and zk
    tauk = 2 / (k + 3); 
    xkp = tauk * zk + (1-tauk) * yk;
    xk=xkp; 

    %% stopping criteria
		
		% compute statistics
		stats.energy(iter) = f;
		
		if(iter > 10) 
			iterm10 = iter - 10;
			fbar = mean(stats.energy(iterm10:iter));
			convergence = abs(f - fbar) / fbar;
			
			if convergence  < 1e-5
				stop = true;
			end
		end
		
    % visualize steps
    if params.display & ((mod((k+1),100) == 1) | (stop == true) | ((iter+1) == params.maxiters))
    	visualize(k, xk, stats, A, b, u0, v0, M, N);
    end

		xold = xk; 
    k = k+1;
		iter = iter + 1;
  end

	xk = xk + [u0; v0; zeros(MN,1)]; 
end

function L = compute_lipschitz_constant(normAtA, alpha, lambda, mu_tv, mu_e)
  L = max(8*alpha/mu_tv, lambda/mu_e) + normAtA;
end

function [df f] = compute_df(x, A, b, AtA, Atb, Dt, D1, D2, u0, v0, alpha, lambda, mu_tv, mu_e)
	MN = size(x,1) / 3; MN2 = 2*MN; MN3 = 3*MN;
	
  [df1 f1] = df_l2_Axplusb(x, A, b, AtA, Atb);
	[df2 f2] = df_tv( x(   1: MN), u0, mu_tv, Dt, D1, D2);
  [df3 f3] = df_tv( x(MN+1:MN2), v0, mu_tv, Dt, D1, D2);
	[df4 f4] = df_l1( x(MN2+1:MN3), mu_e);

	df = df1 + [alpha*df2; alpha*df3; lambda*df4];
	f  =  f1 + alpha*(f2 + f3) + lambda*f4;
end
 
%% Computes the derivative of the TV term                                        
function [df f] = df_tv(x, x0, mu, Dt, D1, D2)
  %% see Eq. 17 at Ayvaci, Raptis, Soatto, NIPS'10
	x = x + x0;
  
  D1x = D1*x; D2x = D2*x;
  tvx = sqrt(D1x.*D1x + D2x.*D2x);
  w = max(mu, tvx);
  u1 = D1x ./ w; u2 = D2x ./ w;

  df = Dt * [u1;u2];

	f = sum(tvx);
end

%% Computes the derivative of the L1 term  
function [df f] = df_l1(x, mu)
  %% see Eq. 15 at Ayvaci, Raptis, Soatto, NIPS'10
  df = x ./ max(mu, abs(x));
	f = norm(x,1);
end

function [df f] = df_l2_Axplusb(x, A, b, AtA, Atb)
	df = AtA*x + Atb;
	f = norm(A*x + b, 2);
end

%% Computes the derivative of the Huber-L1 norm on the data term |Ax + b|
function [df f] = df_l1_Axplusb(x, A, b, mu)
  Axplusb = A*x + b;
  df = A' * (Axplusb ./ max(mu, abs(Axplusb)));
	f = huber_l1(Axplusb,mu);
end

%% Computes the Huber-L1 norm of x
function f = huber_l1(x, mu)
	inds = x<= mu; fx = zeros(size(x));
	fx(inds) = x(inds).^2 / (2*mu);
	fx(~inds) = abs(x(~inds)) - (mu/2);
	f = sum(fx);
end
