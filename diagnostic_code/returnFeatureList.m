function [ feature_list scene_id unique_id ] = returnFeatureList( filepath )
%RETURNFEATURELIST Takes a mat file for ClassifierOutputHandler or
%   ComputeFeatureVectors and gets all the texts pertaining to all features

    assert(exist(filepath, 'file')==2, 'returnFeatureList:FileDoesntExist', 'The feature filepath given for listing doesn''t exist');

    % get the scene id and the unique id
    tok = regexp(filepath, '(\d+)_(\w+)_((?:rffeatureimp)|(?:FV)).mat$', 'tokens');
    assert(length(tok)==1 && length(tok{1})==3, 'Couldn''t decipher scene_id and unique_id from filename OR filename not supported');
    scene_id = tok{1}{1};
    unique_id = tok{1}{2};
    
    fprintf('--> Loading object from %s\n', filepath);
    load(filepath);
    
    if strcmp(tok{1}{3}, 'rffeatureimp') > 0
        % pull data from ClassifierOutputHandler
        
        eval(['classifier_out = ' ClassifierOutputHandler.SAVE_OBJ_NAME ';']);
        
        % validate feature length
        ftr_depth = length(classifier_out.feature_importance);
        no_ftr_types = length(classifier_out.feature_types);
        assert(ftr_depth == sum(classifier_out.feature_depths), 'returnFeatureList:FeaturesMismatch', 'The feature data doesn''t match with feature_depths');
        
        % get feature depths and cell_features
        feature_depths = classifier_out.feature_depths;
        cell_features = classifier_out.settings.cell_features;
    else
        % pull data from ComputeFeatureVectors
        
        eval(['comp_feature_vec = ' ComputeFeatureVectors.SAVE_OBJ_NAME ';']);

        % validate feature lengths
        ftr_depth = size(comp_feature_vec.features,2);
        no_ftr_types = length(comp_feature_vec.feature_types);
        assert(ftr_depth == sum(comp_feature_vec.feature_depths), 'returnFeatureList:FeaturesMismatch', 'The feature data doesn''t match with feature_depths');
        assert(no_ftr_types == length(comp_feature_vec.feature_depths), 'returnFeatureList:FeaturesMismatch', 'The no. of features doesn''t match with feature_depths');
        assert(no_ftr_types == length(comp_feature_vec.cell_features), 'returnFeatureList:FeaturesMismatch', 'The no. of features doesn''t match with cell_features');

        % get feature depths and cell_features
        feature_depths = comp_feature_vec.feature_depths;
        cell_features = comp_feature_vec.cell_features;
    end
    
    
    % initialize the feature texts
    feature_list = cell(sum(feature_depths), 1);

    % iterate over all features
    for feature_id = 1:length(feature_depths)
        s = cell_features{feature_id}.returnFeatureList();

        assert(length(s)==feature_depths(feature_id), 'returnFeatureList:FeaturesMismatch', 'The no. of features returned by returnFeatureList() don''t match up');
        temp = sum(feature_depths(1:feature_id-1));

        feature_list(temp+1:temp+feature_depths(feature_id)) = s;
    end
end

