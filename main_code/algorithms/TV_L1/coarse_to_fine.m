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

function [flow w] = coarse_to_fine(I1, I2, lambda, warps, maxits, ...
                                 pyramid_levels, pyramid_factor, silent_mode);

[M N C] = size(I1);

num_dual_vars = 6;

width_Pyramid = cell(pyramid_levels,1);
height_Pyramid = cell(pyramid_levels,1);

I1_Pyramid = cell(pyramid_levels,C);
I2_Pyramid = cell(pyramid_levels,C);

% precompute image sizes
width_Pyramid{1} = N;
height_Pyramid{1} = M;


for i = 2:pyramid_levels
  width_Pyramid{i} = pyramid_factor*width_Pyramid{i-1};
  height_Pyramid{i} = pyramid_factor*height_Pyramid{i-1};
  if min(width_Pyramid{i}, height_Pyramid{i}) < 16
    pyramid_levels = i;
    break;
  end
end
for i = 1:pyramid_levels
  width_Pyramid{i} = round(width_Pyramid{i});
  height_Pyramid{i} = round(height_Pyramid{i});
end


% set up image pyramides
for i = 1:pyramid_levels
  if i == 1
    for j=1:C
      I1_Pyramid{1,j} = I1(:,:,j);
      I2_Pyramid{1,j} = I2(:,:,j);
    end
  else
    for j=1:C    
      I1_Pyramid{i,j} = imresize(I1_Pyramid{i-1,j}, ...
                                 [height_Pyramid{i} width_Pyramid{i}], 'bicubic');
      I2_Pyramid{i,j} = imresize(I2_Pyramid{i-1,j}, ...
                                 [height_Pyramid{i} width_Pyramid{i}], 'bicubic');     
    end
  end
end

for level = pyramid_levels:-1:1;
  
  scale = pyramid_factor^(level-1);
  
  M = height_Pyramid{level};
  N = width_Pyramid{level};
 
  if level == pyramid_levels
 
    % initialization  
    u = zeros(M,N);
    v = zeros(M,N);
    w = zeros(M,N);
    p = zeros(M,N,num_dual_vars);   
  else
    rescale_factor_u = width_Pyramid{level+1}/width_Pyramid{level};
    rescale_factor_v = height_Pyramid{level+1}/height_Pyramid{level};
    
    % prolongate to finer grid    
    u = imresize(u,[M N], 'nearest')/rescale_factor_u;    
    v = imresize(v,[M N], 'nearest')/rescale_factor_v;
    w = imresize(w, [M N], 'nearest');
    
    p_tmp = p;
    p = zeros(M,N,num_dual_vars); 
    for i=1:num_dual_vars
      p(:,:,i) = imresize(p_tmp(:,:,i),[M N], 'nearest');
    end
  end
  
  I1 = zeros(M,N,C);
  I2 = zeros(M,N,C);
  for j=1:C
    I1(:,:,j) = I1_Pyramid{level,j};
    I2(:,:,j) = I2_Pyramid{level,j};
  end
  
  if exist('silent_mode','var')==0
    silent_mode=0;
  end

  if silent_mode < 2
    fprintf('*** level = %d\n', level);
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  [u, v, w, p] = tv_l1_motion_primal_dual ...
      (I1, I2, u, v, w, p, lambda, warps, maxits, scale, silent_mode);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
end

% store final flow
flow = zeros(M,N,2);
flow(:,:,1) = u;
flow(:,:,2) = v;
