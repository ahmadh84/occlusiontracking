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

function [dx] = dxp(u)
[M N] = size(u);
dx = [u(:,2:end) u(:,end)] - u;
