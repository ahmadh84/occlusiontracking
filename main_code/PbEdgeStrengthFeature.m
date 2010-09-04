classdef PbEdgeStrengthFeature < AbstractFeature
    %PBEDGESTRENGTHFEATURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        threshold_pb;
        
        no_scales = 1;
        scale = 1;
    end
    
    
    properties (Constant)
        PRECOMPUTED_PB_FILE = 'pb.mat';
        
        FEATURE_TYPE = 'Pb Edge Strength';
        FEATURE_SHORT_TYPE = 'PB';
    end
    
    
    methods
        function obj = PbEdgeStrengthFeature( threshold, varargin )
            % threshold for Pb provided by user
            obj.threshold_pb = threshold;
            
            if nargin > 1 && isvector(varargin{2}) && length(varargin{2}) == 2
                obj.no_scales = varargin{2}(1);
                obj.scale = varargin{2}(2);
            end
        end
        
        
        function [ pbedge feature_depth ] = calcFeatures( obj, calc_feature_vec )
            CalcFlows.addPaths()
            
            if obj.no_scales > 1
                error('PbEdgeStrengthFeature:NoScaleSpace', 'Scale space not supported yet');
                assert(~isempty(fields(calc_feature_vec.im1_scalespace)), 'The scale space for im 1 has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.im1_scalespace.scale == obj.scale && ...
                    calc_feature_vec.im1_scalespace.no_scales >= obj.no_scales, 'The scale space given for im 1 in ComputeFeatureVectors is incompatible');
                
                % initialize the output feature
                pbedge = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    % get the next image in the scale space
                    im_resized = calc_feature_vec.im1_scalespace.ss{scale_idx};
                    
                    % compute the probability of boundary
                    if size(calc_feature_vec.im1,3) == 1
                        [ pbedge ] = pbBGTG(im2double(im_resized));
                    else
                        [ pbedge ] = pbCGTG(im2double(im_resized));
                    end

                    % compute distance transform and resize it to the original image size
                    pbedge = imresize(bwdist(pbedge > obj.threshold_pb), calc_feature_vec.image_sz);
                    
                    % resize it to the original image size
                    pbedge(:,:,scale_idx) = imresize(pb, calc_feature_vec.image_sz);
                end
            else
                % if precomputed pb exists
                if exist(fullfile(calc_feature_vec.scene_dir, obj.PRECOMPUTED_PB_FILE), 'file') == 2
                    load(fullfile(calc_feature_vec.scene_dir, obj.PRECOMPUTED_PB_FILE));
                else
                    % compute the probability of boundary
                    if size(calc_feature_vec.im1,3) == 1
                        [ pbedge ] = pbBGTG(im2double(calc_feature_vec.im1));
                    else
                        [ pbedge ] = pbCGTG(im2double(calc_feature_vec.im1));
                    end
                end
                
                % compute distance transform and resize it to the original image size
                pbedge = imresize(double(bwdist(pbedge > obj.threshold_pb)), calc_feature_vec.image_sz);
            end
            
            feature_depth = size(pbedge,3);
        end
        
        
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = returnNoID@AbstractFeature(obj);
            
            temp = obj.no_scales^obj.scale;
            % get first 2 decimal digits
            temp = mod(round(temp*100), 100);
            feature_no_id = (nos*100) + temp;
            
            % incorporate the threshold
            feature_no_id = round(obj.threshold_pb * feature_no_id);
        end
    end
    
end

