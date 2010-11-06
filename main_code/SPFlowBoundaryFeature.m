classdef SPFlowBoundaryFeature < AbstractFeature
    %SPFLOWBOUNDARYFEATURE the distance transfrom from the edges in the first 
    %   image (using canny edge detector). The constructor either takes 
    %   nothing or size 2 vector for computing the feature on scalespace 
    %   (first value: number of scales, second value: resizing factor). If 
    %   using scalespace, ComputeFeatureVectors object passed to
    %   calcFeatures should have im1_scalespace (the scalespace structure),
    %   apart from image_sz. image_sz and im1_gray are required for 
    %   computing this feature without scalespace. . If using the 
    %   scalespace, usually, the output features go up in the scalespace 
    %   (increasing gaussian std-dev) with increasing depth.
    
    
    properties
        % Number of superpixels coarse/fine.
        N_sp = 50;
        N_sp2 = 500;
        % Number of eigenvectors.
        N_ev = 40;
        
        % standard deviation to smooth by at end
        std_smooth = 5;
        
%         no_scales = 1;
%         scale = 1;
        
        flow_ids = [];
        flow_short_types = {};
    end
    
    
    properties (Constant)
        PRECOMPUTED_SP_FILE = 'sp_%d.mat';
        
        FEATURE_TYPE = 'SP Flow Boundary';
        FEATURE_SHORT_TYPE = 'SP';
    end
    
    
    methods
        function obj = SPFlowBoundaryFeature( cell_flows, varargin )
            assert(~isempty(cell_flows), ['There should be atleast 1 flow algorithm to compute ' class(obj)]);
            
            % store the flow algorithms to be used and their ids
            for algo_idx = 1:length(cell_flows)
                obj.flow_short_types{end+1} = cell_flows{algo_idx}.OF_SHORT_TYPE;
                obj.flow_ids(end+1) = cell_flows{algo_idx}.returnNoID();
            end
            
            if nargin > 1 && isscalar(varargin{1})
                obj.N_sp = varargin{1};
            end
            
            if nargin > 2 && isscalar(varargin{2})
                obj.N_sp2 = varargin{2};
            end
            
            if nargin > 3 && isscalar(varargin{3})
                obj.N_ev = varargin{3};
            end
            
            if nargin > 4 && isscalar(varargin{4})
                obj.std_smooth = varargin{4};
            end
        end
        
        
        function [ flowdisct feature_depth compute_time ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of dist is the same as the input image, with a
        %   depth equivalent to the number of scales
        
            t_start_main = tic;
            compute_time = {'totaltime', 0.0; 'pb_edge', 0.0; 'pb_sp', 0.0};
            
            % find which algos to use
            algos_to_use = cellfun(@(x) find(strcmp(x, calc_feature_vec.extra_info.calc_flows.algo_ids)), obj.flow_short_types);

            assert(length(algos_to_use)==length(obj.flow_short_types), ['Can''t find matching flow algorithm(s) used in computation of ' class(obj)]);

            % compute the superpixels
            [ Sp, Sp2, compute_time ] = obj.getSPFlowBoundary(calc_feature_vec, compute_time);
            
            % get flow discontinuities
            [ flowdisct ] = getSPFlowDiscontinuities(obj, calc_feature_vec, algos_to_use, Sp, Sp2);
            
            feature_depth = size(flowdisct,3);
            
            compute_time{1,2} = compute_time{1,2} + toc(t_start_main);
        end
        
        
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = returnNoID@AbstractFeature(obj);
            
            temp = obj.N_sp + obj.N_sp2;
            % get first 2 decimal digits
            temp = mod(temp, 10000) + obj.N_ev.^2;
            feature_no_id = (nos*100) + temp + sum(obj.flow_ids) + obj.std_smooth;
        end
        
        
        function return_feature_list = returnFeatureList(obj)
        % creates a cell vector where each item contains a string of the
        % feature type (in the order the will be spit out by calcFeatures)
            
            return_feature_list = cell(obj.no_scales,1);
            
            return_feature_list{1} = {obj.FEATURE_TYPE, ['N_sp ' num2str(obj.N_sp)], ['N_sp2 ' num2str(obj.N_sp2)], ['N_ev ' num2str(obj.N_ev)]};
        end
    end
    
    
    methods (Access = private)
        function [ Sp, Sp2, compute_time ] = getSPFlowBoundary(obj, calc_feature_vec, compute_time)
            N = size(calc_feature_vec.im1,1);
            M = size(calc_feature_vec.im1,2);

            % ncut parameters for superpixel computation
            diag_length = sqrt(N*N + M*M);
            par = imncut_sp;
            par.int = 0;
            par.pb_ic = 1;
            par.sig_pb_ic = 0.05;
            par.sig_p = ceil(diag_length/50);
            par.verbose = 0;
            par.nb_r = ceil(diag_length/60);
            par.rep = -0.005;  % stability?  or proximity?
            par.sample_rate = 0.2;
            par.nv = obj.N_ev;
            par.sp = obj.N_sp;

            % Intervening contour using mfm-pb
            [ pbedge pbtheta compute_time ] = PbEdgeStrengthFeature.getPbFromFile(calc_feature_vec, compute_time);
            
            
            precomputed_filepath = fullfile(calc_feature_vec.scene_dir, sprintf(SPFlowBoundaryFeature.PRECOMPUTED_SP_FILE, obj.returnNoID()));
            
            % if precomputed pb exists
            if exist(precomputed_filepath, 'file') == 2
                load(precomputed_filepath);

                compute_time{3,2} = sp_compute_time;
                compute_time{1,2} = compute_time{1,2} + compute_time{3,2};
            else
                % compute the superpixels
                t_start_sp = tic;
                
                [emag,ephase] = pbWrapper(calc_feature_vec.im1, pbedge, pbtheta, par.pb_timing);

                emag = pbThicken(emag);
                par.pb_emag = emag;
                par.pb_ephase = ephase;
                clear emag ephase;
                
                fprintf(1, 'Ncutting...\n');
                [Sp,Seg] = imncut_sp(calc_feature_vec.im1, par);
                
                fprintf(1, 'Fine scale superpixel computation...\n');
                Sp2 = clusterLocations(Sp,ceil(N*M/obj.N_sp2));
                
                sp_compute_time = toc(t_start_sp);
                save(precomputed_filepath, 'Sp2', 'Sp', 'sp_compute_time');

                compute_time{3,2} = sp_compute_time;
            end
        end
        
        
        function [ feature ] = getSPFlowDiscontinuities(obj, calc_feature_vec, algos_to_use, Sp, Sp2)
            % get the candidate flow algorithms
            uv_flow = calc_feature_vec.extra_info.calc_flows.uv_flows(:,:,:,algos_to_use);

            % get the median flow (make 2 dim matrix - quicker! :s)
            sz_temp = size(uv_flow);
            uv_flow = reshape(uv_flow, [sz_temp(1)*sz_temp(2)*sz_temp(3) sz_temp(4)]);
            median_flow = median(uv_flow, 2);
            median_flow = reshape(median_flow, [sz_temp(1) sz_temp(2) sz_temp(3)]);

            % loop through superpixels and associate median flow to each superpixel
            fx = median_flow(:,:,1);
            fy = median_flow(:,:,2);
            S = Sp; % small number of superpixels
            %S = Sp2; % large number of superpixels
            for i=1:max(S(:))
                fx(S==i) = median(fx(S==i));
                fy(S==i) = median(fy(S==i));
            end
            avF = median_flow;
            avF(:,:,1) = fx;
            avF(:,:,2) = fy;

            % original gradient magnitude
%             figure;imagesc(flowToColor(median_flow));colorbar
            [xdx, xdy] = gradient(median_flow(:,:,1));
            [ydx, ydy] = gradient(median_flow(:,:,2));
            gm = sqrt(xdx.^2+xdy.^2+ydx.^2+ydy.^2);
%             figure;imagesc(gm./max(gm(:)));colorbar

            % sp flow
%             figure;imagesc(flowToColor(avF));colorbar
            [xdx, xdy] = gradient(avF(:,:,1));
            [ydx, ydy] = gradient(avF(:,:,2));
            gmSP = sqrt(xdx.^2+xdy.^2+ydx.^2+ydy.^2);
%             figure;imagesc(gmSP./max(gmSP(:)));colorbar

            % gauss blur
            G = fspecial('gaussian', (obj.std_smooth*3*2)+1, obj.std_smooth);
            feature = imfilter(gmSP./max(gmSP(:)),G,'replicate');
%             figure;imagesc(feature./max(feature(:)));colorbar
        end
    end
end
