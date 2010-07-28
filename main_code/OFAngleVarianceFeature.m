classdef OFAngleVarianceFeature < AbstractFeature
    %OFANGLEVARIANCEFEATURE computes the variance of the flow vector angles 
    %   in a small window (defined by nhood) around each pixel. The 
    %   constructor takes a cell array of Flow objects which will be used 
    %   for computing this feature. Second argument is of the nhood (a 5x5 
    %   window [c r] = meshgrid(-2:2, -2:2); nhood = cat(3, r(:), c(:));).
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
        FEATURE_TYPE = 'Angle Variance';
        FEATURE_SHORT_TYPE = 'AV';
    end
    
    
    methods
        function obj = OFAngleVarianceFeature( cell_flows, nhood, varargin )
            assert(~isempty(cell_flows), ['There should be atleast 1 flow algorithm to compute ' class(obj)]);
            
            % store the flow algorithms to be used and their ids
            for algo_idx = 1:length(cell_flows)
                obj.flow_short_types{end+1} = cell_flows{algo_idx}.OF_SHORT_TYPE;
                obj.flow_ids(end+1) = cell_flows{algo_idx}.returnNoID();
            end
            
            % neighborhood window provided by user
            obj.nhood = nhood;
            
            % store any scalespace info provided by user
            if nargin > 2 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ angvar feature_depth ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of angvar is the same as the input image, 
        %   with a depth equivalent to the number of flow algos times the 
        %   number of scales
        
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
                angvar = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos*obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    
                    image_sz = size(calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx});
                    image_sz = image_sz([1 2]);
                    
                    % compute angle variance for each optical flow given
                    angvar_temp = obj.computeAngVarForEachUV( calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}(:,:,:,algos_to_use), image_sz );
                    
                    % iterate over all the candidate flow algorithms
                    for feat_idx = 1:size(angvar_temp,3)
                        % resize and store
                        angvar(:,:,((feat_idx-1)*obj.no_scales)+scale_idx) = imresize(angvar_temp(:,:,feat_idx), calc_feature_vec.image_sz);
                    end
                end
            else
                assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                
                % compute angle variance for each optical flow given
                angvar = obj.computeAngVarForEachUV( calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,:,algos_to_use), calc_feature_vec.image_sz );
            end
            
            feature_depth = size(angvar,3);
        end
            
        
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = returnNoID@AbstractFeature(obj);
            
            temp = (obj.no_scales^obj.scale)*numel(obj.nhood);
            % get first 2 decimal digits
            temp = mod(round(temp*100), 100);
            feature_no_id = (nos*100) + temp;
            
            feature_no_id = feature_no_id + sum(obj.flow_ids);
        end    
    end
    
    
    methods (Access = private)
        function [ angvar ] = computeAngVarForEachUV( obj, uv_flows, image_sz )
            
            no_flow_algos = size(uv_flows, 4);

            % initialize the output feature
            angvar = zeros(image_sz(1), image_sz(2), no_flow_algos);

            % get the nhood r and c's (each col given a neighborhood 
            %  around a pixel - nhood_r is row ind, nhood_c is col ind)
            [cols rows] = meshgrid(1:image_sz(2), 1:image_sz(1));
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
            for algo_idx = 1:no_flow_algos

                % get the flow for this candidate algorithm
                xfl = uv_flows(:,:,1,algo_idx);
                yfl = uv_flows(:,:,2,algo_idx);

                % initialize the feature to return
                features = zeros(numel(xfl),1);

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
                        [~, remaining_idxs_rs] = sort(temp_idxs_outside, 1);
                        remaining_idxs_rs(end-s+1:end,:) = [];

                        % adjust temp_r and temp_c with the indxs found which are not outside the image
                        remaining_idxs_rs = sub2ind(size(temp_r), remaining_idxs_rs, repmat(1:size(temp_c,2), [size(remaining_idxs_rs,1) 1]));
                        temp_r = temp_r(remaining_idxs_rs);
                        temp_c = temp_c(remaining_idxs_rs);
                    end

                    % get the indxs for each pixel nhood
                    temp_indxs = sub2ind(size(xfl), temp_r, temp_c);
                    temp_u = xfl(temp_indxs);
                    temp_v = yfl(temp_indxs);


                    %%% The main feature computation
                    ang = atan(temp_v ./ temp_u);
                    avg_ang = anglesUnwrappedMean( ang, 'rad', 1 );
                    avg_ang = repmat(avg_ang, [size(ang,1) 1]);
                    avg_ang = anglesUnwrappedDiff(ang, avg_ang);

                    % angle variance
                    avg_ang = mean(avg_ang.^2, 1);
                    features(curr_idxs,1) = avg_ang;
                end

                % store
                angvar(:,:,algo_idx) = reshape(features, image_sz);
            end
        end
    end

end

