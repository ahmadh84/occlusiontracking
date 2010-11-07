function computeFlows( obj )
% calls all the flow computation algorithms, and performs all the
% post-processing to populate the properties of this object

    mat_filepath = fullfile(obj.scene_dir, obj.getMatFilename());

    % if the object is already stored, simply load it
    if obj.checkStoredObjAvailable()
        if ~obj.silent_mode
            fprintf('--> Loading object from %s\n', mat_filepath);
        end
        load(mat_filepath);
        eval(['obj.deepCopy(' CalcFlows.SAVE_OBJ_NAME ');']);
        return;
    end

    obj.uv_flows = [];
    obj.uv_flows_reverse = [];
    obj.algo_ids = cell(1, obj.no_algos);

    % COMPUTE ALL THE OPTICAL FLOWs and store their IDs
    for algo_idx = 1:obj.no_algos
        if strcmp(obj.cell_flow_algos{algo_idx}.OF_TYPE, 'Large Displacement OF')
            % DON'T HAVE 64BIT MEX FOR LDOF
            warning('CalcFlows:computeFlows', 'loading directly from file');
            
            % if file doesn't exist, attempt to compute it on a remote linux machine
            if ~exist(fullfile(obj.scene_dir, 'largedispof.mat'), 'file')
                addpath('remoteexec');
                status = remote_ldof(fullfile(obj.scene_dir, ComputeTrainTestData.IM1_PNG), fullfile(obj.scene_dir, ComputeTrainTestData.IM2_PNG));
                assert(status == 0, 'Something went wrong while computing LDOF remotely');
            end
            
            load(fullfile(obj.scene_dir, 'largedispof.mat'));
            obj.uv_flows(:,:,:,algo_idx) = uv_ld;
            
            % if we need to compute the flow in reverse
            if obj.compute_reverse
                obj.uv_flows_reverse(:,:,:,algo_idx) = uv_ld_r;
            end
            
            obj.flow_compute_times(algo_idx) = ld_compute_time;
            
        elseif strcmp(obj.cell_flow_algos{algo_idx}.OF_TYPE, 'GT Flow')
            % Just need to give the directory
            warning('CalcFlows:computeFlows', 'using GT flow');
        
            [ obj.uv_flows(:,:,:,algo_idx) gf_compute_time ] = obj.cell_flow_algos{algo_idx}.calcFlow(obj.scene_dir);
            
            assert(~obj.compute_reverse, 'Can''t get reverse flow with GT flow');
            
            obj.flow_compute_times(algo_idx) = gf_compute_time;
            
        elseif strcmp(obj.cell_flow_algos{algo_idx}.OF_TYPE, 'Huber-L1')
            % DON'T HAVE CUDA FOR machine
            warning('CalcFlows:computeFlows', 'loading directly from file');
            load(fullfile(obj.scene_dir, 'huberl1.mat'));
            obj.uv_flows(:,:,:,algo_idx) = uv_fl;
            
            % if we need to compute the flow in reverse
            if obj.compute_reverse
                obj.uv_flows_reverse(:,:,:,algo_idx) = uv_fl_r;
            end
            
            obj.flow_compute_times(algo_idx) = fl_compute_time;
            
        else
            [ obj.uv_flows(:,:,:,algo_idx) compute_time ] = obj.cell_flow_algos{algo_idx}.calcFlow(obj.im1, obj.im2);
            
            % if we need to compute the flow in reverse
            if obj.compute_reverse
                [ obj.uv_flows_reverse(:,:,:,algo_idx) temp ] = obj.cell_flow_algos{algo_idx}.calcFlow(obj.im2, obj.im1);
                compute_time = compute_time + temp;
            end
            
            obj.flow_compute_times(algo_idx) = compute_time;
        end
        
        obj.algo_ids{algo_idx} = obj.cell_flow_algos{algo_idx}.OF_SHORT_TYPE;
    end

    tic;
    
    % check if GT computation needed and available
    if obj.checkGTAvailable()
        % read GT flow file
        obj.uv_gt = readFlowFile(fullfile(obj.scene_dir, CalcFlows.GT_FLOW_FILE));

        % compute the angle errors and EPE for all the algorithms
        obj.uv_ang_err = zeros(size(obj.uv_flows,1), size(obj.uv_flows,2), obj.no_algos);
        obj.uv_epe = obj.uv_ang_err;
        for algo_idx = 1:obj.no_algos
            [ obj.uv_ang_err(:,:,algo_idx) obj.uv_epe(:,:,algo_idx) ] = flowAngErrMe(obj.uv_gt(:,:,1), obj.uv_gt(:,:,2), ...
                                                                                obj.uv_flows(:,:,1,algo_idx), obj.uv_flows(:,:,2,algo_idx));
        end

        % find the best algorithm according to Angular error
        [ obj.result_ang obj.class_ang ] = min(obj.uv_ang_err,[],3);

        % find the best algorithm according to EPE
        [ obj.result_epe obj.class_epe ] = min(obj.uv_epe,[],3);

        % find the distance between first and second best score
        [vals ind] = sort(obj.uv_epe, 3);
        if size(obj.uv_epe,3) > 1
            obj.epe_dist_btwfirstsec = vals(:,:,2) - vals(:,:,1);
        else
            obj.epe_dist_btwfirstsec = vals;
        end

        % GT mask
        obj.gt_mask = obj.loadGTMask( 0 );

        % check if unsure/ignore mask is available
        if exist(fullfile(obj.scene_dir, CalcFlows.GT_UNSURE_MASK), 'file') == 2
            obj.gt_ignore_mask = imread(fullfile(obj.scene_dir, CalcFlows.GT_UNSURE_MASK));
        end
        
        % Average EPE relative to the mask
        pts = nnz(obj.gt_mask);
        for algo_idx = 1:obj.no_algos
            temp_uv_epe = obj.uv_epe(:,:,algo_idx);
            obj.algo_avg_epe(algo_idx) = sum(sum(temp_uv_epe(obj.gt_mask)))/pts;
        end
        obj.opt_avg_epe = sum(sum(obj.result_epe(obj.gt_mask)))/pts;
    end

    obj.flow_extra_time = toc;
    
    % save the object to the mat file
    if ~obj.silent_mode
        fprintf('--> Saving object to %s\n', mat_filepath);
    end
    eval([CalcFlows.SAVE_OBJ_NAME ' = obj;']);
    save(mat_filepath, CalcFlows.SAVE_OBJ_NAME);
end

