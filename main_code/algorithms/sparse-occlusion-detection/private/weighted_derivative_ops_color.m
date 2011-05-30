function [D1 D2] = weighted_derivative_ops_color(M, N, I0, beta, nu)
% WEIGHTED_DERIVATIVE_OPS_COLOR  Computes the weighted derivative operators
%	                               in x- and y-direction
% 
% [D1, D2] = WEIGHTED_DERIVATIVE_OPS_COLOR(M,N, I0, BETA, NU)
% INPUT: 
%   M,N     : Image size
%	  I0      : color image to compute the weights
%   BETA,NU : weight(x) = nu + (1-nu) exp(-beta \| \nabla(I0(x)) \|_2)
%	
% OUTPUT: 
%   D1,D2 : Derivative operators in x- and y-direction. Both are MNxMN sparse matrices.
%
% Copyright (C) 2010 Alper Ayvaci, Michalis Raptis
%
% This file is available under the terms of the
% GNU GPLv2, or (at your option) any later version.
%
% ------------------------------------------------------- 
% AUTHOR Alper Ayvaci, Michalis Raptis (UCLA Vision Lab)
% -------------------------------------------------------

	%% Convert RGB image to LAB
	I0LAB = vl_xyz2lab(vl_rgb2xyz(double(I0)/255)); I0RGB = double(I0);

	MN = M*N;
	[X,Y]  = meshgrid(1:N, 1:M);

	%% Derivative in X direction
	edges = [ vec(sub2ind([M N], Y(:, 1:end-1), X(:, 1:end-1))) ...
	          vec(sub2ind([M N], Y(:, 1:end-1), X(:, 1:end-1)+1)) ];
	nedges = size(edges, 1);

	%% Compute image features
	weights = makeweights(edges, [vec(I0LAB(:,:,1)) vec(I0LAB(:,:,2)) vec(I0LAB(:,:,3))], beta);

	weights_ = nu + (1-nu)*weights;  
	%% The derivative operator in X direction
	D1 = sparse([edges(:,1); edges(:, 1)], [edges(:, 1); edges(:,2)], [-weights_; weights_], MN, MN);

	%% Derivative in Y direction
	edges = [vec(sub2ind([M N], Y(1:end-1,:), X(1:end-1,:)))  ...
	         vec(sub2ind([M N], Y(1:end-1,:)+1, X(1:end-1,:)))];
					
	nedges = size(edges, 1);

	%% Compute image features
	weights = makeweights(edges, [vec(I0LAB(:,:,1)) vec(I0LAB(:,:,2)) vec(I0LAB(:,:,3))], beta);

	weights_ = nu + (1-nu)*weights;  

	%% The derivative operator in Y direction
	D2 = sparse([edges(:,1); edges(:, 1)], [edges(:, 1); edges(:,2)], [-weights_; weights_], MN, MN);

end