function uv = tvl1of(im1, im2)
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

% weighting of the data term
lambda = 70.0; % lambda in [10.0, 1000.0]

% quadratic relaxation parameter
theta = 0.25; % theta in [0.1, 0.5]

% TV norm with quadratic behavior between 0 and epsilon
epsilon = 0.1;

% use edge weighted TV
use_edges = 1; % 0 = no, 1 = yes

% number of TV-L1 iterations per warp
maxits = 10;

% warping parameters
max_pyramid_levels = 1000; % max number of pyramid levels
pyramid_factor = 0.5; % in [0.5, 0.95]
warps = 5; % number of warps per level

% preprocessing
use_structure_texture = 1;
structure_texture_sigma = 1.0;
structure_texture_factor = 0.8;

% load images
% images should be in [0, 1]
si = size(im1);
if length(si) > 2
    I1 = double(rgb2gray(im1))/255;
    I2 = double(rgb2gray(im2))/255;
else
    I1 = double(im1)/255;
    I2 = double(im2)/255;
end

% call main routine
[uv] = coarse_to_fine(I1, I1, I2, lambda, theta, epsilon, use_edges, maxits, ...
    max_pyramid_levels, pyramid_factor, warps, ...
    use_structure_texture, structure_texture_sigma, structure_texture_factor);
