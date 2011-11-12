close all;
clear;

% smoothness of flow
lambda = 50;

% warping parameters
pyramid_levels = 1000; % as much as possible
pyramid_factor = 0.9;
warps = 1;
maxits = 50;

if 1
  I1 = double(imread('frame10.png'))/255.0;
  I2 = double(imread('frame11.png'))/255.0;
end

tic
  [flow illumination] = ...
      coarse_to_fine(I1, I2, lambda, warps, maxits, pyramid_levels, pyramid_factor);
toc

motfile = 'motion.png';
illfile = 'illumination.png';

illumination = illumination - min(illumination(:));
illumination = illumination/max(illumination(:));

tmp = flow;
magnitude = (tmp(:,:,1).^2 + tmp(:,:,2).^2).^0.5;  
max_flow = prctile(magnitude(:),95);


tmp(:,:,1) = min(max(tmp(:,:,1),-max_flow),max_flow);
tmp(:,:,2) = min(max(tmp(:,:,2),-max_flow),max_flow);

imwrite(uint8(flowToColor(tmp)),motfile);
imwrite(illumination,illfile);
