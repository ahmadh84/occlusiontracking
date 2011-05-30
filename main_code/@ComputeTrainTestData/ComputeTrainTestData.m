classdef ComputeTrainTestData < handle
    %COMPUTETRAINTESTDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant, Transient)
        UTILS_PATH = fullfile(pwd, 'utils');
        IM1_PNG = '1.png';
        IM2_PNG = '2.png';
    end
    
    
    properties
        main_dir;
        out_dir;
        settings;
        silent_mode = 0;
    end
    
    
    properties (Access = private)
        force_no_gt = 0;
        compute_refresh = 0;
        feat_vec_flows_once_computed = [];
    end
    
    
    methods
        function obj = ComputeTrainTestData( main_dir, out_dir, settings, varargin )
            
            % if user wants silent mode
            if nargin > 5 && isscalar(varargin{3})
                obj.silent_mode = varargin{3};
            end
            
            if ~obj.silent_mode
                fprintf('Creating ComputeTrainTestData\n');
            end
            
            assert(isdir(main_dir), 'Cannot locate the directory path provided');
            
            % if the output directory doesn't exist, create it
            if ~isdir(out_dir)
                mkdir(out_dir);
            end
            
            obj.main_dir = main_dir;
            obj.out_dir = out_dir;
            
            obj.settings = settings;
            
            % if user wants to force that there is no GT
            if nargin > 3 && isscalar(varargin{1})
                obj.force_no_gt = varargin{1};
            end
            
            % if user wants to recompute everything and not pick up from file
            if nargin > 4 && isscalar(varargin{2})
                obj.compute_refresh = varargin{2};
            end
            
            ComputeTrainTestData.addPaths();
        end
        
        
        function [ train_filepath test_filepath unique_id ] = produceTrainingTestingData( obj, scene_id, training_ids )
            % check if the scene id is not present in training ids
            assert(~any(scene_id == training_ids), 'The scene id provided should not be present in the set of training ids');
            
            [comp_feat_vec calc_flows] = obj.getFeatureVecAndFlow(scene_id);
            
            % send the unique id used for appending to filenames
            unique_id = comp_feat_vec.getUniqueID();
            
            % produce the training data
            if ~obj.force_no_gt
                [ train_filepath ] = obj.produceTrainingDataFile( scene_id, training_ids, unique_id );
            end
            
            % produce the testing data
            [ test_filepath ] = obj.produceTestingDataFile( scene_id, comp_feat_vec, calc_flows );
        end
        
        
        function [ test_filepath unique_id ] = produceTestingData( obj, scene_id )
            [comp_feat_vec calc_flows] = obj.getFeatureVecAndFlow(scene_id);
            
            % send the unique id used for appending to filenames
            unique_id = comp_feat_vec.getUniqueID();
            
            % produce the testing data
            [ test_filepath ] = obj.produceTestingDataFile( scene_id, comp_feat_vec, calc_flows );
        end
        
        
        function [ train_filepath unique_id ] = produceTrainingData( obj, scene_id, training_ids, unique_id )
            % if unique_id not passed by the user, get it by loading a feature vector
            if ~exist('unique_id', 'var') == 1
                [comp_feat_vec calc_flows] = obj.getFeatureVecAndFlow(training_ids(1));

                % send the unique id used for appending to filenames
                unique_id = comp_feat_vec.getUniqueID();
            end
            
            % produce the training data
            [ train_filepath ] = obj.produceTrainingDataFile( scene_id, training_ids, unique_id );
        end
        
        
        [ comp_feat_vec calc_flow ] = getFeatureVecAndFlow(obj, scene_id);
    end
    
    
    methods (Access = private)
        [ train_filepath ] = produceTrainingDataFile( obj, scene_id, training_ids, comp_feat_vec );
        
        
        [ test_filepath ] = produceTestingDataFile( obj, scene_id, comp_feat_vec, calc_flows );
        
        
        [ extra_info ] = extraFVInfoStruct( obj, im1, im2, calc_flows, no_scales, scale );

        
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
        
        
        function scene_dir = sceneId2SceneDir(obj, scene_id)
            % get the scene dir
            if isnumeric(scene_id)
                scene_id = num2str(scene_id);
            end
            scene_dir = fullfile(obj.main_dir, scene_id);
            
            % check if dir exists
            assert(isdir(scene_dir), sprintf('The directory %s does not exist', scene_dir));
        end
    end
    
    
    methods (Static)
        function addPaths()
        % add paths if not already in path
            addpath(genpath(ComputeTrainTestData.UTILS_PATH));
        end
        
        
        function [ comp_feat_vec extra_label_info ] = adjustFeaturesInfo(comp_feat_vec, calc_flows, extra_label_info, settings, NO_GT)
            % get error - get rid of reprojection error of other algos - be carefull if you change feature vector
            algo_idx = find(strcmp(calc_flows.algo_ids, settings.USE_ONLY_OF));
            
            if ~isempty(algo_idx)
                if ~NO_GT
                    % pull out both angular error and EPE and store in
                    % extra info (this will be extra info passed to the 
                    % label object)
                    extra_label_info.uv_ang_err = calc_flows.uv_ang_err(:,:,algo_idx);
                    extra_label_info.uv_epe = calc_flows.uv_epe(:,:,algo_idx);
                end

                % find the photoconstancy feature
                pc_feat_idx = find(strcmp(comp_feat_vec.feature_types, PhotoConstancyFeature.FEATURE_SHORT_TYPE));
                feat_depth_idxs = cumsum([0 comp_feat_vec.feature_depths]);
                pc_feat_cols = feat_depth_idxs(pc_feat_idx)+1:feat_depth_idxs(pc_feat_idx+1);
                
                % get the cols that need to be deleted
                needed_pc_cols = pc_feat_cols(algo_idx:length(calc_flows.algo_ids):end);
                delete_pc_cols = setdiff(pc_feat_cols, needed_pc_cols);
                
                % remove the cols from the feature vector data
                comp_feat_vec.removeFeatures(delete_pc_cols);
            end
        end
    end
end

