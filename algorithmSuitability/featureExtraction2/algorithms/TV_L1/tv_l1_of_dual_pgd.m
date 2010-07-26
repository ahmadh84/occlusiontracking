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

function [u, v, u_, v_, pu, pv] = tv_l1_of_dual_pgd(u, v, u_, v_, u0, v0, pu, pv, ...
                                                  I_x, I_y, I_t, I_grad_sqr, g, ...
                                                  lambda, theta, epsilon, maxits)
% stepwidth
tau = 1.0/(4.0*theta+epsilon);
  
for k = 1:maxits
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 1. thresholding scheme
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  r = I_t + (u-u0).*I_x + (v-v0).*I_y;
  idx1 = r < - lambda*theta*I_grad_sqr;
  idx2 = r > + lambda*theta*I_grad_sqr;
  idx3 = abs(r) <= lambda*theta*I_grad_sqr;
  
  u_ = u;
  u_(idx1) = u_(idx1) + lambda*theta*I_x(idx1);
  u_(idx2) = u_(idx2) - lambda*theta*I_x(idx2);
  u_(idx3) = u_(idx3) - r(idx3)./I_grad_sqr(idx3).*I_x(idx3);
  
  v_ = v;
  v_(idx1) = v_(idx1) + lambda*theta*I_y(idx1);
  v_(idx2) = v_(idx2) - lambda*theta*I_y(idx2);
  v_(idx3) = v_(idx3) - r(idx3)./I_grad_sqr(idx3).*I_y(idx3);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 2. Duality based projected gradient descend scheme
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
  % compute divergence
  div_u = dxm(pu(:,:,1)) + dym(pu(:,:,2));
  div_v = dxm(pv(:,:,1)) + dym(pv(:,:,2));
  
  % compute u
  u = u_ + theta*div_u;
  
  % compute v
  v = v_ + theta*div_v;

  % compute derivatives
  u_x = dxp(u);
  u_y = dyp(u);
  
  % compute derivatives
  v_x = dxp(v);
  v_y = dyp(v);
  
  % update dual variable
  pu(:,:,1) = pu(:,:,1) + tau*(u_x - epsilon*pu(:,:,1));
  pu(:,:,2) = pu(:,:,2) + tau*(u_y - epsilon*pu(:,:,2));
  
  % update dual variable
  pv(:,:,1) = pv(:,:,1) + tau*(v_x - epsilon*pv(:,:,1));
  pv(:,:,2) = pv(:,:,2) + tau*(v_y - epsilon*pv(:,:,2));
  
  % reprojection to |pu| <= 1
  reprojection = max(1.0, sqrt(pu(:,:,1).^2 + pu(:,:,2).^2)./g);
  pu(:,:,1) = pu(:,:,1)./reprojection;
  pu(:,:,2) = pu(:,:,2)./reprojection;
  
  % reprojection to |pv| <= 1
  reprojection = max(1.0, sqrt(pv(:,:,1).^2 + pv(:,:,2).^2)./g);
  pv(:,:,1) = pv(:,:,1)./reprojection;
  pv(:,:,2) = pv(:,:,2)./reprojection;
end
