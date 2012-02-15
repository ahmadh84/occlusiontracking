function [ train_filename ] = produceTrainingDataFile( obj, scene_id, training_ids, unique_id )
%PRODUCETRAININGDATAFILE Summary of this function goes here
%   Detailed explanation goes here

    if ~isfield(obj.settings, 'USE_ONLY_OF')
        obj.settings.USE_ONLY_OF = '';
    end
    
    if ~obj.silent_mode
        fprintf(1, 'Creating training data for %d\n', scene_id);
    end
    
    % get the filename to which all the data will be output
    train_filename = obj.getTrainingDataFilename(scene_id, unique_id, obj.settings.USE_ONLY_OF);
    
    % if the file already exists delete it
    if exist(train_filename, 'file') == 2
        if ~obj.silent_mode
            fprintf(1, 'Deleting old training file %s\n', train_filename);
        end
        delete(train_filename);
    end
    
    for training_id = training_ids
        
        if ~obj.silent_mode
            fprintf(1, '\t... using data from sequence %d\n', training_id);
        end
        
        [train_comp_feat_vec train_calc_flows] = obj.getFeatureVecAndFlow(training_id, 1);
        
        % the structure that will be sent to the label data
        extra_label_info.calc_flows = train_calc_flows;
        
        % adjust info (remove any features if necessary)
        [ train_comp_feat_vec extra_label_info ] = ComputeTrainTestData.adjustFeaturesInfo(train_comp_feat_vec, train_calc_flows, extra_label_info, obj.settings, false);
        
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
        
        % clear memory heavy variables
        clearvars data_to_write data_idxs train_calc_flows train_comp_feat_vec extra_label_info;
    end
end

