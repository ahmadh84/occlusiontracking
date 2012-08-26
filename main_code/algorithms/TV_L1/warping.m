%
%   Duality-based TV-L1 Optical Flow
%
%   Author: Thomas Pock
%
%   If you use this file or package for your work, please refer to the 
%   following paper:
%     @INPROCEEDINGS{Zach2007_OpticalFlow,
%       author = {C. Zach and T. Pock and H. Bischof} ,
%       title = {A Duality Based Approach for Realtime TV-L1 Optical Flow},
%       pages = {214--223} ,
%       year = {2007} ,
%       booktitle = {Pattern Recognition (Proc. DAGM)} ,
%       address = {Heidelberg, Germany} ,
%     }
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
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.


function [u, v, u_, v_, pu, pv] = warping(u, v, u_, v_, pu, pv, ...
                                          I1, I2, lambda, theta, epsilon, ...
                                          use_edges, maxits, level, warps, ...
                                          g)

[M N] = size(I1);

idx = repmat([1:N], M,1);
idy = repmat([1:M]',1,N);

% mask for computing spatial derivatives
mask = [1 -8 0 8 -1]/12;

I1_x = imfilter(I1, mask, 'replicate');
I1_y = imfilter(I1, mask', 'replicate');

I2_x = imfilter(I2, mask, 'replicate');
I2_y = imfilter(I2, mask', 'replicate');

% warping
for i=1:warps
  
  % new point for linearization
  % median filter helps to jump over local minima.
  % The algorithm is not affected by the median since
  % u0,v0 is just an initialization!
  u0 = medfilt2(u_,[3 3], 'symmetric'); 
  v0 = medfilt2(v_,[3 3], 'symmetric'); 
  
  idxx = idx + u0;
  idyy = idy + v0;
  
  I2_warped = interp2(I2,idxx,idyy,'linear');
  I2_x_warped = interp2(I2_x,idxx,idyy,'linear');
  I2_y_warped = interp2(I2_y,idxx,idyy,'linear');
  
  I_x = 0.5*(I1_x + I2_x_warped);
  I_y = 0.5*(I1_y + I2_y_warped);
  I_t = I2_warped  - I1;
  
  % boundary handling
  m = (idxx > N) | (idxx < 1) | (idyy > M) | (idyy < 1);
  
  I_x(m) = 0.0;
  I_y(m) = 0.0;
  I_t(m) = 0.0;
  
  I_grad_sqr = max(1e-06, I_x.^2 + I_y.^2);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % solve TV-L1 optical flow
  [u, v, u_, v_, pu, pv] = tv_l1_of_dual_pgd(u, v, u_, v_, u0, v0, pu, pv, ...
                                             I_x, I_y, I_t, I_grad_sqr, g, ...
                                             lambda, theta, epsilon, maxits);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %fprintf('TV-L1 Optical Flow: level = %d, warp = %d\n', level, i);
  
  % find robust max flow for better visualization
  magnitude = (u.^2 + v.^2).^0.5;  
  max_flow = prctile(magnitude(:),95);
  
  tmp = zeros(M,N,2);
  tmp(:,:,1) = min(max(u,-max_flow),max_flow);
  tmp(:,:,2) = min(max(v,-max_flow),max_flow);
    
  %figure(1), subplot(1,2,2), imshow(uint8(flowToColor(tmp)),[]);
  %drawnow;
end