function [ output_args ] = store_flow_pics( input_args )
%STORE_PICS Summary of this function goes here
%   Detailed explanation goes here

    addpath('main_code');
    addpath(genpath('main_code/utils'));
    
    input_dir = 'D:/ahumayun/Data/evaluation_data/stein';
    sub_out_dir = 'flows';
    calc_flow_file = '*_4518_*gt.mat';
    fldrs = dir(input_dir);
    
    for fldr_idx = 1:length(fldrs)
        if fldrs(fldr_idx).isdir && ~strcmp(fldrs(fldr_idx).name, '.') && ~strcmp(fldrs(fldr_idx).name, '..')
            fprintf(1, 'Processing ''%s'' folder\n', fldrs(fldr_idx).name);
            file = dir(fullfile(input_dir, fldrs(fldr_idx).name, calc_flow_file));
            
            % if calc_flows file exists
            if length(file) == 1
                out_dir = fullfile(input_dir, sub_out_dir, fldrs(fldr_idx).name);
                if ~exist(out_dir, 'dir')
                    mkdir(out_dir);
                end
                copyfile(fullfile(input_dir, fldrs(fldr_idx).name, ComputeTrainTestData.IM1_PNG),out_dir);
                copyfile(fullfile(input_dir, fldrs(fldr_idx).name, ComputeTrainTestData.IM2_PNG),out_dir);
                
                % load calc_flows
                load(fullfile(input_dir, fldrs(fldr_idx).name, file(1).name));
                
                % iterate over all flow algorithms
                for algo_idx = 1:length(flow_info.algo_ids)
                    flow = flow_info.uv_flows(:,:,:,algo_idx);
                    img = flowToColor(flow);
                    imwrite(img, fullfile(out_dir, [flow_info.algo_ids{algo_idx} '.png']));
                end
            end
        end
    end
end

