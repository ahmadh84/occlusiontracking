function [ test_filename ] = produceTestingDataFile( obj, scene_id, comp_feat_vec, calc_flows )
%PRODUCETESTINGDATAFILE Summary of this function goes here
%   Detailed explanation goes here

    if ~isfield(obj.settings, 'USE_ONLY_OF')
        obj.settings.USE_ONLY_OF = '';
    end
    
    % test data
    if ~obj.silent_mode
        fprintf(1, 'Creating test data for %d\n', scene_id);
    end
    
    % get the filename to which all the data will be output
    test_filename = obj.getTestingDataFilename(scene_id, comp_feat_vec.getUniqueID(), obj.settings.USE_ONLY_OF);
    
    % if the file already exists delete it
    if exist(test_filename, 'file') == 2
        if ~obj.silent_mode
            fprintf(1, 'Deleting old testing file %s\n', test_filename);
        end
        delete(test_filename);
    end
    
    % write test data to file - left to right (row major order)
    if ~obj.force_no_gt && ~isempty(calc_flows.gt_mask) 
        
        % the structure that will be sent to the label data
        extra_label_info.calc_flows = calc_flows;
        
        % find the photoconstancy feature
        pc_feat_idx = find(strcmp(comp_feat_vec.feature_types, PhotoConstancyFeature.FEATURE_SHORT_TYPE));
        feat_depth_idxs = cumsum([0 comp_feat_vec.feature_depths]);
        pc_feat_cols = feat_depth_idxs(pc_feat_idx)+1:feat_depth_idxs(pc_feat_idx+1);
        
        % get error - get rid of reprojection error of other algos - be carefull if you change feature vector
        algo_idx = find(strcmp(calc_flows.algo_ids, obj.settings.USE_ONLY_OF));
        
        if ~isempty(algo_idx)
            % pull out both angular error and EPE 
            extra_label_info.uv_ang_err = calc_flows.uv_ang_err(:,:,algo_idx);
            extra_label_info.uv_epe = calc_flows.uv_epe(:,:,algo_idx);
            
            % get the cols that need to be deleted
            needed_pc_cols = pc_feat_cols(algo_idx:length(calc_flows.algo_ids):end);
            delete_pc_cols = setdiff(pc_feat_cols, needed_pc_cols);
            
            % remove the cols from the feature vector data
            comp_feat_vec.removeFeatures(delete_pc_cols);
        end
        
        labels = obj.settings.label_obj.calcLabelWhole(comp_feat_vec, extra_label_info);
    else
        % No GT Labels
        labels = zeros(size(comp_feat_vec.features,1), 1);
        
        % find the photoconstancy feature
        pc_feat_idx = find(strcmp(comp_feat_vec.feature_types, PhotoConstancyFeature.FEATURE_SHORT_TYPE));
        feat_depth_idxs = cumsum([0 comp_feat_vec.feature_depths]);
        pc_feat_cols = feat_depth_idxs(pc_feat_idx)+1:feat_depth_idxs(pc_feat_idx+1);
        
        % get error - get rid of reprojection error of other algos - be carefull if you change feature vector
        algo_idx = find(strcmp(calc_flows.algo_ids, obj.settings.USE_ONLY_OF));
        
        if ~isempty(algo_idx)
            % get the cols that need to be deleted
            needed_pc_cols = pc_feat_cols(algo_idx:length(calc_flows.algo_ids):end);
            delete_pc_cols = setdiff(pc_feat_cols, needed_pc_cols);
            
            % remove the cols from the feature vector data
            comp_feat_vec.removeFeatures(delete_pc_cols);
        end
    end
    
    % write test data to file
    dlmwrite(test_filename, [labels comp_feat_vec.features]);
end

