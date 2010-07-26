function [ output_args ] = featureTraining( scene_dir )
%FEATURETRAINING Summary of this function goes here
%   Detailed explanation goes here
    
    % add paths
    addpath(genpath('utils'));
    addpath(genpath('algorithms'));

    % load images
    im1 = imread(fullfile(scene_dir, '/1.png'));
    im2 = imread(fullfile(scene_dir, '2.png'));

    
end

