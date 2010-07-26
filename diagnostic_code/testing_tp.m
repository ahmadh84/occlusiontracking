function [ output_args ] = testing_tp( input_args )
%TESTING_TP Summary of this function goes here
%   Detailed explanation goes here

    close all;
    
    scene_id = '18';
    prediction_dir = 'H:\middlebury\features_comparison_tests\features_av_lv_cs_pc\1_2';
    main_dir = 'C:\Users\Ahmad\Documents\UCL\MS Thesis - Tracking powered by Superpixels\Data\oisin+middlebury\';
    
    d = dir(fullfile(prediction_dir, [scene_id '*prediction.data']));
    assert(~isempty(d), 'The prediction file was not found');
    
    addpath(genpath(fullfile(pwd, '..', 'main_code', 'utils')));
    addpath(genpath(fullfile(pwd, '..', 'misc', 'TurboPixels')));
    
    % load image
    i = im2double(imread(fullfile(main_dir, scene_id, '1.png')));

    % load prediction posterior
    classifier_out = textread(fullfile(prediction_dir, d(1).name), '%f');
    classifier_out = reshape(classifier_out, size(i,2), size(i,1))';
    
    % load GT
    uv_gt = readFlowFile(fullfile(main_dir, scene_id, '1_2.flo'));
    mask = (uv_gt(:,:,1)>200 | uv_gt(:,:,2)>200);
    
    roc_gui(i, classifier_out, mask);
    
    % binarize classifier output
%     fltr =  fspecial('gaussian', [10 10], 1);
%     bin_classifier_out = imfilter(classifier_out, fltr)>0.5;
%     bin_classifier_out = bwareaopen(bin_classifier_out, 20);
%    
%     [phi,boundary,disp_img] = superpixels(i, double(bin_classifier_out), 800);
%    
%     % display normal
%     non_occl = double(classifier_out);
%     non_occl = cat(3, 1*non_occl, 1*non_occl, 1*non_occl);
%     occl = double(classifier_out);
%     occl = cat(3, 1*occl, 1*occl, 0*occl);
%     
%     show_img = non_occl;
%     occl_mask = repmat(mask, [1 1 3]);
%     show_img(occl_mask) = occl(occl_mask);
%     
%     imshow(show_img);
%     imshow(rgb2gray(i));
%     hold on;
%     image(occl, 'AlphaData', double(bin_classifier_out)*0.6);
%     boundary_img = double(boundary);
%     boundary_img = cat(3, 0.99*boundary_img, 0.0*boundary_img, 0.0*boundary_img);
%     image(boundary_img, 'AlphaData', boundary);
end

