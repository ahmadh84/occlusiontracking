function [ train_filename ] = produceTrainingDataFile( obj, scene_id, training_ids, comp_feat_vec )
%PRODUCETRAININGDATAFILE Summary of this function goes here
%   Detailed explanation goes here

    if ~isfield(obj.settings, 'USE_ONLY_OF')
        obj.settings.USE_ONLY_OF = '';
    end
    
    fprintf(1, 'Creating training data for %d\n', scene_id);
    
    % get the filename to which all the data will be output
    train_filename = obj.getTrainingDataFilename(scene_id, comp_feat_vec.getUniqueID(), obj.settings.USE_ONLY_OF);
    
    % if the file already exists delete it
    if exist(train_filename, 'file') == 2
        fprintf(1, 'Deleting old training file %s\n', train_filename);
        delete(train_filename);
    end
    
    for training_id = training_ids
        
        fprintf(1, '\t... using data from sequence %d\n', training_id);
        
        [train_comp_feat_vec train_calc_flows] = obj.getFeatureVecAndFlow(training_id);
        
        % the structure that will be sent to the label data
        extra_label_info.calc_flows = train_calc_flows;
        
        % find the photoconstancy feature
        pc_feat_idx = find(strcmp(train_comp_feat_vec.feature_types, PhotoConstancyFeature.FEATURE_SHORT_TYPE));
        feat_depth_idxs = cumsum([0 train_comp_feat_vec.feature_depths]);
        pc_feat_cols = feat_depth_idxs(pc_feat_idx)+1:feat_depth_idxs(pc_feat_idx+1);
        
        % get error - get rid of reprojection error of other algos - be carefull if you change feature vector
        algo_idx = find(strcmp(train_calc_flows.algo_ids, obj.settings.USE_ONLY_OF));
        
        if ~isempty(algo_idx)
            % pull out both angular error and EPE 
            extra_label_info.uv_ang_err = train_calc_flows.uv_ang_err(:,:,algo_idx);
            extra_label_info.uv_epe = train_calc_flows.uv_epe(:,:,algo_idx);
            
            % get the cols that need to be deleted
            needed_pc_cols = pc_feat_cols(algo_idx:length(train_calc_flows.algo_ids):end);
            delete_pc_cols = setdiff(pc_feat_cols, needed_pc_cols);
            
            % remove the cols from the feature vector data
            train_comp_feat_vec.removeFeatures(delete_pc_cols);
        end
        
        
        % call the labelling object, to get the labels
        [ label data_idxs idxs_per_label ] = obj.settings.label_obj.calcLabelTraining(train_comp_feat_vec, obj.settings.MAX_MARKINGS_PER_LABEL, extra_label_info);
        
        % collate the data that will be written to the file
        data_to_write = zeros(idxs_per_label*length(label), size(train_comp_feat_vec.features,2)+1);
        for idx = 1:length(label)
            data = train_comp_feat_vec.features(data_idxs{idx},:);
            data_to_write((idxs_per_label*(idx-1))+1:idxs_per_label*idx, :) = [repmat(label(idx), [size(data,1) 1]) data];
        end
        
        % write training data
        dlmwrite(train_filename, data_to_write, '-append');
    end
end

