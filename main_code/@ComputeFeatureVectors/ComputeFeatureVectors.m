classdef ComputeFeatureVectors < handle
    %COMPUTEFEATUREVECTORS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant, Transient)
        SAVE_OBJ_NAME = 'comp_feature_vector';
    end
    
    
    properties (Transient)
        im1;
        im2;
        im1_gray;
        im2_gray;
        im1_scalespace = struct;
        im2_scalespace = struct;
        extra_info = struct;
    end
    
    
    properties
        image_sz;
        scene_dir;
        cell_features;
        features = [];
        feature_depths = [];
        feature_types = {};
        feature_compute_times = [];
        extra_id = 0;
        
        silent_mode = 0;
    end
    
    
    properties (Access = private)
        no_feature_types;
        compute_refresh = 0;
    end
    
    
    methods
        function obj = ComputeFeatureVectors( scene_dir, cell_features, varargin )
            obj.scene_dir = scene_dir;
            
            % store all feature objects
            obj.cell_features = cell_features;
            obj.no_feature_types = length(obj.cell_features);
            
            obj.feature_compute_times = zeros(1, length(obj.cell_features));
            
            % load images
            obj.im1 = imread(fullfile(obj.scene_dir, ComputeTrainTestData.IM1_PNG));
            obj.im2 = imread(fullfile(obj.scene_dir, ComputeTrainTestData.IM2_PNG));
            
            % save grayscales
            if size(obj.im1,3) > 1
                obj.im1_gray = im2double(rgb2gray(obj.im1));
                obj.im2_gray = im2double(rgb2gray(obj.im2));
            else
                obj.im1_gray = im2double(obj.im1);
                obj.im2_gray = im2double(obj.im2);
            end
            
            % store the original image size
            obj.image_sz = [ size(obj.im1,1), size(obj.im1,2) ];
            
            % if extra info needs to be stored for feature computation
            if nargin > 2 && isstruct(varargin{1})
                obj.extra_info = varargin{1};
                obj.extra_id = obj.extra_info.calc_flows.getUniqueID();
            end
            
            % if user wants to have im1 scale space
            if nargin > 3 && isvector(varargin{2}) && length(varargin{2}) == 2
                obj.im1_scalespace.no_scales = varargin{2}(1);
                obj.im1_scalespace.scale = varargin{2}(2);
                obj.im1_scalespace.ss = ComputeFeatureVectors.computeScaleSpace(obj.im1_gray, varargin{2}(1), varargin{2}(2));
            end
            
            % if user wants to have im1 scale space
            if nargin > 4 && isvector(varargin{3}) && length(varargin{3}) == 2
                obj.im2_scalespace.no_scales = varargin{3}(1);
                obj.im2_scalespace.scale = varargin{3}(2);
                obj.im2_scalespace.ss = ComputeFeatureVectors.computeScaleSpace(obj.im2_gray, varargin{3}(1), varargin{3}(2));
            end
            
            % if user wants to recompute everything and not pick up from file
            if nargin > 5 && isscalar(varargin{4})
                obj.compute_refresh = varargin{4};
            end
            
            % if user wants silent mode
            if nargin > 6 && isscalar(varargin{5})
                obj.silent_mode = varargin{5};
            end
            
            % finally, compute the features
            obj.computeAllFeatures();
        end
        
        
        function removeFeatures( obj, del_feature_cols )
            % delete the feature cols
            obj.features(:,del_feature_cols) = [];
            
            % count the number of vectors removed for each feature
            limits = [0.5 cumsum(obj.feature_depths)+0.5];
            cnt = histc(del_feature_cols, limits);
            cnt(end) = [];
            
            % adjust the depth and type if necessary
            obj.feature_depths = obj.feature_depths - cnt;
            del_feat = obj.feature_depths == 0;
            if any(del_feat)
                obj.feature_depths(del_feat) = [];
                obj.feature_types(del_feat) = [];
            end
        end
        
        
        function unique_id = getUniqueID( obj )
            unique_id = [];
            
            for feature_idx = 1:obj.no_feature_types
                unique_id = [unique_id obj.cell_features{feature_idx}.returnNoID()];
            end
            
            % sum them since order doesn't matter
            unique_id = sum(unique_id);
            
            % append extra info id
            unique_id = unique_id + obj.extra_id;
        end
    end
    
    
    methods (Access = private)
        % main function defined in m file
        computeAllFeatures( obj );
        
        
        function bool = checkStoredObjAvailable( obj )
        % check if the stored object is available
            bool = (exist(fullfile(obj.scene_dir, obj.getMatFilename()), 'file') == 2) & (~obj.compute_refresh);
        end
        
        
        function deepCopy( obj, new_obj )
        % copies all the properties given in new_obj to the current object
            mc = metaclass(new_obj);
            for prop_idx = 1:length(mc.Properties)
                if strcmp(mc.Properties{prop_idx}.GetAccess, 'public') && strcmp(mc.Properties{prop_idx}.SetAccess, 'public')
                    prop_name = mc.Properties{prop_idx}.Name;
                    obj.(prop_name) = new_obj.(prop_name);
                end
            end
            
            % adjust no. of features
            obj.no_feature_types = length(obj.cell_features);
        end
        
        
        function filename = getMatFilename( obj )
            % get the scene id
            [d sceneID] = fileparts(obj.scene_dir);
            if isempty(sceneID)
                [temp, sceneID] = fileparts(d);
            end
            
            filename = [sceneID '_' sprintf('%d', obj.getUniqueID()) '_FV.mat'];
        end
    end
    
    
    methods (Static)
        function [ im_scalespace ] = computeScaleSpace( im, no_scales, scale )
            im_scalespace = { im };
            for scale_idx = 2:no_scales
                % place a resized version in the stack
                im_scalespace{scale_idx} = imresize(im_scalespace{scale_idx-1}, scale);
            end
        end
    end
end

