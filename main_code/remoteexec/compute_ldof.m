function compute_ldof()
    impath = pwd;

    cd '~/thesis/main_code';

    im1 = imread(fullfile(impath, ComputeTrainTestData.IM1_PNG));
    im2 = imread(fullfile(impath, ComputeTrainTestData.IM2_PNG));

    % make RGB image if not already (LDOF doesn't take grayscales)
    if size(im1,3) == 1
        im1 = cat(3, im1, im1, im1);
        im2 = cat(3, im2, im2, im2);
    end

    [ uv_ld time1 ] = LargeDisplacementOF.calcFlow(im1, im2);
    [ uv_ld_r time2 ] = LargeDisplacementOF.calcFlow(im2, im1);

    ld_compute_time = time1 + time2;

    cd(impath);
    save('largedispof.mat', 'uv_ld', 'uv_ld_r', 'ld_compute_time');
    
    exit;
end


function [ uv_ld ld_compute_time ] = backwardcomp_ldof(im1, im2)
    tic;

    addpath('algorithms/Large Disp OF')
    uv_ld = mex_LDOF(double(im1), double(im2));

    ld_compute_time = toc;
end