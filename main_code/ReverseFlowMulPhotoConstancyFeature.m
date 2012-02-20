classdef ReverseFlowMulPhotoConstancyFeature < AbstractFeature
    %REVERSEFLOWCONSTANCYFEATURE computes:
    %   x' = round(x + u_{12}(x))
    %   ||x - (x' + u_{21}(x'))||
    %   which in short is the distance between the original position and
    %   the position advected by the forward flow followed by the reverse
    %   flow. The constructor takes a cell array of Flow objects which will 
    %   be used for computing this feature. The constructor also optionally 
    %   takes a size 2 vector for computing the feature on scalespace 
    %   (first value: number of scales, second value: resizing factor). If 
    %   using scalespace, ComputeFeatureVectors object passed to
    %   calcFeatures should have extra_info.flow_scalespace (the flow 
    %   scalespace structures) and extra_info.flow_scalespace_r (the 
    %   reverse flow scalespace structures), apart from image_sz. Note that
    %   it is the responsibility of the user to provide enough number of 
    %   scales in both the scalespace structures. If not using scalespace,
    %   extra_info.calc_flows.uv_flows and 
    %   extra_info.calc_flows.uv_flows_reverse are required for computing 
    %   this feature. If using the scalespace, usually, the output features 
    %   go up in the scalespace (increasing gaussian std-dev) with 
    %   increasing depth.
    %
    %   The features are first ordered by algorithms and then with their
    %   respective scale
    
    
    properties
        no_scales = 1;
        scale = 1;
        nhood;
        
        flow_ids = [];
        flow_short_types = {};
    end
    
    
    properties (Constant)
        NAN_VAL = 0;
        FEATURE_TYPE = 'Reverse Flow * Photo Constancy';
        FEATURE_SHORT_TYPE = 'RCmPC';
    end
    
    
    methods
        function obj = ReverseFlowMulPhotoConstancyFeature( cell_flows, nhood, varargin )
            % set this class to require reverse flow
            obj.NEED_REV_FLOW = 1;
            
            assert(~isempty(cell_flows), ['There should be atleast 1 flow algorithm to compute ' class(obj)]);
            
            % store the flow algorithms to be used and their ids
            for algo_idx = 1:length(cell_flows)
                obj.flow_short_types{end+1} = cell_flows{algo_idx}.OF_SHORT_TYPE;
                obj.flow_ids(end+1) = cell_flows{algo_idx}.returnNoID();
            end
            
            % neighborhood window provided by user
            obj.nhood = nhood;
            
            % store any scalespace info provided by user
            if nargin > 1 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ revflowconst feature_depth compute_time ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of revflowconst is the same as the input image, 
        %   with a depth equivalent to the number of flow algos times the 
        %   number of scales
        
            t_start_main = tic;
            
            % find which algos to use
            algos_to_use = cellfun(@(x) find(strcmp(x, calc_feature_vec.extra_info.calc_flows.algo_ids)), obj.flow_short_types);

            assert(length(algos_to_use)==length(obj.flow_short_types), ['Can''t find matching flow algorithm(s) used in computation of ' class(obj)]);
            
            if obj.no_scales > 1
                assert(isfield(calc_feature_vec.extra_info, 'flow_scalespace') && ...
                    ~isempty(fields(calc_feature_vec.extra_info.flow_scalespace)) && ...
                    ~isempty(fields(calc_feature_vec.extra_info.flow_scalespace_r)), ...
                    'The scale space for UV flow (or/and its reverse) has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.extra_info.flow_scalespace.scale == obj.scale && ...
                    calc_feature_vec.extra_info.flow_scalespace.no_scales >= obj.no_scales && ...
                    calc_feature_vec.extra_info.flow_scalespace_r.scale == obj.scale && ...
                    calc_feature_vec.extra_info.flow_scalespace_r.no_scales >= obj.no_scales, ...
                    'The scale space given for UV flow (or/and its reverse) in ComputeFeatureVectors is incompatible');
                
                
                no_flow_algos = length(obj.flow_short_types);
                
                % initialize the output feature
                revflowconst = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos*obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    im_sz = size(calc_feature_vec.extra_info.flow_scalespace_r.ss{scale_idx}(:,:,1,1));
                    
                    im1_resized = calc_feature_vec.im1_cielab_scalespace.ss{scale_idx};
                    im2_resized = calc_feature_vec.im2_cielab_scalespace.ss{scale_idx};
                    
                    [cols rows] = meshgrid(1:im_sz(2), 1:im_sz(1));

                    % compute length variance for each optical flow given
                    %lenvar = OFLengthVarianceFeature.computeLenVarForEachUV( calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}(:,:,:,algos_to_use), obj.nhood, im_sz );
                    
                    % iterate over all the candidate flow algorithms
                    for algo_idx = 1:no_flow_algos
                        algo_id = strcmp(obj.flow_short_types{algo_idx}, calc_feature_vec.extra_info.calc_flows.algo_ids);
                        
                        assert(nnz(algo_id) == 1, ['Can''t find matching flow algorithm used in computation of ' class(obj)]);
                        
                        % get the next flow image in the scale space
                        uv_resized = calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}(:,:,:,algo_id);
                        uv_resized_reverse = calc_feature_vec.extra_info.flow_scalespace_r.ss{scale_idx}(:,:,:,algo_id);
                        
                        % compute photoconstancy
                        proj_im = PhotoConstancyFeature.computePhotoConstancy(im1_resized, im2_resized, uv_resized, cols, rows);
                        
                        % compute x' = round(x + u_{12}(x)) (advected point)
                        r_dash = rows + uv_resized(:,:,2);
                        c_dash = cols + uv_resized(:,:,1);
                        r_dash = round(r_dash);
                        c_dash = round(c_dash);
                        
                        % find the points which have fallen outside the image
                        outside_idcs = r_dash < 1 | r_dash > im_sz(1) | c_dash < 1 | c_dash > im_sz(2);
                        r_dash(outside_idcs) = 1;
                        c_dash(outside_idcs) = 1;
                        
                        % get the reverse flow
                        rev_v = uv_resized_reverse(:,:,2);
                        rev_u = uv_resized_reverse(:,:,1);

                        %  compute ||x - (x' + u_{21}(x'))||
                        ind_dash = sub2ind(im_sz, r_dash, c_dash);

                        r_dash = r_dash + rev_v(ind_dash);
                        c_dash = c_dash + rev_u(ind_dash);

                        reverse_dist = sqrt((rows - r_dash).^2 + (cols - c_dash).^2);
                        reverse_dist = reverse_dist .* (proj_im.^2);
                        %reverse_dist = reverse_dist .* abs(im1_resized - im2_resized(ind_dash));
                        %reverse_dist = reverse_dist .* (sqrt(uv_resized_reverse(:,:,2).^2 + uv_resized_reverse(:,:,1).^2) + sqrt(uv_resized(:,:,2).^2 + uv_resized(:,:,1).^2));
                        reverse_dist(outside_idcs) = ReverseFlowMulPhotoConstancyFeature.NAN_VAL;
                        
                        % store
                        revflowconst(:,:,((algo_idx-1)*obj.no_scales)+scale_idx) = imresize(reverse_dist, calc_feature_vec.image_sz);
                    end
                end
            else
                assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                assert(~isempty(calc_feature_vec.extra_info.calc_flows.uv_flows_reverse), 'The reverse flow in CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                
                no_flow_algos = length(obj.flow_short_types);
                
                % initialize the output feature
                revflowconst = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos);
                
                [cols rows] = meshgrid(1:calc_feature_vec.image_sz(2), 1:calc_feature_vec.image_sz(1));
                
                % iterate over all the candidate flow algorithms
                for algo_idx = 1:no_flow_algos
                    algo_id = strcmp(obj.flow_short_types{algo_idx}, calc_feature_vec.extra_info.calc_flows.algo_ids);
                    
                    assert(nnz(algo_id) == 1, ['Can''t find matching flow algorithm used in computation of ' class(obj)]);
                    
                    % compute x' = round(x + u_{12}(x)) (advected point)
                    r_dash = rows + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,2,algo_id);
                    c_dash = cols + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,1,algo_id);
                    r_dash = round(r_dash);
                    c_dash = round(c_dash);
                    
                    % find the points which have fallen outside the image
                    outside_idcs = r_dash < 1 | r_dash > calc_feature_vec.image_sz(1) | c_dash < 1 | c_dash > calc_feature_vec.image_sz(2);
                    r_dash(outside_idcs) = 1;
                    c_dash(outside_idcs) = 1;
                    
                    % get the reverse flow
                    rev_v = calc_feature_vec.extra_info.calc_flows.uv_flows_reverse(:,:,2,algo_id);
                    rev_u = calc_feature_vec.extra_info.calc_flows.uv_flows_reverse(:,:,1,algo_id);
                    
                    %  compute ||x - (x' + u_{21}(x'))||
                    ind_dash = sub2ind(calc_feature_vec.image_sz, r_dash, c_dash);
                    
                    r_dash = r_dash + rev_v(ind_dash);
                    c_dash = c_dash + rev_u(ind_dash);
                    
                    reverse_dist = sqrt((rows - r_dash).^2 + (cols - c_dash).^2);
                    reverse_dist(outside_idcs) = ReverseFlowMulPhotoConstancyFeature.NAN_VAL;
                    
                    % store
                    revflowconst(:,:,algo_idx) = reverse_dist;
                end
            end
            
            feature_depth = size(revflowconst,3);
            
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
            
            return_feature_list = cell(obj.no_scales * length(obj.flow_short_types),1);
            
            for flow_id = 1:length(obj.flow_short_types)
                starting_no = (flow_id-1)*obj.no_scales;
                
                return_feature_list{starting_no+1} = {[obj.FEATURE_TYPE ' using ' obj.flow_short_types{flow_id}], 'no scaling'};

                for scale_id = 2:obj.no_scales
                    return_feature_list{starting_no+scale_id} = {[obj.FEATURE_TYPE ' using ' obj.flow_short_types{flow_id}], ['scale ' num2str(scale_id)], ['size ' sprintf('%.1f%%', (obj.scale^(scale_id-1))*100)]};
                end
            end
        end
    end

end

