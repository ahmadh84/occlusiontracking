classdef PhotoConstancyFeature < AbstractFeature
    %PHOTOCONSTANCYFEATURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        no_scales = 1;
        scale = 1;
    end
    
    
    properties (Constant)
        NAN_VAL = 100;
        FEATURE_TYPE = 'Photo Constancy';
        FEATURE_SHORT_TYPE = 'PC';
    end
    
    
    methods
        function obj = PhotoConstancyFeature( varargin )
            if nargin > 0 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ photoconst feature_depth ] = calcFeatures( obj, calc_feature_vec )
            if obj.no_scales > 1
                assert(~isempty(fields(calc_feature_vec.im1_scalespace)) && ...
                    ~isempty(fields(calc_feature_vec.im2_scalespace)), ...
                    'The scale space for im 1 and/or im 2 has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.im1_scalespace.scale == obj.scale && ...
                    calc_feature_vec.im1_scalespace.no_scales >= obj.no_scales, 'The scale space given for im 1 in ComputeFeatureVectors is incompatible');
                
                assert(calc_feature_vec.im2_scalespace.scale == obj.scale && ...
                    calc_feature_vec.im2_scalespace.no_scales >= obj.no_scales, 'The scale space given for im 2 in ComputeFeatureVectors is incompatible');
                
                assert(isfield(calc_feature_vec.extra_info, 'flow_scalespace') && ...
                    ~isempty(fields(calc_feature_vec.extra_info.flow_scalespace)), ...
                    'The scale space for UV flow has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.extra_info.flow_scalespace.scale == obj.scale && ...
                    calc_feature_vec.extra_info.flow_scalespace.no_scales >= obj.no_scales, ...
                    'The scale space given for UV flow in ComputeFeatureVectors is incompatible');
                
                
                no_flow_algos = size(calc_feature_vec.extra_info.flow_scalespace.ss{1}, 4);
                
                % initialize the output feature
                photoconst = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos*obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    % get the next image in the scale space
                    im1_resized = calc_feature_vec.im1_scalespace.ss{scale_idx};
                    im2_resized = calc_feature_vec.im2_scalespace.ss{scale_idx};
                    
                    [cols rows] = meshgrid(1:size(im1_resized, 2), 1:size(im1_resized, 1));

                    % iterate over all the candidate flow algorithms
                    for algo_idx = 1:no_flow_algos
                        % get the next flow image in the scale space
                        uv_resized = calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}(:,:,:,algo_idx);

                        % project the second image to the first according to the flow
                        proj_im = interp2(im2_resized, cols + uv_resized(:,:,1), rows + uv_resized(:,:,2), 'cubic');

                        % compute the error in the projection
                        proj_im = abs(im1_resized - proj_im);
                        proj_im(isnan(proj_im)) = PhotoConstancyFeature.NAN_VAL;

                        % store
                        photoconst(:,:,((scale_idx-1)*no_flow_algos)+algo_idx) = imresize(proj_im, calc_feature_vec.image_sz);
                    end
                end
                
                % correct the ordering of features
                temp = reshape(1:no_flow_algos*obj.no_scales, [no_flow_algos obj.no_scales]);
                temp = permute(temp, [2 1]);
                photoconst = photoconst(:,:,temp(:));
            else
                assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                
                no_flow_algos = size(calc_feature_vec.extra_info.calc_flows.uv_flows, 4);
                
                % initialize the output feature
                photoconst = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos);
                
                [cols rows] = meshgrid(1:calc_feature_vec.image_sz(2), 1:calc_feature_vec.image_sz(1));
                
                % iterate over all the candidate flow algorithms
                for algo_idx = 1:no_flow_algos
                    % project the second image to the first according to the flow
                    proj_im = interp2(calc_feature_vec.im2_gray, ...
                        cols + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,1,algo_idx), ...
                        rows + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,2,algo_idx), 'cubic');
                   
                    % compute the error in the projection
                    proj_im = abs(calc_feature_vec.im1_gray - proj_im);
                    proj_im(isnan(proj_im)) = PhotoConstancyFeature.NAN_VAL;
                    
                    % store
                    photoconst(:,:,algo_idx) = proj_im;
                end
            end
            
            feature_depth = size(photoconst,3);
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

