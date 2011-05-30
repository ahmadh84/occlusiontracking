function pyr = construct_image_pyramid(I, pyrlevels, pyrfactor)
% CONSTRUCT_IMAGE_PYRAMID  Computes the image pyramid
% 
% PYR = CONSTRUCT_IMAGE_PYRAMID(I, PYRLEVELS, PYRFACTOR)
% INPUT: 
%	  I         : Input image
%   PYRLEVELS : # of levels at the pyramid
%   PYRFACTOR : pyramid factor
%			
%	OUTPUT: 
%   PYR : Output pyramid. Cell with the size pyrlevels.
%
% Copyright (C) 2010 Alper Ayvaci, Michalis Raptis
%
% This file is available under the terms of the
% GNU GPLv2, or (at your option) any later version.
%
% ------------------------------------------------------- 
% AUTHOR Alper Ayvaci, Michalis Raptis (UCLA Vision Lab)
% -------------------------------------------------------

	factor            = sqrt(2);  
	smooth_sigma      = sqrt(1/pyrfactor)/factor;  
	f                 = fspecial('gaussian', 2*round(1.5*smooth_sigma) +1, smooth_sigma);        
	
	pyr = cell(pyrlevels,1);
	tmp = I;
	pyr{1} = tmp;

	for m = 2:pyrlevels    
	   % Gaussian filtering 
	   tmp = imfilter(tmp, f, 'corr', 'symmetric', 'same');           
	   tmp = imresize(tmp, pyrfactor, 'bilinear');  
	   pyr{m} = tmp;
	end;

end


