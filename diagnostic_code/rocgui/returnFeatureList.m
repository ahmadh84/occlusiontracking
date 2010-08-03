function [ feature_list scene_id unique_id ] = returnFeatureList( filepath_or_obj, tooltip_format )
%RETURNFEATURELIST Takes a mat file for or an object of 
%   ClassifierOutputHandler or ComputeFeatureVectors and gets all the texts 
%   pertaining to all features

    if ~exist('tooltip_format', 'var')
        tooltip_format = 0;
    end
    
    if isobject(filepath_or_obj)
    % if it was an object
        curr_obj = filepath_or_obj;
        
        if isa(curr_obj, 'ClassifierOutputHandler')
            scene_id = curr_obj.scene_id;
            unique_id = curr_obj.unique_id;
        elseif isa(curr_obj, 'ComputeFeatureVectors')
            scene_id = [];
            unique_id = curr_obj.getUniqueID();
        end
        
    elseif ischar(filepath_or_obj)
    % if it was an class
        assert(exist(filepath_or_obj, 'file')==2, 'returnFeatureList:FileDoesntExist', 'The feature filepath given for listing doesn''t exist');

        % get the scene id and the unique id
        tok = regexp(filepath_or_obj, '(\d+)_(\w+)_((?:rffeatureimp)|(?:FV)).mat$', 'tokens');
        assert(length(tok)==1 && length(tok{1})==3, 'returnFeatureList:IncorrectFile', 'Couldn''t decipher scene_id and unique_id from filename OR filename not supported');
        scene_id = tok{1}{1};
        unique_id = tok{1}{2};

        fprintf('--> Loading object from %s\n', filepath_or_obj);
        s = load(filepath_or_obj);
        temp = fields(s);
        curr_obj = s.(temp{1});
    else
        error('returnFeatureList:Invalid input', 'Invalid input to returnFeatureList');
    end
    
    if isa(curr_obj, 'ClassifierOutputHandler')
        % pull data from ClassifierOutputHandler
        
        % validate feature length
        ftr_depth = length(curr_obj.feature_importance);
        no_ftr_types = length(curr_obj.feature_types);
        assert(ftr_depth == sum(curr_obj.feature_depths), 'returnFeatureList:FeaturesMismatch', 'The feature data doesn''t match with feature_depths');
        
        % get feature depths and cell_features
        feature_depths = curr_obj.feature_depths;
        cell_features = curr_obj.settings.cell_features;
    elseif isa(curr_obj, 'ComputeFeatureVectors')
        % pull data from ComputeFeatureVectors
        
        % validate feature lengths
        ftr_depth = size(curr_obj.features,2);
        no_ftr_types = length(curr_obj.feature_types);
        assert(ftr_depth == sum(curr_obj.feature_depths), 'returnFeatureList:FeaturesMismatch', 'The feature data doesn''t match with feature_depths');
        assert(no_ftr_types == length(curr_obj.feature_depths), 'returnFeatureList:FeaturesMismatch', 'The no. of features doesn''t match with feature_depths');
        assert(no_ftr_types == length(curr_obj.cell_features), 'returnFeatureList:FeaturesMismatch', 'The no. of features doesn''t match with cell_features');

        % get feature depths and cell_features
        feature_depths = curr_obj.feature_depths;
        cell_features = curr_obj.cell_features;
    else
        error('returnFeatureList:IncorrectFile', 'File given neither has ComputeFeatureVectors or ClassifierOutputHandler object');
    end
    
    
    % initialize the feature texts
    feature_list = cell(sum(feature_depths), 1);

    % iterate over all features
    for feature_id = 1:length(feature_depths)
        s = cell_features{feature_id}.returnFeatureList();

        assert(length(s)==feature_depths(feature_id), 'returnFeatureList:FeaturesMismatch', 'The no. of features returned by returnFeatureList() don''t match up');
        
        % if need plain string format
        if ~tooltip_format
            for i = 1:length(s)
                temp = repmat({', '}, [1, length(s{i})*2-1]);
                temp(1:2:length(s{i})*2) = s{i};
                s{i} = horzcat(temp{:});
            end
        end
        
        temp = sum(feature_depths(1:feature_id-1));

        feature_list(temp+1:temp+feature_depths(feature_id)) = s;
    end
end

