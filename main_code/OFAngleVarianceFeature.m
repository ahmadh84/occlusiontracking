classdef OFAngleVarianceFeature < AbstractFeature
    %PHOTOCONSTANCYFEATURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        no_scales = 1;
        scale = 1;
        nhood;
    end
    
    
    properties (Constant)
        FEATURE_TYPE = 'Angle Variance';
        FEATURE_SHORT_TYPE = 'AV';
    end
    
    
    methods
        function obj = OFAngleVarianceFeature( nhood, varargin )
            obj.nhood = nhood;
            if nargin > 1 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ angvar feature_depth ] = calcFeatures( obj, calc_feature_vec )
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
                angvar = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), no_flow_algos*obj.no_scales);

                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    
                    image_sz = size(calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx});
                    image_sz = image_sz([1 2]);
                    
                    % compute angle variance for each optical flow given
                    angvar_temp = obj.computeAngVarForEachUV( calc_feature_vec.extra_info.flow_scalespace.ss{scale_idx}, image_sz );
                    
                    % iterate over all the candidate flow algorithms
                    for feat_idx = 1:size(angvar_temp,3)
                        % store
                        angvar(:,:,((scale_idx-1)*no_flow_algos)+feat_idx) = imresize(angvar_temp(:,:,feat_idx), calc_feature_vec.image_sz);
                    end
                end
                
                % correct the ordering of features
                temp = reshape(1:no_flow_algos*obj.no_scales, [no_flow_algos obj.no_scales]);
                temp = permute(temp, [2 1]);
                angvar = angvar(:,:,temp(:));
            else
                assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');
                
                % compute angle variance for each optical flow given
                angvar = obj.computeAngVarForEachUV( calc_feature_vec.extra_info.calc_flows.uv_flows, calc_feature_vec.image_sz );
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

