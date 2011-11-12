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


function [u, v, w, p] = tv_l1_motion_primal_dual(I1, I2, u, v, w, p, lambda, ...
                                                warps, maxits, scale, silent_mode)

[M N C] = size(I1);

% stepwidth
L = sqrt(8);

tau = 1/L;
sigma = 1/L;

u_ = u;
v_ = v;
w_ = w;

% some parameters
epsilon_u = 0;
epsilon_w = 0;
gamma = 0.02;

for j = 1:warps
   
  u0 = u;
  v0 = v;
  
  % warping
  if silent_mode < 1
    fprintf('tv-l1-of-pd: warp = %d\n', j);
  end
  
  [I_x, I_y, I_t, I_2_warped] = warping(I1, I2, u0, v0);

  I_grad_sqr = max(1e-09, I_x.^2 + I_y.^2 + gamma*gamma);  
 
  for k = 0:maxits-1
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DUAL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % compute derivatives
   
    u_x = dxp(u_);
    u_y = dyp(u_);
    
    v_x = dxp(v_);
    v_y = dyp(v_);
  
    w_x = dxp(w_);
    w_y = dyp(w_);
    
    % update dual variable
    p(:,:,1) = (p(:,:,1) + sigma*u_x)/(1 + sigma*epsilon_u);
    p(:,:,2) = (p(:,:,2) + sigma*u_y)/(1 + sigma*epsilon_u);

    p(:,:,3) = (p(:,:,3) + sigma*v_x)/(1 + sigma*epsilon_u);
    p(:,:,4) = (p(:,:,4) + sigma*v_y)/(1 + sigma*epsilon_u);
    
    p(:,:,5) = (p(:,:,5) + sigma*w_x)/(1 + sigma*epsilon_w);
    p(:,:,6) = (p(:,:,6) + sigma*w_y)/(1 + sigma*epsilon_w);    
    
    % reprojection to |pu| <= 1
    reprojection = max(1.0, sqrt(p(:,:,1).^2 + p(:,:,2).^2 + p(:,:,3).^2 + p(:,:,4).^2));
    p(:,:,1) = p(:,:,1)./reprojection;
    p(:,:,2) = p(:,:,2)./reprojection;
    p(:,:,3) = p(:,:,3)./reprojection;
    p(:,:,4) = p(:,:,4)./reprojection;
    
    reprojection = max(1.0, sqrt(p(:,:,5).^2 + p(:,:,6).^2));
    p(:,:,5) = p(:,:,5)./reprojection;
    p(:,:,6) = p(:,:,6)./reprojection;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PRIMAL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % compute divergence
    
    div_u = dxm(p(:,:,1)) + dym(p(:,:,2));
    div_v = dxm(p(:,:,3)) + dym(p(:,:,4));
    div_w = dxm(p(:,:,5)) + dym(p(:,:,6));
    
    % remember old u,v,w
    u_ = u;
    v_ = v;
    w_ = w;
    
    % update u,v,w
    u = u + tau*(div_u);
    v = v + tau*(div_v);
    w = w + tau*(div_w);
    
    % prox operator for u,v,w
    
    rho = I_t + (u-u0).*I_x + (v-v0).*I_y + gamma*w;
    idx1 = rho      < - tau*lambda*I_grad_sqr;
    idx2 = rho      >   tau*lambda*I_grad_sqr;
    idx3 = abs(rho) <=  tau*lambda*I_grad_sqr;
    
    u(idx1) = u(idx1) + tau*lambda*I_x(idx1);
    v(idx1) = v(idx1) + tau*lambda*I_y(idx1);
    w(idx1) = w(idx1) + tau*lambda*gamma;
    
    u(idx2) = u(idx2) - tau*lambda*I_x(idx2);
    v(idx2) = v(idx2) - tau*lambda*I_y(idx2);
    w(idx2) = w(idx2) - tau*lambda*gamma;
    
    u(idx3) = u(idx3) - rho(idx3).*I_x(idx3)./I_grad_sqr(idx3);
    v(idx3) = v(idx3) - rho(idx3).*I_y(idx3)./I_grad_sqr(idx3);
    w(idx3) = w(idx3) - rho(idx3).*gamma./I_grad_sqr(idx3);
    
    u_ = 2*u - u_;
    v_ = 2*v - v_;
    w_ = 2*w - w_;
    
    if mod(k,10) == 0
      if silent_mode < 1
        show_flow(u,v,gamma*w,I1,I_2_warped + (u-u0).*I_x + (v-v0).*I_y + gamma*w);
        fprintf('tv-l1-motion-primal-dual: it = %d\n', k)
      end
    end

  end
  
  % filter strong outliers
  u = peakfilt(u);
  v = peakfilt(v);
end