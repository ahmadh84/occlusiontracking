classdef OFLengthFeature < AbstractFeature
    %TEMPORALGRADFEATURE computes the ||\nabla\bar{u}||, ||\nabla\bar{v}|| 
    %   the gradient magnitude of flow. Each computation results in two
    %   features: temporal gradient magnitude of u and v. The 
    %   constructor takes a cell array of Flow objects which will be used 
    %   for computing this feature (the median of all the flow outputs is 
    %   used). The constructor also optionally takes a size 2 vector for 
    %   computing the feature on scalespace (first value: number of scales, 
    %   second value: resizing factor). If using scalespace, 
    %   ComputeFeatureVectors object passed to calcFeatures should have 
    %   extra_info.flow_scalespace (the scalespace structure), apart from 
    %   image_sz. Note that it is the responsibility of the user to provide 
    %   enough number of scales in all 3 scalespace structures. If not 
    %   using scalespace, extra_info.uv_flows is required for computing 
    %   this feature. If using the scalespace, usually, the output features 
    %   go up in the scalespace (increasing gaussian std-dev) with 
    %   increasing depth.
    %
    %   The features are first ordered by temporal gradient u/v and 
    %   then with their respective scale
    

    properties
        no_scales = 1;
        scale = 1;
        
        flow_ids = [];
        flow_short_types = {};
    end
    
    
    properties (Constant)
        FEATURE_TYPE = 'Flow Vector Length';
        FEATURE_SHORT_TYPE = 'VL';
    end
    
    
    methods
        function obj = OFLengthFeature( cell_flows, varargin )
            assert(~isempty(cell_flows), ['There should be atleast 1 flow algorithm to compute ' class(obj)]);
            
            % store the flow algorithms to be used and their ids
            for algo_idx = 1:length(cell_flows)
                obj.flow_short_types{end+1} = cell_flows{algo_idx}.OF_SHORT_TYPE;
                obj.flow_ids(end+1) = cell_flows{algo_idx}.returnNoID();
            end
            
            % store any scalespace info provided by user
            if nargin > 1 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ flength feature_depth compute_time ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of tgrad is the same as the input image, 
        %   with a depth equivalent to the number of scales times 2

            t_start_main = tic;
            
            % find which algos to use
            algos_to_use = cellfun(@(x) find(strcmp(x, calc_feature_vec.extra_info.calc_flows.algo_ids)), obj.flow_short_types);

            assert(length(algos_to_use)==length(obj.flow_short_types), ['Can''t find matching flow algorithm(s) used in computation of ' class(obj)]);
            
            if obj.no_scales > 1
                assert(isfield(calc_feature_vec.extra_info, 'flow_scalespace') && ...
                    ~isempty(fields(calc_feature_vec.extra_info.flow_scalespace)), ...
                    'The scale space for UV flow has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.extra_info.flow_scalespace.scale == obj.scale && ...
                    calc_feature_vec.extra_info.flow_scalespace.no_scales >= obj.no_scales, ...
                    'The scale space given for UV flow in ComputeFeatureVectors is incompatible');
                
                % initialize the output feature
                flength = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), obj.no_scales);
                
                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    % get the scale space of candidate flow algorithms
                    uv_resized = calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}(:,:,:,algos_to_use);
                    
                    % get the median flow (make 2 dim matrix - quicker! :s)
                    sz_temp = size(uv_resized);
                    uv_resized = reshape(uv_resized, [sz_temp(1)*sz_temp(2)*sz_temp(3) size(uv_resized,4)]);
                    median_flow = median(uv_resized(:,algos_to_use), 2);
                    median_flow = reshape(median_flow, [sz_temp(1) sz_temp(2) sz_temp(3)]);
                    
                    temp = sqrt(median_flow(:,:,1).^2 + median_flow(:,:,2).^2);
                    
                    % resize it to the original image size
                    flength(:,:,scale_idx) = imresize(temp, calc_feature_vec.image_sz);
                end
            else
                assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                
                % get the candidate flow algorithms
                uv_flow = calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,:,algos_to_use);
                
                % get the median flow (make 2 dim matrix - quicker! :s)
                sz_temp = size(uv_flow);
                uv_flow = reshape(uv_flow, [sz_temp(1)*sz_temp(2)*sz_temp(3) sz_temp(4)]);
                median_flow = median(uv_flow, 2);
                median_flow = reshape(median_flow, [sz_temp(1) sz_temp(2) sz_temp(3)]);

                % compute length of each vector
                flength = sqrt(median_flow(:,:,1).^2 + median_flow(:,:,2).^2);
            end
            
            feature_depth = size(flength,3);
            
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
            
            feature_no_id = feature_no_id + sum(obj.flow_ids);
        end
        
        
        function return_feature_list = returnFeatureList(obj)
        % creates a cell vector where each item contains a string of the
        % feature type (in the order the will be spit out by calcFeatures)
            
            return_feature_list = cell(obj.no_scales,1);
            
            return_feature_list{1} = {[obj.FEATURE_TYPE ' using ' num2str(length(obj.flow_short_types)) ' flow algos'], 'no scaling'};

            for scale_id = 2:obj.no_scales
                return_feature_list{scale_id} = {[obj.FEATURE_TYPE ' using ' num2str(length(obj.flow_short_types)) ' flow algos'], ['scale ' num2str(scale_id)], ['size ' sprintf('%.1f%%', (obj.scale^(scale_id-1))*100)]};
            end
        end
    end

end

