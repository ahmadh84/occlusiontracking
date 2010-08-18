function computeExtraAlgosLinux( sequences )
%COMPUTEEXTRAALGOSLINUX script to compute flow from algorithms which only
%   run on linux

    main_dir = '../../Data/oisin+middlebury';
%     addpath(genpath('algorithms/Classic NL'));
%     addpath(genpath('algorithms/Large Disp OF'));
    
    flowsave_filenames = { 'largedispof.mat' };
    flowsave_varnames = { 'uv_ld' };
    flowsave_r_varnames = { 'uv_ld_r' };
    
    cell_flows = { LargeDisplacementOF };
    
    for scene_id = sequences
        scene_dir = fullfile(main_dir, num2str(scene_id));
        
        % load images
        im1 = imread(fullfile(scene_dir, ComputeTrainTestData.IM1_PNG));
        im2 = imread(fullfile(scene_dir, ComputeTrainTestData.IM2_PNG));
        
        % make RGB image if not already (LDOF doesn't take grayscales)
        if size(im1,3) == 1
            im1 = cat(3, im1, im1, im1);
            im2 = cat(3, im2, im2, im2);
        end
        
        for algo_idx = 1:length(cell_flows)
            temp = cell_flows{algo_idx}.calcFlow(im1, im2);
            eval([flowsave_varnames{algo_idx} ' = temp;']);
            
            temp = cell_flows{algo_idx}.calcFlow(im2, im1);
            eval([flowsave_r_varnames{algo_idx} ' = temp;']);
            
            mat_filepath = fullfile(scene_dir, flowsave_filenames{algo_idx});
            save(mat_filepath, flowsave_varnames{algo_idx}, flowsave_r_varnames{algo_idx});
        end
    end

end

