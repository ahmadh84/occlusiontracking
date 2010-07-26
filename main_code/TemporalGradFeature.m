classdef TemporalGradFeature < AbstractFeature
    %TEMPORALGRADFEATURE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        no_scales = 1;
        scale = 1;
    end
    
    
    properties (Constant)
        FEATURE_TYPE = 'Temporal Gradient';
        FEATURE_SHORT_TYPE = 'TG';
    end
    
    
    methods
        function obj = TemporalGradFeature( varargin )
            if nargin > 0 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ tgrad feature_depth ] = calcFeatures( obj, calc_feature_vec )
            if obj.no_scales > 1
                assert(isfield(calc_feature_vec.extra_info, 'flow_scalespace') && ...
                    ~isempty(fields(calc_feature_vec.extra_info.flow_scalespace)), ...
                    'The scale space for UV flow has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.extra_info.flow_scalespace.scale == obj.scale && ...
                    calc_feature_vec.extra_info.flow_scalespace.no_scales >= obj.no_scales, ...
                    'The scale space given for UV flow in ComputeFeatureVectors is incompatible');
                
                % initialize the output feature
                tgradx = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), obj.no_scales);
                tgrady = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    % get the scale space of candidate flow algorithms
                    uv_resized = calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx};
                    
                    % get the median flow (make 2 dim matrix - quicker! :s)
                    sz_temp = size(uv_resized);
                    uv_resized = reshape(uv_resized, [sz_temp(1)*sz_temp(2)*sz_temp(3) sz_temp(4)]);
                    median_flow = median(uv_resized, 2);
                    median_flow = reshape(median_flow, [sz_temp(1) sz_temp(2) sz_temp(3)]);
                    
                    % compute the X gradient
                    [dx, dy] = gradient(median_flow(:,:,1));

                    % resize it to the original image size
                    tgradx(:,:,scale_idx) = imresize(sqrt(dx.^2 + dy.^2), calc_feature_vec.image_sz);
                    
                    % compute the Y gradient
                    [dx, dy] = gradient(median_flow(:,:,2));

                    % resize it to the original image size
                    tgrady(:,:,scale_idx) = imresize(sqrt(dx.^2 + dy.^2), calc_feature_vec.image_sz);
                end
            else
                assert(isfield(calc_feature_vec.extra_info, 'uv_flows'), 'The UV flow has not been defined in the passed ComputeFeatureVectors');
                
                % get the candidate flow algorithms
                uv_flow = calc_feature_vec.extra_info.uv_flows;
                
                % get the median flow (make 2 dim matrix - quicker! :s)
                sz_temp = size(uv_flow);
                uv_flow = reshape(uv_flow, [sz_temp(1)*sz_temp(2)*sz_temp(3) sz_temp(4)]);
                median_flow = median(uv_flow, 2);
                median_flow = reshape(median_flow, [sz_temp(1) sz_temp(2) sz_temp(3)]);

                % compute the X gradient
                [dx, dy] = gradient(median_flow(:,:,1));

                % resize it to the original image size
                tgradx = imresize(sqrt(dx.^2 + dy.^2), calc_feature_vec.image_sz);

                % compute the Y gradient
                [dx, dy] = gradient(median_flow(:,:,2));

                % resize it to the original image size
                tgrady = imresize(sqrt(dx.^2 + dy.^2), calc_feature_vec.image_sz);
            end
            
            % combine the x and y gradient
            tgrad = cat(3, tgradx, tgrady);
            
            feature_depth = size(tgrad,3);
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

