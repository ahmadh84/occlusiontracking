function [ output_args ] = calculate_pixels( input_args )
%CALCULATE_PIXELS Summary of this function goes here
%   Detailed explanation goes here
    addpath('main_code');
    training_seq = [4 5 9 10 11 12 13 14 18 19];
    main_dir = '../Data/oisin+middlebury';
    
    t_occl = 0;
    t_noccl = 0;
    
    for seq = training_seq
        scene_dir = fullfile(main_dir, num2str(seq));
        uv_gt = readFlowFile(fullfile(scene_dir, CalcFlows.GT_FLOW_FILE));
        
        mask = ~(uv_gt(:,:,1)>200 | uv_gt(:,:,2)>200);
        noccl = nnz(mask);
        occl = nnz(~mask);
        
        if exist(fullfile(scene_dir, CalcFlows.GT_UNSURE_MASK)) == 2
            mask = imread(fullfile(scene_dir, CalcFlows.GT_UNSURE_MASK));
            occl = occl - nnz(mask);
        end
        
        fprintf('%d %d\n', noccl, occl);
        t_occl = t_occl + occl;
        t_noccl = t_noccl + noccl;
    end
    
    fprintf('////////////////\n%d %d\n', t_noccl, t_occl);
end

