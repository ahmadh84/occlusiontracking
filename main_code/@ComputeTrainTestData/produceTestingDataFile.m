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
        
        % adjust info (remove any features if necessary)
        [ comp_feat_vec extra_label_info ] = ComputeTrainTestData.adjustFeaturesInfo(comp_feat_vec, calc_flows, extra_label_info, obj.settings, false);
        
        labels = obj.settings.label_obj.calcLabelWhole(comp_feat_vec, extra_label_info);
    else
        % No GT Labels
        labels = zeros(size(comp_feat_vec.features,1), 1);
        
        % adjust info (remove any features if necessary)
        [ comp_feat_vec ] = ComputeTrainTestData.adjustFeaturesInfo(comp_feat_vec, calc_flows, struct, obj.settings, true);
    end
    
    % write test data to file
    dlmwrite(test_filename, [labels comp_feat_vec.features]);
end

