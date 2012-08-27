classdef PbEdgeStrengthFeature < AbstractFeature
    %PBEDGESTRENGTHFEATURE the distance transfrom from the edges in the 
    %   first image (using Pb edge detector). The first argument to the
    %   constructor is the threshold which will be applied to Pb edge 
    %   detector's output to binarize the image. The constructor can also 
    %   take a size 2 vector for computing the feature on scalespace 
    %   (first value: number of scales, second value: resizing factor). If 
    %   using scalespace, ComputeFeatureVectors object passed to
    %   calcFeatures should have im1_scalespace (the scalespace structure),
    %   apart from image_sz. image_sz and im1_gray are required for 
    %   computing this feature without scalespace. If using the 
    %   scalespace, usually, the output features go up in the scalespace 
    %   (increasing gaussian std-dev) with increasing depth.
    
    
    properties
        threshold_pb;
        
        no_scales = 1;
        scale = 1;
    end
    
    
    properties (Constant)
        PRECOMPUTED_PB_FILE = 'pb.mat';
        PRECOMPUTED_SS_PB_FILE = 'pb_%s_%s.mat';
        
        FEATURE_TYPE = 'Pb Edge Strength';
        FEATURE_SHORT_TYPE = 'PB';
    end
    
    
    methods
        function obj = PbEdgeStrengthFeature( threshold, varargin )
            % threshold for Pb provided by user
            obj.threshold_pb = threshold;
            
            if nargin > 1 && isvector(varargin{1}) && length(varargin{1}) == 2
                obj.no_scales = varargin{1}(1);
                obj.scale = varargin{1}(2);
            end
        end
        
        
        function [ pbedge feature_depth compute_time ] = calcFeatures( obj, calc_feature_vec )
            
            t_start_main = tic;
            compute_time = {'totaltime', 0.0; 'pb_edge', 0.0};
            
            CalcFlows.addPaths()
            
            if obj.no_scales > 1
                assert(~isempty(fields(calc_feature_vec.im1_scalespace)), 'The scale space for im 1 has not been defined in the passed ComputeFeatureVectors');
                
                assert(calc_feature_vec.im1_scalespace.scale == obj.scale && ...
                    calc_feature_vec.im1_scalespace.no_scales >= obj.no_scales, 'The scale space given for im 1 in ComputeFeatureVectors is incompatible');
                
                % initialize the output feature
                pbedge = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), obj.no_scales);

                % load scale-space from file or compute and save to file
                [ pbedge_ss compute_time ] = obj.getSSPbFromFile(calc_feature_vec, compute_time);
                
                % iterate for multiple scales
                for scale_idx = 1:obj.no_scales
                    pbedge_temp = pbedge_ss{scale_idx};
                    
                    % compute distance transform and resize it to the original image size
                    pbedge_temp = imresize(bwdist(pbedge_temp > obj.threshold_pb), calc_feature_vec.image_sz);
                    
                    % resize it to the original image size
                    pbedge(:,:,scale_idx) = imresize(pbedge_temp, calc_feature_vec.image_sz);
                end
            else
                [ pbedge pbtheta compute_time ] = PbEdgeStrengthFeature.getPbFromFile(calc_feature_vec, compute_time);
                
                % compute distance transform and resize it to the original image size
                pbedge = imresize(double(bwdist(pbedge > obj.threshold_pb)), calc_feature_vec.image_sz);
            end
            
            feature_depth = size(pbedge,3);
            
            compute_time{1,2} = compute_time{1,2} + toc(t_start_main);
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
            
            % incorporate the threshold
            feature_no_id = round(obj.threshold_pb * feature_no_id);
        end
        
        
        function return_feature_list = returnFeatureList(obj)
        % creates a cell vector where each item contains a string of the
        % feature type (in the order the will be spit out by calcFeatures)
            
            return_feature_list = cell(obj.no_scales,1);
            
            return_feature_list{1} = {obj.FEATURE_TYPE, 'no scaling', sprintf('Threshold %.3f', obj.threshold_pb)};
            
            for scale_id = 2:obj.no_scales
                return_feature_list{scale_id} = {obj.FEATURE_TYPE, ['scale ' num2str(scale_id)], ['size ' sprintf('%.1f%%', (obj.scale^(scale_id-1))*100)], sprintf('Threshold %.3f', obj.threshold_pb)};
            end
        end
    end
    
    
    methods (Static)
        function [ pbedge pbtheta compute_time ] = getPbFromFile(calc_feature_vec, compute_time)
            % if precomputed pb exists
            if exist(fullfile(calc_feature_vec.scene_dir, PbEdgeStrengthFeature.PRECOMPUTED_PB_FILE), 'file') == 2
                load(fullfile(calc_feature_vec.scene_dir, PbEdgeStrengthFeature.PRECOMPUTED_PB_FILE));

                compute_time{2,2} = pbedge_compute_time;
                compute_time{1,2} = compute_time{1,2} + compute_time{2,2};
            else
                % compute the probability of boundary
                t_start_pb = tic;
                if size(calc_feature_vec.im1,3) == 1
                    [ pbedge, pbtheta ] = pbBGTG(im2double(calc_feature_vec.im1));
                else
                    [ pbedge, pbtheta ] = pbCGTG(im2double(calc_feature_vec.im1));
                end
                pbedge_compute_time = toc(t_start_pb);
                save(fullfile(calc_feature_vec.scene_dir, PbEdgeStrengthFeature.PRECOMPUTED_PB_FILE), 'pbedge', 'pbtheta', 'pbedge_compute_time');

                compute_time{2,2} = pbedge_compute_time;
            end
        end
    end
    
    
    methods (Access = private)    
        function [ pbedge_ss compute_time ] = getSSPbFromFile(obj, calc_feature_vec, compute_time)
            ss_pb_file = sprintf(obj.PRECOMPUTED_SS_PB_FILE, num2str(obj.no_scales), num2str(obj.scale));
            
            % if precomputed pb exists
            if exist(fullfile(calc_feature_vec.scene_dir, ss_pb_file), 'file') == 2
                load(fullfile(calc_feature_vec.scene_dir, ss_pb_file));

                compute_time{2,2} = pbedge_compute_time;
                compute_time{1,2} = compute_time{1,2} + compute_time{2,2};
            else
                % compute the probability of boundary
                pbedge_ss = {};
                [ pbedge pbtheta compute_time ] = PbEdgeStrengthFeature.getPbFromFile(calc_feature_vec, compute_time);
                pbedge_ss = [pbedge_ss; {pbedge}];
                
                t_start_pb = tic;
                
                for scale_idx = 2:obj.no_scales
                    % get the next image in the scale space
                    im_resized = calc_feature_vec.im1_scalespace.ss{scale_idx};
                    im_resized(im_resized>1) = 1.0;
                    im_resized(im_resized<0) = 0.0;
                    
                    if size(im_resized,3) == 1
                        [ pbedge ] = pbBGTG(im2double(im_resized));
                    else
                        [ pbedge ] = pbCGTG(im2double(im_resized));
                    end
                    
                    pbedge_ss = [pbedge_ss; {pbedge}];
                end
                
                pbedge_compute_time = toc(t_start_pb) + compute_time{2,2};
                save(fullfile(calc_feature_vec.scene_dir, ss_pb_file), 'pbedge_ss', 'pbedge_compute_time');

                compute_time{2,2} = pbedge_compute_time;
            end
        end
    end
end
