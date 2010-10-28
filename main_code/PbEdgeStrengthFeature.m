classdef PbEdgeStrengthFeature < AbstractFeature
    %PBEDGESTRENGTHFEATURE Summary of this class goes here
    %   Detailed explanation goes here
    
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
