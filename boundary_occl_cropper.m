close all;

main_dir = 'H:/middlebury_oisin_dataset';

training_seq = [4 5 9 10 11 12 13 14 17 18 19];
addpath(genpath('main_code/utils'));
addpath('main_code');

extra_flow_algos = {'classicnl.mat', 'largedispof.mat'};

bounds = [ 2 583 1 387;
           2 579 1 387;
           1 593 27 480;
           19 566 9 450;
           14 316 4 236;
           27 296 6 229;
           22 297 5 234;
           15 304 4 235;
           26 640 1 463;
           12 640 1 473;
           1 639 1 472];

write_final_output = 1;

for idx = 1:length(training_seq)
    scene_id = training_seq(idx);
    scene_dir = fullfile(main_dir, num2str(scene_id));
    
    flow_im_filename = fullfile(scene_dir, ['flow' num2str(scene_id) '.png']);
    flow_im = imread(flow_im_filename);
    imshow(flow_im);
    
    adjusted_flow_im = flow_im(bounds(idx,3):bounds(idx,4), bounds(idx,1):bounds(idx,2), :);
    figure, imshow(adjusted_flow_im);
    
    if write_final_output
        imwrite(adjusted_flow_im, flow_im_filename);
        
        filename_1 = fullfile(scene_dir, ComputeTrainTestData.IM1_PNG);
        i1 = imread(filename_1);
        adjusted_i1 = i1(bounds(idx,3):bounds(idx,4), bounds(idx,1):bounds(idx,2), :);
        imwrite(adjusted_i1, filename_1);
        
        filename_2 = fullfile(scene_dir, ComputeTrainTestData.IM2_PNG);
        i2 = imread(filename_2);
        adjusted_i2 = i2(bounds(idx,3):bounds(idx,4), bounds(idx,1):bounds(idx,2), :);
        imwrite(adjusted_i2, filename_2);
    end
    
    % adjust flow file
    uv_gt_filename = fullfile(scene_dir, CalcFlows.GT_FLOW_FILE);
    uv_gt = readFlowFile(uv_gt_filename);
    adjusted_uv_gt = uv_gt(bounds(idx,3):bounds(idx,4), bounds(idx,1):bounds(idx,2), :);
    
    figure, imshow(flowToColor(adjusted_uv_gt));
    if write_final_output
        writeFlowFile(adjusted_uv_gt, uv_gt_filename);
    end
    
    close all;
end