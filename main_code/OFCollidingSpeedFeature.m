classdef OFCollidingSpeedFeature < AbstractFeature
    %PHOTOCONSTANCYFEATURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        no_scales = 1;
        scale = 1;
        nhood_1;
        nhood_2;
        pinv_dist_u;
        pinv_dist_v;
        proj_a1;
        proj_a2;
        proj_a3;
        proj_a4;
    end
    
    
    properties (Constant)
        FEATURE_TYPE = 'Colliding Speed';
        FEATURE_SHORT_TYPE = 'CS';
        
        FEATURES_PER_PIXEL = 3;
    end
    
    
    methods
        function obj = OFCollidingSpeedFeature( nhood, varargin )
            assert(mod(sqrt(size(nhood,1)+1), 1) == 0, 'The number of nhood pixels can be only (Z^2)-1');
            obj.nhood_1 = nhood(1:size(nhood,1)/2,:,:);
            obj.nhood_2 = nhood(end:-1:(size(nhood,1)/2)+1,:,:);
            
            obj = obj.extraInfo();
            
            if nargin > 1 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ colspd feature_depth ] = calcFeatures( obj, calc_feature_vec )
            if obj.no_scales > 1
                assert(isfield(calc_feature_vec.extra_info, 'flow_scalespace') && ...
                    ~isempty(fields(calc_feature_vec.extra_info.flow_scalespace)), ...
                    'The scale space for UV flow has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.extra_info.flow_scalespace.scale == obj.scale && ...
                    calc_feature_vec.extra_info.flow_scalespace.no_scales >= obj.no_scales, ...
                    'The scale space given for UV flow in ComputeFeatureVectors is incompatible');
                
                % get the number of flow algorithms
                no_flow_algos = size(calc_feature_vec.extra_info.flow_scalespace.ss{1}, 4);
                
                % initialize the output feature
                colspd = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos*obj.FEATURES_PER_PIXEL*obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    
                    image_sz = size(calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx});
                    image_sz = image_sz([1 2]);
                    
                    % compute diagonally opposite pixel's colliding speed for each optical flow given
                    colspd_temp = obj.computeCollidingSpeedForEachUV(  calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}, image_sz );
                    
                    % iterate over all the candidate flow algorithms
                    for feat_idx = 1:size(colspd_temp,3)
                        % store
                        colspd(:,:,((scale_idx-1)*no_flow_algos*obj.FEATURES_PER_PIXEL)+feat_idx) = imresize(colspd_temp(:,:,feat_idx), calc_feature_vec.image_sz);
                    end
                end
                
                % correct the ordering of features (order by (1) algos, (2)
                % features, (3) scales)
                temp = reshape(1:no_flow_algos*obj.FEATURES_PER_PIXEL*obj.no_scales, [obj.FEATURES_PER_PIXEL no_flow_algos obj.no_scales]);
                temp = permute(temp, [3 1 2]);
                colspd = colspd(:,:,temp(:));
            else
                assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                
                % compute diagonally opposite pixel's colliding speed for each optical flow given
                colspd = obj.computeCollidingSpeedForEachUV( calc_feature_vec.extra_info.calc_flows.uv_flows, calc_feature_vec.image_sz );
            end
            
            feature_depth = size(colspd,3);
        end
            
        
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = returnNoID@AbstractFeature(obj);
            
            temp = (obj.no_scales^obj.scale)*numel(obj.nhood_1);
            % get first 2 decimal digits
            temp = mod(round(temp*100), 100);
            feature_no_id = (nos*100) + temp;
        end    
    end
    
    
    methods (Access = private)
        function [ colspd ] = computeCollidingSpeedForEachUV( obj, uv_flows, image_sz )
            
            no_flow_algos = size(uv_flows, 4);
            
            % initialize the output feature
            colspd = zeros(image_sz(1), image_sz(2), no_flow_algos*obj.FEATURES_PER_PIXEL);

            % get the nhood r and c's (each col given a neighborhood 
            %  around a pixel - nhood_r is row ind, nhood_c is col ind)
            [cols rows] = meshgrid(1:image_sz(2), 1:image_sz(1));
            nhood_rep_1 = repmat(obj.nhood_1, [1 numel(rows) 1]);
            nhood_rep_2 = repmat(obj.nhood_2, [1 numel(rows) 1]);
            nhood_r_1 = nhood_rep_1(:,:,1) + repmat(rows(:)', [size(obj.nhood_1,1) 1]);
            nhood_c_1 = nhood_rep_1(:,:,2) + repmat(cols(:)', [size(obj.nhood_1,1) 1]);
            nhood_r_2 = nhood_rep_2(:,:,1) + repmat(rows(:)', [size(obj.nhood_2,1) 1]);
            nhood_c_2 = nhood_rep_2(:,:,2) + repmat(cols(:)', [size(obj.nhood_2,1) 1]);

            % get the pixel indices which are outside
            idxs_outside = nhood_r_1 <= 0 | nhood_c_1 <= 0 | nhood_r_1 > image_sz(1) | nhood_c_1 > image_sz(2) ...
                | nhood_r_2 <= 0 | nhood_c_2 <= 0 | nhood_r_2 > image_sz(1) | nhood_c_2 > image_sz(2);

            % find how many nhood pixels are outside for each pixel
            sums_outside = sum(idxs_outside, 1);

            % find the unique no. of nhood pixels outside (will iterate
            % over these no.s)
            unique_sums = unique(sums_outside);

            % iterate over all the candidate flow algorithms
            for algo_idx = 1:no_flow_algos

                % get the flow for this candidate algorithm
                xfl = uv_flows(:,:,1,algo_idx);
                yfl = uv_flows(:,:,2,algo_idx);

                % initialize the feature to return
                features = zeros(numel(xfl), obj.FEATURES_PER_PIXEL);

                % iterate over all unique no. of pixels outside
                for s = unique_sums
                    % get the pixels which fall in this category
                    curr_idxs = sums_outside==s;

                    % get rows and cols for for these valid pixels
                    temp_r_1 = nhood_r_1(:,curr_idxs);
                    temp_c_1 = nhood_c_1(:,curr_idxs);
                    temp_r_2 = nhood_r_2(:,curr_idxs);
                    temp_c_2 = nhood_c_2(:,curr_idxs);
                    
                    
                    % throw away indices which fall outside (fix temp_r
                    % and temp_c)
                    if s ~= 0
                        % select the pixel (nhoods) which have this no. of nhood pixels outside
                        temp_idxs_outside = idxs_outside(:,curr_idxs);

                        % sort and delete the nhood pixels which are outside
                        [~, remaining_idxs_rs] = sort(temp_idxs_outside, 1);
                        remaining_idxs_rs(end-s+1:end,:) = [];
                        
                        % get the projection matrix A
                        curr_proj_a1 = obj.proj_a1(remaining_idxs_rs);
                        curr_proj_a2 = obj.proj_a2(remaining_idxs_rs);
                        curr_proj_a3 = obj.proj_a3(remaining_idxs_rs);
                        curr_proj_a4 = obj.proj_a4(remaining_idxs_rs);
                        
                        % get the pseudoinv distance
                        curr_pinv_d_u = obj.pinv_dist_u(remaining_idxs_rs);
                        curr_pinv_d_v = obj.pinv_dist_v(remaining_idxs_rs);
                        
                        % if its not a 2D array straighten the arrays
                        if ~all(size(curr_proj_a1) == size(remaining_idxs_rs))
                            curr_proj_a1 = curr_proj_a1';
                            curr_proj_a2 = curr_proj_a2';
                            curr_proj_a3 = curr_proj_a3';
                            curr_proj_a4 = curr_proj_a4';
                            
                            curr_pinv_d_u = curr_pinv_d_u';
                            curr_pinv_d_v = curr_pinv_d_v';
                        end

                        % adjust temp_r and temp_c with the indxs found which are not outside the image
                        remaining_idxs_rs = sub2ind(size(temp_r_1), remaining_idxs_rs, repmat(1:size(temp_c_1,2), [size(remaining_idxs_rs,1) 1]));
                        temp_r_1 = temp_r_1(remaining_idxs_rs);
                        temp_c_1 = temp_c_1(remaining_idxs_rs);
                        temp_r_2 = temp_r_2(remaining_idxs_rs);
                        temp_c_2 = temp_c_2(remaining_idxs_rs);
                    else
                        % get the projection matrix A
                        curr_proj_a1 = repmat(obj.proj_a1, [1 size(temp_r_1, 2)]);
                        curr_proj_a2 = repmat(obj.proj_a2, [1 size(temp_r_1, 2)]);
                        curr_proj_a3 = repmat(obj.proj_a3, [1 size(temp_r_1, 2)]);
                        curr_proj_a4 = repmat(obj.proj_a4, [1 size(temp_r_1, 2)]);
                        
                        % get the pseudoinv distance
                        curr_pinv_d_u = repmat(obj.pinv_dist_u, [1 size(temp_r_1, 2)]);
                        curr_pinv_d_v = repmat(obj.pinv_dist_v, [1 size(temp_r_1, 2)]);
                    end

                    % get the indxs for each pixel nhood
                    temp_indxs = sub2ind(size(xfl), temp_r_1, temp_c_1);
                    temp_u_1 = xfl(temp_indxs);
                    temp_v_1 = yfl(temp_indxs);
                    temp_indxs = sub2ind(size(xfl), temp_r_2, temp_c_2);
                    temp_u_2 = xfl(temp_indxs);
                    temp_v_2 = yfl(temp_indxs);


                    %%% The main feature computation
                    fu = temp_u_1 - temp_u_2;
                    fv = temp_v_1 - temp_v_2;
                    
                    curr_proj_a1 = curr_proj_a1.*fu + curr_proj_a3.*fv;
                    curr_proj_a2 = curr_proj_a2.*fu + curr_proj_a4.*fv;
                    
                    t = curr_pinv_d_u.*curr_proj_a1 + curr_pinv_d_v.*curr_proj_a2;
                    
                    if ~isempty(t)
                        features(curr_idxs, 1) = max(t, [], 1);
                        features(curr_idxs, 2) = min(t, [], 1);
                        features(curr_idxs, 3) = var(t, 1, 1);
                    end
                end

                % store
                for feat_idx = 1:obj.FEATURES_PER_PIXEL
                    colspd(:,:,((algo_idx-1)*obj.FEATURES_PER_PIXEL)+feat_idx) = reshape(features(:,feat_idx), image_sz);
                end
            end
        end
        
        
        function obj = extraInfo( obj )
            dist = squeeze(obj.nhood_2 - obj.nhood_1);
            
            n = sum(dist.^2, 2);
            
            obj.proj_a1 = ( dist(:,1).^2 ) ./ n;
            obj.proj_a2 = ( dist(:,1).*dist(:,2) ) ./ n;
            obj.proj_a3 = obj.proj_a2;
            obj.proj_a4 = ( dist(:,2).^2 ) ./ n;
            
            obj.pinv_dist_u = 1./n .* dist(:,1);
            obj.pinv_dist_v = 1./n .* dist(:,2);
        end
    end

end

