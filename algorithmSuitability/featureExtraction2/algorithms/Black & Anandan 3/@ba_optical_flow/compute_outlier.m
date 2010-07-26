function [os od] = compute_outlier(this, uv)
%COMPUTE_OUTLIER computes outliers for both the spatial term (os) and the 
%  data term (od), for the Black and Anandan method that uses the Lorentzian
%   penalty function
%
%   This is a member function of the class 'ba_optical_flow'. 
%
%   Author: Deqing Sun, Department of Computer Science, Brown University
%   Contact: dqsun@cs.brown.edu
%   $Date: 2007-11-30 $
%
% Copyright 2007-2008, Brown University, Providence, RI.
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


% Spatial term
S = this.spatial_filters;

os = false(size(uv,1), size(uv,2));
for i = 1:length(S)

    u_ = conv2(uv(:,:,1), S{i}, 'same');
    v_ = conv2(uv(:,:,2), S{i}, 'same');

    if isa(this.rho_spatial_u{i}, 'robust_function')
        
        os = os | abs(u_) > this.rho_spatial_u{i}.param/sqrt(3) | ...
                abs(v_) > this.rho_spatial_v{i}.param/sqrt(3);
        
    else
        error('compute_outlier: unknown rho function to compute outliers!');
    end;
end;

% Data term
It  = partial_deriv(this.images, uv, this.interpolation_method);    
    
if isa(this.rho_data, 'robust_function')

    od = abs(It) > this.rho_data.param/sqrt(3);
    
else
    error('compute_outlier: unknown rho function to compute outliers!');
end;