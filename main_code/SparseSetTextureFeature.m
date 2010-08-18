classdef SparseSetTextureFeature < AbstractFeature
    %SPARSESETTEXTUREFEATURE computes the difference in texture given by
    %   Sparse Set of Texture features as proposed in:
    %         Brox, T., From pixels to regions: partial differential 
    %         equations in image analysis, April 2005
    %   Given the advected position of each pixel x' = round(x +
    %   u_{12}(x)), it computes the mahalanobis distance between T1(x) and
    %   T2(x'), where T1 is the texture feature for frame 1, and T2 is for
    %   frame 2. The constructor takes a cell array of Flow objects which 
    %   will be used for computing this feature. The constructor also 
    %   optionally takes a size 2 vector for computing the feature on 
    %   scalespace (first value: number of scales, second value: resizing 
    %   factor). If using scalespace, ComputeFeatureVectors object passed 
    %   to calcFeatures should have im1_scalespace, im2_scalespace and 
    %   extra_info.flow_scalespace (the scalespace structures), apart from 
    %   image_sz. Note that it is the responsibility of the user to provide 
    %   enough number of scales in all 3 scalespace structures. If not 
    %   using scalespace im1_gray, im2_gray and 
    %   extra_info.calc_flows.uv_flows are required for computing this 
    %   feature. If using the scalespace, usually, the output features go 
    %   up in the scalespace (increasing gaussian std-dev) with increasing 
    %   depth.
    %
    %   The features are first ordered by flow algorithms and then with 
    %   their respective scale
    
    
    properties
        no_scales = 1;
        scale = 1;
        
        flow_ids = [];
        flow_short_types = {};
    end
    
    
    properties (Constant)
        NAN_VAL = 100;
        FEATURE_TYPE = 'Sparse Set Texture Difference';
        FEATURE_SHORT_TYPE = 'ST';
    end
    
    
    methods
        function obj = SparseSetTextureFeature( cell_flows, varargin )
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
        
        
        function [ texturediff feature_depth ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of texturediff is the same as the input image, 
        %   with a depth equivalent to the number of flow algos times the 
        %   number of scales
        
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
                
                
                no_flow_algos = length(obj.flow_short_types);
                
                % initialize the output feature
                texturediff = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos*obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    % get the next image in the scale space
                    im1_resized = calc_feature_vec.im1_scalespace.ss{scale_idx};
                    im2_resized = calc_feature_vec.im2_scalespace.ss{scale_idx};

                    % compute sparse set of texture features for both images
                    sparsesettext1 = obj.computeSparseSetTexture( im1_resized );
                    sparsesettext2 = obj.computeSparseSetTexture( im2_resized );

                    [cols rows] = meshgrid(1:size(im1_resized, 2), 1:size(im1_resized, 1));

                    % iterate over all the candidate flow algorithms
                    for algo_idx = 1:no_flow_algos
                        algo_id = strcmp(obj.flow_short_types{algo_idx}, calc_feature_vec.extra_info.calc_flows.algo_ids);
                        
                        assert(nnz(algo_id) == 1, ['Can''t find matching flow algorithm used in computation of ' class(obj)]);
                    
                        % get the next flow image in the scale space
                        uv_resized = calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}(:,:,:,algo_id);    
                        
                        proj_texture = zeros(size(sparsesettext2));
                        texture_var = zeros(1,1,size(sparsesettext2,3));

                        for text_idx = 1:size(proj_texture,3)
                            % project the second image's texture feature to the first according to the flow
                            proj_texture(:,:,text_idx) = interp2(sparsesettext2(:,:,text_idx), ...
                                    cols + uv_resized(:,:,1), ...
                                    rows + uv_resized(:,:,2), 'cubic');

                            % compute variance of each feature
                            temp = [sparsesettext1(:,:,text_idx) sparsesettext2(:,:,text_idx)];
                            texture_var(text_idx) = var(temp(:));
                        end

                        texture_var = repmat(texture_var, [size(im1_resized,1) size(im1_resized,2)]);

                        % compute the Mahalanobis distance for the texture features
                        proj_texture = (sparsesettext1 - proj_texture).^2;
                        proj_texture = sqrt(sum(proj_texture ./ texture_var, 3));

                        proj_texture(isnan(proj_texture)) = SparseSetTextureFeature.NAN_VAL;

                        % store
                        texturediff(:,:,((algo_idx-1)*obj.no_scales)+scale_idx) = imresize(proj_texture, calc_feature_vec.image_sz);
                    end
                end
            else
                assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                
                no_flow_algos = length(obj.flow_short_types);
                
                % compute sparse set of texture features for both images
                sparsesettext1 = obj.computeSparseSetTexture( calc_feature_vec.im1 );
                sparsesettext2 = obj.computeSparseSetTexture( calc_feature_vec.im2 );
                
                % initialize the output feature
                texturediff = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos);
                
                [cols rows] = meshgrid(1:calc_feature_vec.image_sz(2), 1:calc_feature_vec.image_sz(1));
                
                % iterate over all the candidate flow algorithms
                for algo_idx = 1:no_flow_algos
                    algo_id = strcmp(obj.flow_short_types{algo_idx}, calc_feature_vec.extra_info.calc_flows.algo_ids);
                    
                    assert(nnz(algo_id) == 1, ['Can''t find matching flow algorithm used in computation of ' class(obj)]);
                    
                    proj_texture = zeros(size(sparsesettext2));
                    texture_var = zeros(1,1,size(sparsesettext2,3));
                    
                    for text_idx = 1:size(proj_texture,3)
                        % project the second image's texture feature to the first according to the flow
                        proj_texture(:,:,text_idx) = interp2(sparsesettext2(:,:,text_idx), ...
                                cols + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,1,algo_id), ...
                                rows + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,2,algo_id), 'cubic');
                        
                        % compute variance of each feature
                        temp = [sparsesettext1(:,:,text_idx) sparsesettext2(:,:,text_idx)];
                        texture_var(text_idx) = var(temp(:));
                    end
                    
                    texture_var = repmat(texture_var, calc_feature_vec.image_sz);
                    
                    % compute the Mahalanobis distance for the texture features
                    proj_texture = (sparsesettext1 - proj_texture).^2;
                    proj_texture = sqrt(sum(proj_texture ./ texture_var, 3));
                    
                    proj_texture(isnan(proj_texture)) = SparseSetTextureFeature.NAN_VAL;
                    
                    % store
                    texturediff(:,:,algo_idx) = proj_texture;
                end
            end
            
            feature_depth = size(texturediff,3);
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
        function sparsesettext = computeSparseSetTexture( obj, im )
            if size(im,3) == 3
                F = discriminative_texture_feature(double(im),6,[],1);
            else
                F = discriminative_texture_feature(double(im),6,[],0);
            end
            
            sparsesettext = reshape(F', [size(im,1),size(im,2),size(F,1)]);
        end
    end

end

