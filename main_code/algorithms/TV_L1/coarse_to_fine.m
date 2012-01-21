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

function [flow] = coarse_to_fine(I_key, I1, I2, lambda, theta, epsilon, use_edges, maxits, ...
                                 max_pyramid_levels, pyramid_factor, warps, ...
                                 use_structure_texture, structure_texture_sigma, structure_texture_factor);

[M N] = size(I_key);

width_Pyramid = cell(1,1);
height_Pyramid = cell(1,1);

% precalculate image sizes
pyramid_levels = max_pyramid_levels;
width_Pyramid{1} = N;
height_Pyramid{1} = M;
for i = 2:pyramid_levels
  width_Pyramid{i} = round(pyramid_factor*width_Pyramid{i-1});
  height_Pyramid{i} = round(pyramid_factor*height_Pyramid{i-1});
  if min(width_Pyramid{i}, height_Pyramid{i}) < 16
    pyramid_levels = i;
    break;
  end
end

I1_Pyramid = cell(pyramid_levels,1);
I2_Pyramid = cell(pyramid_levels,1);

g_Pyramid = cell(pyramid_levels,1);

% set up image pyramides
for i = 1:pyramid_levels
  I1_Pyramid{i} = structure_texture_decomposition(imresize(I1, [height_Pyramid{i} width_Pyramid{i}], 'bilinear'), ...
                                                  use_structure_texture, structure_texture_sigma, structure_texture_factor);
  I2_Pyramid{i} = structure_texture_decomposition(imresize(I2, [height_Pyramid{i} width_Pyramid{i}], 'bilinear'), ...
                                                  use_structure_texture, structure_texture_sigma, structure_texture_factor);
  if use_edges == 1
    g_Pyramid{i} = compute_edge_weight(imresize(I_key, [height_Pyramid{i} width_Pyramid{i}], 'bilinear'));
  else
    g_Pyramid{i} = ones(height_Pyramid{i},width_Pyramid{i});
  end
end

% start coarse to fine processing
for level = pyramid_levels:-1:1;
  
  M = height_Pyramid{level};
  N = width_Pyramid{level};
 
  if level == pyramid_levels
 
    % initialization  
    u = zeros(M,N);
    v = zeros(M,N);
    
    u_ = zeros(M,N);
    v_ = zeros(M,N);
    
    pu = zeros(M,N,2);
    pv = zeros(M,N,2);
    
  else
    rescale_factor_u = width_Pyramid{level+1}/width_Pyramid{level};
    rescale_factor_v = height_Pyramid{level+1}/height_Pyramid{level};
    
    % prolongate to finer grid
    u = imresize(u,[M N], 'bilinear')/rescale_factor_u;    
    v = imresize(v,[M N], 'bilinear')/rescale_factor_v;

    u_ = imresize(u_,[M N], 'bilinear')/rescale_factor_u;    
    v_ = imresize(v_,[M N], 'bilinear')/rescale_factor_v;
    
    pu_tmp = pu;
    pv_tmp = pv;
    
    pu = zeros(M,N,2);
    pv = zeros(M,N,2);
    
    for i=1:2
      pu(:,:,i) = imresize(pu_tmp(:,:,i),[M N], 'bilinear');
      pv(:,:,i) = imresize(pv_tmp(:,:,i),[M N], 'bilinear');
    end
  end

  %figure(1), subplot(1,2,1), imshow(I_key,[]);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % call warping routine
  [u, v, u_, v_, pu, pv] = warping(u, v, u_, v_, pu, pv, ...
                                   I1_Pyramid{level}, I2_Pyramid{level}, lambda, theta, epsilon, ...
                                   use_edges, maxits, level, warps, ...
                                   g_Pyramid{level});
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
end

% store final flow
flow = zeros(M,N,2);
flow(:,:,1) = u;
flow(:,:,2) = v;