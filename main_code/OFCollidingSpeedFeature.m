classdef OFCollidingSpeedFeature < AbstractFeature
    %OFCOLLIDINGSPEEDEFEATURE computes the speed of collision given the 
    %   flow vectors of diagonally opposite pixels in a  lengths in a small 
    %   window (defined by nhood) around each pixel. This class computes 
    %   summary statistics of the different collision speeds in a certain 
    %   pixel nhood. The constructor takes a cell array of Flow objects 
    %   which will be used for computing this feature. Second argument is 
    %   of the nhood (a 5x5 window [c r] = meshgrid(-2:2, -2:2); 
    %   nhood = cat(3, r(:), c(:)); 
    %   nhood_cs(nhood_cs(:,:,1)==0 & nhood_cs(:,:,2)==0,:,:) = [];).
    %   The constructor also optionally takes a size 2 vector for computing 
    %   the feature on scalespace (first value: number of scales, second 
    %   value: resizing factor). If using scalespace, ComputeFeatureVectors 
    %   object passed to calcFeatures should have 
    %   extra_info.flow_scalespace (the scalespace structure), apart from 
    %   image_sz. Note that it is the responsibility of the user to provide 
    %   enough number of scales in all scalespace structure. If not 
    %   using scalespace, extra_info.calc_flows.uv_flows is required for 
    %   computing this feature. If using the scalespace, usually, the 
    %   output features go up in the scalespace (increasing gaussian 
    %   std-dev) with increasing depth.
    %
    %   The features are first ordered by algorithms and then with max / 
    %   min / var features and then by their respective scale
    
    
    properties
        no_scales = 1;
        scale = 1;
        nhood_1;
        nhood_2;
        
        flow_ids = [];
        flow_short_types = {};
        
        FEATURES_PER_PIXEL_TYPES = {'MAX', 'MIN', 'VAR'};
    end
    
    
    properties (Transient)
        vecdir_u;
        vecdir_v;
        l2normsq;
    end
    
    
    properties (Constant)
        FEATURE_TYPE = 'Colliding Speed';
        FEATURE_SHORT_TYPE = 'CS';
    end
    
    
    methods
        function obj = OFCollidingSpeedFeature( cell_flows, nhood, varargin )
            assert(~isempty(cell_flows), ['There should be atleast 1 flow algorithm to compute ' class(obj)]);
            
            % store the flow algorithms to be used and their ids
            for algo_idx = 1:length(cell_flows)
                obj.flow_short_types{end+1} = cell_flows{algo_idx}.OF_SHORT_TYPE;
                obj.flow_ids(end+1) = cell_flows{algo_idx}.returnNoID();
            end
            
            % neighborhood window provided by user
            assert(mod(sqrt(size(nhood,1)+1), 1) == 0, 'The number of nhood pixels can be only (Z^2)-1');
            obj.nhood_1 = nhood(1:size(nhood,1)/2,:,:);
            obj.nhood_2 = nhood(end:-1:(size(nhood,1)/2)+1,:,:);
            
            % initialize the other transient info required to compute this feature
            obj = obj.extraInfo();
            
            % store any scalespace info provided by user
            if nargin > 2 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
            
            % if want to change the feature sub-types used
            if nargin > 3 && iscell(varargin{2}) && ~isempty(varargin{2})
                obj.FEATURES_PER_PIXEL_TYPES = varargin{2};
            end
        end
        
        
        function [ colspd feature_depth compute_time ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of colspd is the same as the input image, 
        %   with a depth equivalent to the number of flow algos times the
        %   features per pixel times the number of scales
        
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
                
                % get the number of flow algorithms
                no_flow_algos = length(obj.flow_short_types);
                
                % initialize the output feature
                colspd = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos*length(obj.FEATURES_PER_PIXEL_TYPES)*obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    
                    image_sz = size(calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx});
                    image_sz = image_sz([1 2]);
                    
                    % compute diagonally opposite pixel's colliding speed for each optical flow given
                    colspd_temp = obj.computeCollidingSpeedForEachUV(  calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}(:,:,:,algos_to_use), image_sz );
                    
                    % iterate over all the candidate flow algorithms
                    for feat_idx = 1:size(colspd_temp,3)
                        % resize and store
                        colspd(:,:,((feat_idx-1)*obj.no_scales)+scale_idx) = imresize(colspd_temp(:,:,feat_idx), calc_feature_vec.image_sz);
                    end
                end
            else
                assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                
                % compute diagonally opposite pixel's colliding speed for each optical flow given
                colspd = obj.computeCollidingSpeedForEachUV( calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,:,algos_to_use), calc_feature_vec.image_sz );
            end
            
            feature_depth = size(colspd,3);
            
            compute_time = toc(t_start_main);
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
            
            feature_no_id = feature_no_id + sum(obj.flow_ids);
            
            for ftr_idx = 1:length(obj.FEATURES_PER_PIXEL_TYPES)
                nos = uint8(obj.FEATURES_PER_PIXEL_TYPES{ftr_idx});
                nos = double(nos) .* ([1:length(nos)].^2);
                feature_no_id = feature_no_id + sum(nos);
            end
        end
        
        
        function return_feature_list = returnFeatureList(obj)
        % creates a cell vector where each item contains a string of the
        % feature type (in the order the will be spit out by calcFeatures)
            
            window_size = (max(obj.nhood,[],1) - min(obj.nhood,[],1))+1;
            window_size = sprintf('%dx%d', window_size(1), window_size(2));
            return_feature_list = cell(obj.no_scales * length(obj.FEATURES_PER_PIXEL_TYPES) * length(obj.flow_short_types),1);
            
            for flow_id = 1:length(obj.flow_short_types)
                for feature_id = 1:length(obj.FEATURES_PER_PIXEL_TYPES)
                    starting_no = ((flow_id-1)*obj.no_scales*length(obj.FEATURES_PER_PIXEL_TYPES)) + ((feature_id-1)*obj.no_scales);
                    
                    return_feature_list{starting_no+1} = {[obj.FEATURE_TYPE ' using ' obj.flow_short_types{flow_id}], ...
                                                          [obj.FEATURES_PER_PIXEL_TYPES{feature_id} ' feature'], ...
                                                          ['window size ' window_size], 'no scaling'};

                    for scale_id = 2:obj.no_scales
                        return_feature_list{starting_no+scale_id} = {[obj.FEATURE_TYPE ' using ' obj.flow_short_types{flow_id}], ...
                                                                     [obj.FEATURES_PER_PIXEL_TYPES{feature_id} ' feature'], ...
                                                                     ['window size ' window_size], ['scale ' num2str(scale_id)], ...
                                                                     ['size ' sprintf('%.1f%%', (obj.scale^(scale_id-1))*100)]};
                    end
                end
            end
        end
    end
    
    
    methods (Access = private)
        function [ colspd ] = computeCollidingSpeedForEachUV( obj, uv_flows, image_sz )
            
            no_flow_algos = size(uv_flows, 4);
            
            % initialize the output feature
            colspd = zeros(image_sz(1), image_sz(2), no_flow_algos*length(obj.FEATURES_PER_PIXEL_TYPES));

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

