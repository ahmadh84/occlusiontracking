classdef EdgeDistFeature < AbstractFeature
    %EDGEDISTFEATURE the distance transfrom from the edges in the first 
    %   image (using canny edge detector). The constructor either takes 
    %   nothing or size 2 vector for computing the feature on scalespace 
    %   (first value: number of scales, second value: resizing factor). If 
    %   using scalespace, ComputeFeatureVectors object passed to
    %   calcFeatures should have im1_scalespace (the scalespace structure),
    %   apart from image_sz. image_sz and im1_gray are required for 
    %   computing this feature without scalespace. . If using the 
    %   scalespace, usually, the output features go up in the scalespace 
    %   (increasing gaussian std-dev) with increasing depth.
    
    
    properties
        no_scales = 1;
        scale = 1;
    end
    
    
    properties (Constant)
        FEATURE_TYPE = 'Edge Distance';
        FEATURE_SHORT_TYPE = 'ED';
    end
    
    
    methods
        function obj = EdgeDistFeature( varargin )
            if nargin > 0 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ dist feature_depth compute_time ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of dist is the same as the input image, with a
        %   depth equivalent to the number of scales
        
            t_start_main = tic;
            
            if obj.no_scales > 1
                assert(~isempty(fields(calc_feature_vec.im1_scalespace)), 'The scale space for im 1 has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.im1_scalespace.scale == obj.scale && ...
                    calc_feature_vec.im1_scalespace.no_scales >= obj.no_scales, 'The scale space given for im 1 in ComputeFeatureVectors is incompatible');
                
                % initialize the output feature
                dist = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    % get the next flow image in the scale space
                    im_resized = calc_feature_vec.im1_scalespace.ss{scale_idx};
                    
                    % compute the edge image
                    edge_im = edge(im_resized, 'canny');
                    
                    % compute distance transform and resize it to the original image size
                    dist(:,:,scale_idx) = imresize(bwdist(edge_im), calc_feature_vec.image_sz);
                end
            else
                % compute the edge image
                edge_im = edge(calc_feature_vec.im1_gray, 'canny');
                
                % compute distance transform and resize it to the original image size
                dist = imresize(bwdist(edge_im), calc_feature_vec.image_sz);
            end
            
            feature_depth = size(dist,3);
            
            compute_time = toc(t_start_main);
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
        end
        
        
        function return_feature_list = returnFeatureList(obj)
        % creates a cell vector where each item contains a string of the
        % feature type (in the order the will be spit out by calcFeatures)
            
            return_feature_list = cell(obj.no_scales,1);
            
            return_feature_list{1} = {obj.FEATURE_TYPE, 'no scaling'};
            
            for scale_id = 2:obj.no_scales
                return_feature_list{scale_id} = {obj.FEATURE_TYPE, ['scale ' num2str(scale_id)], ['size ' sprintf('%.1f%%', (obj.scale^(scale_id-1))*100)]};
            end
        end
    end
    
end

