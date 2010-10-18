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
                
                % get the normalization flow vector length
                [ maxrad ] = returnMaxRadNorm(flow_info.uv_gt, flow_info.gt_mask, flow_info.uv_flows);
                
                % iterate over all flow algorithms
                for algo_idx = 1:length(flow_info.algo_ids)
                    flow = flow_info.uv_flows(:,:,:,algo_idx);
                    img = flowToColor(flow, maxrad);
                    imwrite(img, fullfile(out_dir, [flow_info.algo_ids{algo_idx} '.png']));
                end
            end
        end
    end
end


function [ maxrad ] = returnMaxRadNorm(gt_flow, gt_mask, uv_flows)

    if isempty(gt_flow)
        % get the median flow (make 2 dim matrix - quicker! :s)
        sz_temp = size(uv_flows);
        uv_flows = reshape(uv_flows, [sz_temp(1)*sz_temp(2)*sz_temp(3) sz_temp(4)]);
        median_flow = median(uv_flows, 2);
        gt_flow = reshape(median_flow, [sz_temp(1) sz_temp(2) sz_temp(3)]);    
    end
    
    rad = sqrt(gt_flow(:,:,1).^2+gt_flow(:,:,2).^2);
    
    if ~isempty(gt_mask)
        rad(~gt_mask) = -1;
    end
    
    maxrad = max(-1, max(rad(:)));
    maxrad = maxrad * 1.2;
end

