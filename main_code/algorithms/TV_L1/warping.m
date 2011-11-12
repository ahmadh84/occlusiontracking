%   TV-L1 optical flow
%
%   Author: Thomas Pock
%
%   If you use this file or package for your work, please refer to the
%   following papers:
% 
%   [1] Antonin Chambolle and Thomas Pock, A first-order primal-dual
%   algorithm with applications to imaging, Technical Report, 2010
%
%
%   License:
%     Copyright (C) 2009 Institute for Computer Graphics and Vision,
%                      Graz University of Technology
% 
%     This program is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see
%     <http://www.gnu.org/licenses/>.

function [I_x, I_y, I_t, I2_warped] = warping(I1, I2, u, v)

[M N C] = size(I1);

idx = repmat([1:N], M,1);
idy = repmat([1:M]',1,N);
 
idxx = idx + u;
idyy = idy + v;
m = (idxx > N-1) | (idxx < 2) | (idyy > M-1) | (idyy < 2);

idxx = max(1,min(N,idxx));
idxm = max(1,min(N,idxx-0.5));
idxp = max(1,min(N,idxx+0.5));

idyy = max(1,min(M,idyy));
idym = max(1,min(M,idyy-0.5));
idyp = max(1,min(M,idyy+0.5));

I2_warped = interp2(I2,idxx,idyy,'cubic');
I2_x_warped = interp2(I2,idxp,idyy,'cubic') - interp2(I2,idxm,idyy,'cubic');
I2_y_warped = interp2(I2,idxx,idyp,'cubic') - interp2(I2,idxx,idym,'cubic');

% use everage to improve accuracy
I_x = I2_x_warped;
I_y = I2_y_warped;

I_t = I2_warped  - I1;

% boundary handling
I_x(m) = 0.0;
I_y(m) = 0.0;
I_t(m) = 0.0;