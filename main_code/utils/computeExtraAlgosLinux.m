function computeExtraAlgosLinux( sequences )
%COMPUTEEXTRAALGOSLINUX script to compute flow from algorithms which only
%   run on linux

    main_dir = '../../Data/middlebury';
%     addpath(genpath('algorithms/Classic NL'));
%     addpath(genpath('algorithms/Large Disp OF'));
    
    flowsave_filenames = { 'classicnl.mat', 'largedispof.mat' };
    flowsave_varnames = { 'uv_cn', 'uv_ld' };
    
    cell_flows = { ClassicNLOF, ...
                   LargeDisplacementOF };
    
    for scene_id = sequences
        scene_dir = fullfile(main_dir, num2str(scene_id));
        
        % load images
        im1 = imread(fullfile(scene_dir, ComputeTrainTestData.IM1_PNG));
        im2 = imread(fullfile(scene_dir, ComputeTrainTestData.IM2_PNG));
        
        for algo_idx = 1:length(cell_flows)
            temp = cell_flows{algo_idx}.calcFlow(im1, im2);
            
            eval([flowsave_varnames{algo_idx} ' = temp;']);
            mat_filepath = fullfile(scene_dir, flowsave_filenames{algo_idx});
            save(mat_filepath, flowsave_varnames{algo_idx});
        end
    end

end

