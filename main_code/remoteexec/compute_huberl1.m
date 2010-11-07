
impath = 'D:/temp2';

cd 'D:/ahumayun/Code/main_code';

im1 = imread(fullfile(impath, ComputeTrainTestData.IM1_PNG));
im2 = imread(fullfile(impath, ComputeTrainTestData.IM2_PNG));

% make RGB image if not already (LDOF doesn't take grayscales)
if size(im1,3) == 1
    im1 = cat(3, im1, im1, im1);
    im2 = cat(3, im2, im2, im2);
end

[ uv_fl time1 ] = HuberL1OF.calcFlow(im1, im2);
[ uv_fl_r time2 ] = HuberL1OF.calcFlow(im2, im1);

fl_compute_time = time1 + time2;

save('huberl1.mat', 'uv_fl', 'uv_fl_r', 'fl_compute_time');

