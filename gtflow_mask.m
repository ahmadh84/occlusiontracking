function [ output_args ] = gtflow_mask( input_args )
%GTFLOW_MASK Summary of this function goes here
%   Detailed explanation goes here

    addpath('../../Code/main_code');
    
    data_dir = '../Data/oisin+middlebury';
    input_d = 'H:\middlebury\features_comparison_tests\features_st';
    out_image_dir = '../images/evaluation/st/';
    
%     sequence_no = [1 2 3 6 7 15 16];
%     thresholds = [30 10 20 50 50 100 10];
    
    sequence_no = [1 2 7 15 16];
    thresholds = [30 10 50 100 10];
    
    for no = 1:length(sequence_no)
        d = fullfile(data_dir, num2str(sequence_no(no)));
        %store_gtmask(d, thresholds(no));
        
        adjust_flowfile(d);
    end
end


function adjust_flowfile(data_dir)
    
    % do photoconstancy
    gt_flow = readFlowFile(fullfile(data_dir, CalcFlows.GT_FLOW_FILE));
    
    i = imread(fullfile(data_dir, 'gt_occl_mask.png'));
    u = gt_flow(:,:,1);
    v = gt_flow(:,:,2);
    u(i) = 1000;
    v(i) = 1000;
    
    flow = cat(3,u,v);
    
    writeFlowFile(flow, fullfile(data_dir, CalcFlows.GT_FLOW_FILE));
end


function store_gtmask(data_dir, th)
    % read im1 and im2
    im1 = imread(fullfile(data_dir, ComputeTrainTestData.IM1_PNG));
    im2 = imread(fullfile(data_dir, ComputeTrainTestData.IM2_PNG));
    image_sz = size(im1);
    
    % do photoconstancy
    gt_flow = readFlowFile(fullfile(data_dir, CalcFlows.GT_FLOW_FILE));

    % initialize the output feature
    photoconst = zeros(image_sz);

    [cols rows] = meshgrid(1:image_sz(2), 1:image_sz(1));

    % project the second image to the first according to the flow
    for depth = 1:size(photoconst,3)
        photoconst(:,:,depth) = interp2(im2(:,:,depth), ...
            cols + gt_flow(:,:,1), rows + gt_flow(:,:,2), 'cubic');
    end

    % compute the error in the projection
    proj_im = abs(double(im1) - double(photoconst));
    proj_im(isnan(photoconst)) = 255;
    proj_im = max(proj_im, [], 3);
    
    imwrite(proj_im>th, fullfile(data_dir, 'gt_mask.png'));
end

