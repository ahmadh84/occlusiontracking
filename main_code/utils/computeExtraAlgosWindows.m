function computeExtraAlgosWindows( main_dir, sequences )
%COMPUTEEXTRAALGOSWINDOWS script to compute flow from algorithms which only
%   run on linux

%     addpath(genpath('algorithms/Classic NL'));
%     addpath(genpath('algorithms/Large Disp OF'));
    
    cell_flows = { HuberL1OF, OcclusionsConvexOF, ClassicNLOF };
    
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
            uv_extra_info.scene_dir = scene_dir;
            uv_extra_info.reverse = 0;
            [ temp time1 ] = cell_flows{algo_idx}.calcFlow(im1, im2, uv_extra_info);
            eval([cell_flows{algo_idx}.FORWARD_FLOW_VAR ' = temp;']);
            
            uv_extra_info.reverse = 1;
            [ temp time2 ] = cell_flows{algo_idx}.calcFlow(im2, im1, uv_extra_info);
            eval([cell_flows{algo_idx}.BCKWARD_FLOW_VAR ' = temp;']);
            
            time1 = time1 + time2;
            eval([cell_flows{algo_idx}.COMPUTATION_TIME_VAR ' = time1;']);
            
            mat_filepath = fullfile(scene_dir, cell_flows{algo_idx}.SAVE_FILENAME);
            save(mat_filepath, cell_flows{algo_idx}.FORWARD_FLOW_VAR, cell_flows{algo_idx}.BCKWARD_FLOW_VAR, cell_flows{algo_idx}.COMPUTATION_TIME_VAR);
        end
    end

end

