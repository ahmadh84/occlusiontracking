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

function [g] = compute_edge_weight(f)

[M N] = size(f);

q = 0.5;
alpha = 1.0;
sigma = 1.0;

ks = min(5, 2*(round(3*sigma))+1);
f_g = imfilter(f,fspecial('gaussian',[ks ks], sigma),'replicate');
mask = [-1 0 1];
fx = imfilter(f_g,mask,'replicate');
fy = imfilter(f_g,mask','replicate');

norm = sqrt(fx.^2 + fy.^2);

g = max(1e-06, exp(-alpha*norm.^q));