classdef GradientMagFeature < AbstractFeature
    %GRADIENTMAGFEATURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        no_scales = 1;
        scale = 1;
    end
    
    
    properties (Constant)
        FEATURE_TYPE = 'Gradient Magnitude';
        FEATURE_SHORT_TYPE = 'GM';
    end
    
    
    methods
        function obj = GradientMagFeature( varargin )
            if nargin > 0 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ grad feature_depth ] = calcFeatures( obj, calc_feature_vec )
            if obj.no_scales > 1
                assert(~isempty(fields(calc_feature_vec.im1_scalespace)), 'The scale space for im 1 has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.im1_scalespace.scale == obj.scale && ...
                    calc_feature_vec.im1_scalespace.no_scales >= obj.no_scales, 'The scale space given for im 1 in ComputeFeatureVectors is incompatible');
                
                % initialize the output feature
                grad = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    % get the next image in the scale space
                    im_resized = calc_feature_vec.im1_scalespace.ss{scale_idx};
                    
                    % compute the gradient
                    [dx, dy] = gradient(im_resized);

                    % resize it to the original image size
                    grad(:,:,scale_idx) = imresize(sqrt(dx.^2 + dy.^2), calc_feature_vec.image_sz);
                end
            else
                % compute the gradient
                [dx, dy] = gradient(calc_feature_vec.im1_gray);
                
                % resize it to the original image size
                grad = sqrt(dx.^2 + dy.^2);
            end
            
            feature_depth = size(grad,3);
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
    end
    
end