%                 all_lens = sqrt(xfl.^2 + yfl.^2);
%                 norm_len = mean(all_lens(:));
%                 xfl = xfl ./ norm_len;
%                 yfl = yfl ./ norm_len;
                
                % initialize the feature to return
                features = zeros(numel(xfl), length(obj.FEATURES_PER_PIXEL_TYPES));

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
                        [temp, remaining_idxs_rs] = sort(temp_idxs_outside, 1);
                        remaining_idxs_rs(end-s+1:end,:) = [];
                        
                        % get the l2 sq and projection line u,v matrices
                        curr_l2normsq = obj.l2normsq(remaining_idxs_rs);
                        curr_vecdir_u = obj.vecdir_u(remaining_idxs_rs);
                        curr_vecdir_v = obj.vecdir_v(remaining_idxs_rs);
                        
                        % if its not a 2D array straighten the arrays
                        if ~all(size(curr_l2normsq) == size(remaining_idxs_rs))
                            curr_l2normsq = curr_l2normsq';
                            curr_vecdir_u = curr_vecdir_u';
                            curr_vecdir_v = curr_vecdir_v';
                        end

                        % adjust temp_r and temp_c with the indxs found which are not outside the image
                        remaining_idxs_rs = sub2ind(size(temp_r_1), remaining_idxs_rs, repmat(1:size(temp_c_1,2), [size(remaining_idxs_rs,1) 1]));
                        temp_r_1 = temp_r_1(remaining_idxs_rs);
                        temp_c_1 = temp_c_1(remaining_idxs_rs);
                        temp_r_2 = temp_r_2(remaining_idxs_rs);
                        temp_c_2 = temp_c_2(remaining_idxs_rs);
                    else
                        % get the l2 sq and projection line u,v matrices
                        curr_l2normsq = repmat(obj.l2normsq, [1 size(temp_r_1, 2)]);
                        curr_vecdir_u = repmat(obj.vecdir_u, [1 size(temp_r_1, 2)]);
                        curr_vecdir_v = repmat(obj.vecdir_v, [1 size(temp_r_1, 2)]);
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
                    
                    t = curr_l2normsq ./ ((fu .* curr_vecdir_u) + (fv .* curr_vecdir_v));
                    
                    if ~isempty(t)
                        % store features accordingly
                        for feat_idx = 1:length(obj.FEATURES_PER_PIXEL_TYPES)
                            if strcmp(obj.FEATURES_PER_PIXEL_TYPES{feat_idx}, 'MAX')
                                features(curr_idxs, feat_idx) = max(t, [], 1);
                            elseif strcmp(obj.FEATURES_PER_PIXEL_TYPES{feat_idx}, 'MIN')
                                features(curr_idxs, feat_idx) = min(t, [], 1);
                            elseif strcmp(obj.FEATURES_PER_PIXEL_TYPES{feat_idx}, 'VAR')
                                features(curr_idxs, feat_idx) = var(t, 1, 1);
                            end
                        end
                    end
                end

                % store
                for feat_idx = 1:length(obj.FEATURES_PER_PIXEL_TYPES)
                    colspd(:,:,((algo_idx-1)*length(obj.FEATURES_PER_PIXEL_TYPES))+feat_idx) = reshape(features(:,feat_idx), image_sz);
                end
            end
        end
        
        
        function obj = extraInfo( obj )
            vec_dir = squeeze(obj.nhood_2 - obj.nhood_1);
            obj.vecdir_u = vec_dir(:,1);
            obj.vecdir_v = vec_dir(:,2);
            
            obj.l2normsq = sum(vec_dir.^2, 2);
        end
    end

end

