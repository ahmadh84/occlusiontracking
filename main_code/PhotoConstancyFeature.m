classdef PhotoConstancyFeature < AbstractFeature
    %PHOTOCONSTANCYFEATURE the |I1(x)-I2(x+u)| the absolute difference in
    %   pixel values of two images using the flow information. The 
    %   constructor takes a cell array of Flow objects which will be used 
    %   for computing this feature. The constructor also optionally takes a 
    %   size 2 vector for computing the feature on scalespace (first value: 
    %   number of scales, second value: resizing factor). If using 
    %   scalespace, ComputeFeatureVectors object passed to calcFeatures 
    %   should have im1_scalespace, im2_scalespace and 
    %   extra_info.flow_scalespace (the scalespace structures), apart from 
    %   image_sz. Note that it is the responsibility of the user to provide 
    %   enough number of scales in all 3 scalespace structures. If not 
    %   using scalespace im1_gray, im2_gray and 
    %   extra_info.calc_flows.uv_flows are required for computing this 
    %   feature. If using the scalespace, usually, the output features go 
    %   up in the scalespace (increasing gaussian std-dev) with increasing 
    %   depth.
    %
    %   The features are first ordered by algorithms and then with their
    %   respective scale
    
    
    properties
        no_scales = 1;
        scale = 1;
        
        flow_ids = [];
        flow_short_types = {};
    end
    
    
    properties (Constant)
        NAN_VAL = 1000;
        FEATURE_TYPE = 'Photo Constancy';
        FEATURE_SHORT_TYPE = 'PC';
    end
    
    
    methods
        function obj = PhotoConstancyFeature( cell_flows, varargin )
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
        
        
        function [ photoconst feature_depth compute_time ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of photoconst is the same as the input image, 
        %   with a depth equivalent to the number of flow algos times the 
        %   number of scales
        
            t_start_main = tic;
            
            if obj.no_scales > 1
                assert(~isempty(fields(calc_feature_vec.im1_scalespace)) && ...
                    ~isempty(fields(calc_feature_vec.im2_scalespace)), ...
                    'The scale space for im 1 and/or im 2 has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.im1_cielab_scalespace.scale == obj.scale && ...
                    calc_feature_vec.im1_cielab_scalespace.no_scales >= obj.no_scales, 'The scale space given for im 1 l*a*b* in ComputeFeatureVectors is incompatible');
                
                assert(calc_feature_vec.im2_cielab_scalespace.scale == obj.scale && ...
                    calc_feature_vec.im2_cielab_scalespace.no_scales >= obj.no_scales, 'The scale space given for im 2 l*a*b* in ComputeFeatureVectors is incompatible');
                
                assert(isfield(calc_feature_vec.extra_info, 'flow_scalespace') && ...
                    ~isempty(fields(calc_feature_vec.extra_info.flow_scalespace)), ...
                    'The scale space for UV flow has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.extra_info.flow_scalespace.scale == obj.scale && ...
                    calc_feature_vec.extra_info.flow_scalespace.no_scales >= obj.no_scales, ...
                    'The scale space given for UV flow in ComputeFeatureVectors is incompatible');
                
                
                no_flow_algos = length(obj.flow_short_types);
                
                % initialize the output feature
                photoconst = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos*obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    % get the next image in the scale space
                    im1_resized = calc_feature_vec.im1_cielab_scalespace.ss{scale_idx};
                    im2_resized = calc_feature_vec.im2_cielab_scalespace.ss{scale_idx};
                    
                    [cols rows] = meshgrid(1:size(im1_resized, 2), 1:size(im1_resized, 1));

                    % iterate over all the candidate flow algorithms
                    for algo_idx = 1:no_flow_algos
                        algo_id = strcmp(obj.flow_short_types{algo_idx}, calc_feature_vec.extra_info.calc_flows.algo_ids);
                        
                        assert(nnz(algo_id) == 1, ['Can''t find matching flow algorithm used in computation of ' class(obj)]);
                        
                        % get the next flow image in the scale space
                        uv_resized = calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}(:,:,:,algo_id);
                        
                        % compute photoconstancy
                        [ proj_im ] = obj.computePhotoConstancy(im1_resized, im2_resized, uv_resized, cols, rows);

                        % store
                        photoconst(:,:,((algo_idx-1)*obj.no_scales)+scale_idx) = imresize(proj_im, calc_feature_vec.image_sz);
                    end
                end
            else
                assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                
                assert(any(strcmp(fieldnames(calc_feature_vec), 'im1_cielab')) && ...
                    ~isempty(calc_feature_vec.im1_cielab), 'im1 l*a*b* image doesn''t exist (note that the input images should not be grayscale)');
                
                assert(any(strcmp(fieldnames(calc_feature_vec), 'im2_cielab')) && ...
                    ~isempty(calc_feature_vec.im2_cielab), 'im2 l*a*b* image doesn''t exist (note that the input images should not be grayscale)');
                
                no_flow_algos = length(obj.flow_short_types);
                
                % initialize the output feature
                photoconst = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos);
                
                [cols rows] = meshgrid(1:calc_feature_vec.image_sz(2), 1:calc_feature_vec.image_sz(1));
                
                % iterate over all the candidate flow algorithms
                for algo_idx = 1:no_flow_algos
                    algo_id = strcmp(obj.flow_short_types{algo_idx}, calc_feature_vec.extra_info.calc_flows.algo_ids);
                    
                    assert(nnz(algo_id) == 1, ['Can''t find matching flow algorithm used in computation of ' class(obj)]);
                    
                    % compute photoconstancy
                    [ proj_im ] = obj.computePhotoConstancy(calc_feature_vec.im1_cielab, calc_feature_vec.im2_cielab, ...
                        calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,:,algo_id), cols, rows);
                    
                    % store
                    photoconst(:,:,algo_idx) = proj_im;
                end
            end
            
            feature_depth = size(photoconst,3);
            
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
    
    
    methods (Access = private)
        function [ proj_im ] = computePhotoConstancy(obj, im1, im2, uv, cols, rows)
            shifts = [0 0; -1 0; -1 -1; 0 -1; 1 -1; 1 0; 1 1; 0 1; -1 1];
            
            temp = zeros([size(im2,1), size(im2,2), 2]);
            proj_im = zeros([size(im2,1), size(im2,2), size(shifts,1)]);

            flow_u = cols + uv(:,:,1);
            flow_v = rows + uv(:,:,2);
            
            lab_a = im2(:,:,2);
            lab_b = im2(:,:,3);
            
            for shift_idx = 1:size(shifts,1)
                tform = maketform('affine', [1 0; 0 1; shifts(shift_idx,1) shifts(shift_idx,2)]);
                
                lab_a_temp = imtransform(lab_a, tform, 'XData',[1 size(lab_a,2)], 'YData',[1 size(lab_a,1)], 'FillValues',NaN);
                lab_b_temp = imtransform(lab_b, tform, 'XData',[1 size(lab_b,2)], 'YData',[1 size(lab_b,1)], 'FillValues',NaN);
                
                % project the im2's a* and b* to the first according to the flow
                temp(:,:,1) = interp2(lab_a_temp, flow_u, flow_v, 'cubic');
                temp(:,:,2) = interp2(lab_b_temp, flow_u, flow_v, 'cubic');

                % compute the error in the projection
                temp = im1(:,:,[2 3]) - temp;
                proj_im(:,:,shift_idx) = sum(temp.^2, 3);
            end
            
            % take the min from all the neighborhood values and compute root for L2 norm
            proj_im = sqrt(min(proj_im, [], 3));
            proj_im(isnan(proj_im)) = PhotoConstancyFeature.NAN_VAL;
        end
    end

end

