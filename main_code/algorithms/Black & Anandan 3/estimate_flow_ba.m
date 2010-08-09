function uv = estimate_flow_ba(im1, im2, varargin)
%UV = ESTIMATE_FLOW_BA(IM1, IM2)   Optical flow computation using Horn & Schunck's method
%   takes in two input images IM1 IM2 (grayscle or color) and compute the
%   flow field from IM1 to IM2 using default parameters. 
%
% output UV is an M*N*2 matrix. UV(:,:,1) is the horizontal flow and
% UV(:,:,2) is the vertical flow.
%
%UV = ESTIMATE_FLOW_BA(IM1, IM2, 'PARAMETER1 NAME', PARAMETER1 VALUE, 'PARAMETER2 NAME', PARAMETER2 VALUE ...);
%   uses the parameters provided to estimate the flow field, including
%     'lambda'                trade-off (regularization) parameter for the B&A formulation; default is 0.1, larger produces smoother flow fields 
%     'lambda_q'              trade-off (regularization) parameter for the quadratic formulation used in the GNC optimization; default is 0.05
%     'sigma_d'               parameter of the Lorentzian robust penalty function for the spatial term
%     'sigma_s'               parameter of the Lorentzian robust penalty function for the data term
%     'pyramid_levels'        pyramid levels for the quadratic formulation; default is 4
%     'pyramid_spacing'       reduction ratio up each pyramid level for the quadratic formulation; default is 2
%     'gnc_pyramid_levels'    pyramid levels for the B&A formulation; default is 2
%     'gnc_pyramid_spacing'   reduction ratio up each pyramid level for the B&A formulation; default is 1.25
%
%
% Authors: Deqing Sun, Department of Computer Science, Brown University
%          Stefan Roth, Department of Computer Science, TU Darmstadt
% Contact: dqsun@cs.brown.edu, sroth@cs.tu-darmstadt.de
% $Date: 2008-10-28$
% $Revision: 0 $
%
% Copyright 2007-2008, Brown University, Providence, RI. USA
%                      TU Darmstadt, Darmstadt, Germany 
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

% addpath(genpath('utils'));

% Load flow estimation method
ope           = ba_optical_flow;
ope.display   = false;        % uncomment to avoid printing information
% ope.solver    = 'pcg'; 

% Parse parameters 
if length(varargin) >=2
    ope = parse_input_parameter(ope, varargin);
end;    

% 2009-3-23 modified by dqsun to deal with input integer images
if isinteger(im1);
    im1 = double(im1);
    im2 = double(im2);
end;

ope.images  = cat(length(size(im1))+1, im1, im2);
uv          = compute_flow(ope, zeros([size(im1,1) size(im1,2) 2]));

% Uncomment below if you do not want to add 'utils/' to your
% matlab search path

% rmpath(genpath('utils'));