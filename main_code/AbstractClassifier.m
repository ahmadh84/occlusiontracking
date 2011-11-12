classdef AbstractClassifier < handle
    %ABSTRACTCLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract, Constant)
        CLSFR_TYPE;
        CLSFR_SHORT_TYPE;
        
        CLSFR_EXEC_PATH;
        %settings.RANDOM_FOREST_RUN = 'randomForest\src\predictDescriptor\Release\predictDescriptor.exe ';
    end
    
    
    properties
        
        silent_mode = 0;
    end
    
    
    % OpenCV Random Forest parameters
%     settings.RF_MAX_DEPTH = '35';           % maximum levels in a tree
%     settings.RF_MIN_SAMPLE_COUNT = '20';    % don't split a node if less
%     settings.RF_MAX_CATEGORIES = '25';      % limits the no. of categorical values before the decision tree preclusters those categories so that it will have to test no more than 2^max_categories–2 possible value subsets. Low values reduces computation at the cost of accuracy
%     settings.RF_NO_ACTIVE_VARS = '11';      % size of randomly selected subset of features to be tested at any given node (typically the sqrt of total no. of features)
%     settings.RF_MAX_TREE_COUNT = '105';
%     settings.RF_GET_VAR_IMP = '1';          % calculate the variable importance of each feature during training (at cost of additional computation time)

    
    properties (Access = private)
    end
    
    
    methods
        function clsfr_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = uint8(obj.CLSFR_SHORT_TYPE);
            nos = double(nos) .* ([1:length(nos)].^2);
            clsfr_no_id = sum(nos);
        end
    end
    
    
    methods (Access = private)
        function filename = getTestingDataFilename(obj, scene_id, comp_feat_vec_id, only_of)
            if isnumeric(scene_id)
                scene_id = num2str(scene_id);
            end
            if isnumeric(comp_feat_vec_id)
                comp_feat_vec_id = num2str(comp_feat_vec_id);
            end
            
            if exist('only_of', 'var') && ~isempty(only_of)
                filename = fullfile(obj.out_dir, [scene_id '_' comp_feat_vec_id '_' only_of '_Test.data']);
            else
                filename = fullfile(obj.out_dir, [scene_id '_' comp_feat_vec_id '_Test.data']);
            end
            
            d = fileparts(filename);
            if ~exist(d, 'dir')
                mkdir(d);
            end
        end
        
        
        function filename = getTrainingDataFilename(obj, scene_id, comp_feat_vec_id, only_of)
            if isnumeric(scene_id)
                scene_id = num2str(scene_id);
            end
            if isnumeric(comp_feat_vec_id)
                comp_feat_vec_id = num2str(comp_feat_vec_id);
            end
            
            if exist('only_of', 'var') && ~isempty(only_of)
                filename = fullfile(obj.out_dir, [scene_id '_' comp_feat_vec_id '_' only_of '_Train.data']);
            else
                filename = fullfile(obj.out_dir, [scene_id '_' comp_feat_vec_id '_Train.data']);
            end
            
            d = fileparts(filename);
            if ~exist(d, 'dir')
                mkdir(d);
            end
        end
    end
end
