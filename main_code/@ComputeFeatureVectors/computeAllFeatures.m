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

    % iterate and compute all the features provided
    for feature_idx = 1:obj.no_feature_types
        % compute the feature
        [ feature feature_depth ] = obj.cell_features{feature_idx}.calcFeatures(obj);

        % add feature to the main collection
        obj.feature_depths(feature_idx) = feature_depth;
        obj.feature_types{feature_idx} = obj.cell_features{feature_idx}.FEATURE_SHORT_TYPE;
        obj.features = cat(3, obj.features, feature);
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