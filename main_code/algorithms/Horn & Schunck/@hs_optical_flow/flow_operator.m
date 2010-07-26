function [A, b, params, iterative] = flow_operator(this, uv, duv, It, Ix, Iy)
%FLOW_OPERATOR   Linear flow operator (equation) for flow estimation
%   [A, b] = FLOW_OPERATOR(THIS, UV, INIT)  
%   returns a linear flow operator (equation) of the form A * x = b.  The
%   flow equation is linearized around UV with the initialization INIT
%   (e.g. from a previous pyramid level).  
%
%   [A, b, PARAMS, ITER] = FLOW_OPERATOR(...) returns optional parameters
%   PARAMS that are to be passed into a linear equation solver and a flag
%   ITER that indicates whether solving for the flow requires multiple
%   iterations of linearizing.
%  
%   This is a member function of the class 'hs_optical_flow'. 

% Authors: Deqing Sun, Department of Computer Science, Brown University
%          Stefan Roth, Department of Computer Science, TU Darmstadt
% Contact: dqsun@cs.brown.edu, sroth@cs.tu-darmstadt.de
% $Date: 2008-10-28$
% $Revision: 0 $
%
% Copyright 2007-2008, Brown University, Providence, RI. USA
% 		     TU Darmstadt, Darmstadt, Germany 
% 
%                         All Rights Reserved
% 
% Permission to use, copy, modify, and distribute this software and its
% documentation for any purpose other than its incorporation into a
% commercial product is hereby granted without fee, provided that the
% above copyright notice appear in all copies and that both that
% copyright notice and this permission notice appear in supporting
% documentation, and that the name of the author and Brown University not be used in
% advertising or publicity pertaining to distribution of the software
% without specific, written prior permission.
% 
% THE AUTHOR AND BROWN UNIVERSITY DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
% INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR ANY
% PARTICULAR PURPOSE.  IN NO EVENT SHALL THE AUTHOR OR BROWN UNIVERSITY BE LIABLE FOR
% ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.   

  % Perform linearization
  It = It + Ix.*repmat(duv(:,:,1), [1 1 size(It,3)]) ...
          + Iy.*repmat(duv(:,:,2), [1 1 size(It,3)]);
 
  uv = uv+duv; 
  
  sz        = [size(Ix,1) size(Ix,2)];
  npixels   = prod(sz);

  % Spatial/prior term
  L     = [0 1 0; 1 -4 1; 0 1 0];     % Laplacian operator
  F     = make_imfilter_mat(L, sz, 'replicate', 'same');

  % Replicate operator for u and v
  M     = [F, sparse(npixels, npixels);
           sparse(npixels, npixels), F];

  % Data term
  
  % For color processing
  Ix2 = mean(Ix.^2, 3);
  Iy2 = mean(Iy.^2, 3);
  Ixy = mean(Ix.*Iy, 3);
  Itx = mean(It.*Ix, 3);
  Ity = mean(It.*Iy, 3);

  duu   = spdiags(Ix2(:), 0, npixels, npixels);
  dvv   = spdiags(Iy2(:), 0, npixels, npixels);
  duv   = spdiags(Ixy(:), 0, npixels, npixels);

  % Compute the operator
  A     = [duu duv; duv dvv]/this.sigmaD2 - this.lambda*M/this.sigmaS2;
  
  b     = this.lambda *M*uv(:)/this.sigmaS2 - [Itx(:); Ity(:)]/this.sigmaD2;
  
  % No auxiliary parameters
  params    = [];
  % The quadratic formulation of H&S ensures one linearization per warping
  if max(b(:)) - min(b(:)) < 1E-6
    iterative = false;
  else
    iterative = true;
  end