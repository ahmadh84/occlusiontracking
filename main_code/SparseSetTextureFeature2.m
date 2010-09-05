classdef SparseSetTextureFeature2 < AbstractFeature
    %SPARSESETTEXTUREFEATURE2 computes the difference in texture given by
    %   Sparse Set of Texture features as proposed in:
    %         Brox, T., From pixels to regions: partial differential 
    %         equations in image analysis, April 2005
    %   Given the advected position of each pixel x' = round(x +
    %   u_{12}(x)), it computes the distance suggested by brox between 
    %   T1(x) and T2(x'), where T1 is the texture feature for frame 1, and 
    %   T2 is for frame 2. The constructor takes a cell array of Flow
    %   objects which will be used for computing this feature. The ctor 
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
        
        nhood;
        flow_ids = [];
        flow_short_types = {};
    end
    
    
    properties (Constant)
        PRECOMPUTED_ST_FILE = 'sparsetextures.mat';
        
        NAN_VAL = 100;
        FEATURE_TYPE = 'Sparse Set Texture Difference';
        FEATURE_SHORT_TYPE = 'ST';
    end
    
    
    methods
        function obj = SparseSetTextureFeature2( cell_flows, nhood, varargin )
            assert(~isempty(cell_flows), ['There should be atleast 1 flow algorithm to compute ' class(obj)]);
            
            % store the flow algorithms to be used and their ids
            for algo_idx = 1:length(cell_flows)
                obj.flow_short_types{end+1} = cell_flows{algo_idx}.OF_SHORT_TYPE;
                obj.flow_ids(end+1) = cell_flows{algo_idx}.returnNoID();
            end
            
            obj.nhood = nhood;
            
            % store any scalespace info provided by user
            if nargin > 2 && isvector(varargin{2}) && length(varargin{2}) == 2
                obj.no_scales = varargin{2}(1);
                obj.scale = varargin{2}(2);
            end
        end
        
        
        function [ texturediff feature_depth ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of texturediff is the same as the input image, 
        %   with a depth equivalent to the number of flow algos times the 
        %   number of scales
        
            if obj.no_scales > 1
                error('SparseSetTextureFeature2:NoScale', 'Scale code hasn''t been implemented');
                
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
                
                % if precomputed pb exists
                if exist(fullfile(calc_feature_vec.scene_dir, obj.PRECOMPUTED_ST_FILE), 'file') == 2
                    load(fullfile(calc_feature_vec.scene_dir, obj.PRECOMPUTED_ST_FILE));
                    sparsesettext1 = T1;
                    sparsesettext2 = T2;
                else
                    % compute sparse set of texture features for both images
                    sparsesettext1 = obj.computeSparseSetTexture( calc_feature_vec.im1 );
                    sparsesettext2 = obj.computeSparseSetTexture( calc_feature_vec.im2 );
                    T1 = sparsesettext1;
                    T2 = sparsesettext2;
                    save(fullfile(calc_feature_vec.scene_dir, obj.PRECOMPUTED_ST_FILE), 'T1', 'T2');
                end
                
                [ W1 ] = obj.window_texture( sparsesettext1 );
                fprintf(1, 'Done texture window 1\n');
                [ W2 ] = obj.window_texture( sparsesettext2 );
                fprintf(1, 'Done texture window 2\n');
                
                % initialize the output feature
                texturediff = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos);
                
                [cols rows] = meshgrid(1:calc_feature_vec.image_sz(2), 1:calc_feature_vec.image_sz(1));
                
                % iterate over all the candidate flow algorithms
                for algo_idx = 1:no_flow_algos
                    algo_id = strcmp(obj.flow_short_types{algo_idx}, calc_feature_vec.extra_info.calc_flows.algo_ids);
                    
                    assert(nnz(algo_id) == 1, ['Can''t find matching flow algorithm used in computation of ' class(obj)]);
                    
                    proj_texture = zeros(size(W2));
                    
                    for text_idx = 1:size(proj_texture,4)
                        % project the second image's texture feature to the first according to the flow
                        proj_texture(:,:,1,text_idx) = interp2(W2(:,:,1,text_idx), ...
                                cols + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,1,algo_id), ...
                                rows + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,2,algo_id), 'cubic');
                        proj_texture(:,:,2,text_idx) = interp2(W2(:,:,2,text_idx), ...
                                cols + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,1,algo_id), ...
                                rows + calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,2,algo_id), 'cubic');
                    end
                    
                    % compute the distance as suggested by Brox
                    proj_texture = squeeze((W1(:,:,1,:)-proj_texture(:,:,1,:)) ./ (W1(:,:,2,:)+proj_texture(:,:,2,:)));
                    proj_texture = proj_texture.^2;
                    proj_texture = sum(proj_texture, 3) ./ size(proj_texture,3);
                    
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
            feature_no_id = feature_no_id + size(obj.nhood,1);
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
        function [ W ] = window_texture( obj, F )

            image_sz = size(F);

            % initialize the output feature
            W = zeros(image_sz(1),image_sz(2),2,image_sz(3));

            block_sz = [40 40];

            for block_r = 1:block_sz(1):image_sz(1)
                for block_c = 1:block_sz(2):image_sz(2)

                    if block_r+block_sz(1)-1 < image_sz(1)
                        sub_region_r = [block_r block_r+block_sz(1)-1];
                    else
                        sub_region_r = [block_r image_sz(1)];
                    end
                    
                    if block_c+block_sz(2)-1 < image_sz(2)
                        sub_region_c = [block_c block_c+block_sz(2)-1];
                    else
                        sub_region_c = [block_c image_sz(2)];
                    end
                    
                    [cols rows] = meshgrid(sub_region_c(1):sub_region_c(2), sub_region_r(1):sub_region_r(2));
                    nhood_rep = repmat(obj.nhood, [1 numel(rows) 1]);

                    nhood_r = nhood_rep(:,:,1) + repmat(rows(:)', [size(obj.nhood,1) 1]);
                    nhood_c = nhood_rep(:,:,2) + repmat(cols(:)', [size(obj.nhood,1) 1]);

                    % get the pixel indices which are outside
                    idxs_outside = nhood_r <= 0 | nhood_c <= 0 | nhood_r > image_sz(1) | nhood_c > image_sz(2);

                    % find how many nhood pixels are outside for each pixel
                    sums_outside = sum(idxs_outside, 1);

                    % find the unique no. of nhood pixels outside (will iterate
                    % over these no.s)
                    unique_sums = unique(sums_outside);

                    % iterate over all the candidate flow algorithms
                    for feature_idx = 1:image_sz(3)

                        % get the flow for this candidate algorithm
                        f_texture = F(:,:,feature_idx);

                        % initialize the feature to return
                        features = zeros(size(nhood_rep,2),2);

                        % iterate over all unique no. of pixels outside
                        for s = unique_sums
                            % get the pixels which fall in this category
                            curr_idxs = sums_outside==s;

                            % get rows and cols for for these valid pixels
                            temp_r = nhood_r(:,curr_idxs);
                            temp_c = nhood_c(:,curr_idxs);

                            % throw away indices which fall outside (fix temp_r
                            % and temp_c)
                            if s ~= 0
                                % select the pixel (nhoods) which have this no. of nhood pixels outside
                                temp_idxs_outside = idxs_outside(:,curr_idxs);

                                % sort and delete the nhood pixels which are outside
                                [temp, remaining_idxs_rs] = sort(temp_idxs_outside, 1);
                                remaining_idxs_rs(end-s+1:end,:) = [];

                                % adjust temp_r and temp_c with the indxs found which are not outside the image
                                remaining_idxs_rs = sub2ind(size(temp_r), remaining_idxs_rs, repmat(1:size(temp_c,2), [size(remaining_idxs_rs,1) 1]));
                                temp_r = temp_r(remaining_idxs_rs);
                                temp_c = temp_c(remaining_idxs_rs);
                            end

                            % get the indxs for each pixel nhood
                            temp_indxs = sub2ind(size(f_texture), temp_r, temp_c);
                            temp_f = f_texture(temp_indxs);

                            % angle variance
                            avg_texture = mean(temp_f, 1);
                            std_texture = std(temp_f, 0, 1);
                            features(curr_idxs,1) = avg_texture;
                            features(curr_idxs,2) = std_texture;
                        end

                        % store
                        W(sub_region_r(1):sub_region_r(2),sub_region_c(1):sub_region_c(2),1,feature_idx) = reshape(features(:,1), size(rows,1), size(rows,2));
                        W(sub_region_r(1):sub_region_r(2),sub_region_c(1):sub_region_c(2),2,feature_idx) = reshape(features(:,2), size(rows,1), size(rows,2));
                    end
                end
            end
        end
        
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

