function computeAllFeatures( obj )
% Main function that computes and stores all the provided features

    mat_filepath = fullfile(obj.scene_dir, obj.getMatFilename());

    % if the object is already stored, simply load it
    if obj.checkStoredObjAvailable()
        if ~obj.silent_mode
            fprintf('--> Loading object from %s\n', mat_filepath);
        end
        load(mat_filepath);
        eval(['obj.deepCopy(' ComputeFeatureVectors.SAVE_OBJ_NAME ');']);
        return;
    end

    % to keep track times from repeat computations (loaded from disk)
    compute_time_ticked = cell(0,2);
    
    % iterate and compute all the features provided
    for feature_idx = 1:obj.no_feature_types
        % compute the feature
        [ feature feature_depth feature_compute_time ] = obj.cell_features{feature_idx}.calcFeatures(obj);

        % add feature to the main collection
        obj.feature_depths(feature_idx) = feature_depth;
        obj.feature_types{feature_idx} = obj.cell_features{feature_idx}.FEATURE_SHORT_TYPE;
        obj.features = cat(3, obj.features, feature);
        
        
        % collate the computation times
        if iscell(feature_compute_time)
            total_time = feature_compute_time{strcmpi(feature_compute_time(:,1), 'totaltime'), 2};
            feature_compute_time(strcmpi(feature_compute_time(:,1), 'totaltime'), :) = [];
            remove_list = [];
            for time_idx = 1:size(feature_compute_time,1)
                % if already timed - remove from total time
                if any(strcmpi(compute_time_ticked(:,1), feature_compute_time{time_idx,1}))
                    total_time = total_time - feature_compute_time{time_idx,2};
                    remove_list = [remove_list time_idx];
                end
            end
            feature_compute_time(remove_list,:) = [];
            compute_time_ticked = [compute_time_ticked; feature_compute_time];
            obj.feature_compute_times(feature_idx) = total_time;
        else
            obj.feature_compute_times(feature_idx) = feature_compute_time;
        end
    end

    % collate the features collected into a single feature vector (row major order)
    obj.features = permute(obj.features, [2 1 3]);
    obj.features = reshape(obj.features, [obj.image_sz(1)*obj.image_sz(2) sum(obj.feature_depths)]);

    % save the object to the mat file
    if ~obj.silent_mode
        fprintf('--> Saving object to %s\n', mat_filepath);
    end
    eval([ComputeFeatureVectors.SAVE_OBJ_NAME ' = obj;']);
    save(mat_filepath, ComputeFeatureVectors.SAVE_OBJ_NAME);
end