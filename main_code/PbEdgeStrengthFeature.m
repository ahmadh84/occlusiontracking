classdef PbEdgeStrengthFeature < AbstractFeature
    %PBEDGESTRENGTHFEATURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        no_scales = 1;
        scale = 1;
    end
    
    
    properties (Constant)
        FEATURE_TYPE = 'Pb Edge Strength';
        FEATURE_SHORT_TYPE = 'Pb';
    end
    
    
    methods
        function obj = PbEdgeStrengthFeature( varargin )
            if nargin > 0 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ pbedge feature_depth ] = calcFeatures( obj, calc_feature_vec )
            CalcFlows.addPaths()
            
            if obj.no_scales > 1
                error('PbEdgeStrengthFeature:NoScaleSpace', 'Scale space not supported yet');
%                 assert(~isempty(fields(calc_feature_vec.im1_scalespace)), 'The scale space for im 1 has not been defined in the passed ComputeFeatureVectors');
%                 
%                 assert(calc_feature_vec.im1_scalespace.scale == obj.scale && ...
%                     calc_feature_vec.im1_scalespace.no_scales >= obj.no_scales, 'The scale space given for im 1 in ComputeFeatureVectors is incompatible');
%                 
%                 % initialize the output feature
%                 pbedge = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), obj.no_scales);
% 
%                 % iterate for multiple scales
%                 for scale_idx = 1:obj.no_scales
%                     % get the next image in the scale space
%                     im_resized = calc_feature_vec.im1_scalespace.ss{scale_idx};
%                     
%                     % compute the gradient
%                     [pb] = pbCG(im2double(im_resized));
% 
%                     % resize it to the original image size
%                     pbedge(:,:,scale_idx) = imresize(pb, calc_feature_vec.image_sz);
%                 end
            else
                % compute the gradient
                [ pbedge ] = pbCG(im2double(calc_feature_vec.im1));
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
        end
    end
    
end

