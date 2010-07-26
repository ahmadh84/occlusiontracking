function [It, Ix, Iy] = partial_deriv(images, uv_prev, interpolation_method, deriv_filter)
%PARTIAL_DERIV   Spatio-temporal derivatives
%   P = PARTIAL_DERIV computes the spatio-temporal derivatives
%   P between IMAGES using the flow field UV_PREV with specified
%   INTERPOLATION_METHOD ('bi-linear' or 'bi-cubic') and derivative filters
%  

% Authors: Deqing Sun, Department of Computer Science, Brown University
%          Stefan Roth, Department of Computer Science, TU Darmstadt
% Contact: dqsun@cs.brown.edu, sroth@cs.tu-darmstadt.de
% $Date: 2008-10-28$
% $Revision: 0 $
%
% Copyright 2007-2008, Brown University, Providence, RI. USA
% 		     TU Darmstadt, Darmstadt, Germany 
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


if nargin == 2
    interpolation_method = 'bi-linear';
end;

H   = size(images, 1);
W   = size(images, 2);

[x,y]   = meshgrid(1:W,1:H);
x2      = x + uv_prev(:,:,1);        
y2      = y + uv_prev(:,:,2);        
    
if strcmp(interpolation_method, 'bi-cubic')

    % Bicubic interpolation
    if nargout == 1
        
        if size(images, 4) == 1
            % gray-level
            warpIm = interp2_bicubic(images(:,:,2),x2,y2);
        else
            % color
            warpIm  = zeros(size(images(:,:,:,1)));
            for j = 1:size(images,3)
                warpIm(:,:,j) = interp2_bicubic(images(:,:,j, 2),x2,y2);
            end;
        end;
        
    elseif nargout == 3
        
        if size(images, 4) == 1
            % gray-level
            [warpIm Ix Iy] = interp2_bicubic(images(:,:,2),x2,y2);
        else
            % color
            warpIm  = zeros(size(images(:,:,:,1)));
            Ix      = warpIm;
            Iy      = warpIm;
            for j = 1:size(images,3)
                [warpIm(:,:,j) Ix(:,:,j) Iy(:,:,j)] = interp2_bicubic(images(:,:,j,2),x2,y2);
            end;
        end;
    
    else
        error('partial_deriv: number of output wrong!');
    end;

    indx        = isnan(warpIm);
    if size(images, 4) == 1
        It          = warpIm - images(:,:,1);
    else
        It          = warpIm - images(:,:,:,1);
    end;
    
    % Disable those out-of-boundary pixels in warping
    It(indx)    = 0;
    if nargout == 3
        Ix(indx) = 0;
        Iy(indx) = 0;
    end;
    
elseif strcmp(interpolation_method, 'bi-linear')

    % Linear interpolation is more robust though gradient is approximately
    % computed
    if size(images, 4) == 1
        % gray-level
        warpIm  = interp2(x,y,images(:,:,2),x2,y2,'linear', NaN);
        % Comment above and uncomment below if there is error with interp2  
%         warpIm  = interp2(x,y,images(:,:,2),x2,y2,'linear');        
        tmp     = images(:,:,1);
    else
        % color
        warpIm  = zeros(size(images(:,:,:,1)));
        for j = 1:size(images,3)
            warpIm(:,:,j) = interp2(x,y,images(:,:,j,2),x2,y2,'linear', NaN);
            % Comment above and uncomment below if there is error with interp2 
%             warpIm(:,:,j) = interp2(x,y,images(:,:,j,2),x2,y2,'linear');            
            tmp           = images(:,:,:,1);
        end;
    end;
    
    % Disable those out-of-boundary pixels in warping
    B         = isnan(warpIm);
    warpIm(B) = tmp(B);
    It        = warpIm - tmp;    
    
    if nargin == 4
        h = deriv_filter;
    else
        % h         = [-1 0 1]/2;
        h = [-1 9 -45 0 45 -9 1]/60;        % derivative used by Bruhn et al "combing "IJCV05' page218
    end;
    
    if nargout == 3
        Ix        = imfilter(warpIm, h,  'corr', 'symmetric', 'same');  %
        Iy        = imfilter(warpIm, h', 'corr', 'symmetric', 'same');
    end;
    % Ix(B) = 0;
    % Iy(B) = 0;
else
    error('partial_deriv: unknown interpolation method!');
end;