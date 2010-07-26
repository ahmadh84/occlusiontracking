classdef CalcFlows < handle
    %CALCFLOWS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant, Transient)
        ALGOS_PATH = fullfile(pwd, 'algorithms');
        GT_FLOW_FILE = '1_2.flo';
        SAVE_OBJ_NAME = 'flow_info';
    end
    
    
    properties (Transient) 
        im1;
        im2;
    end
    
    
    properties
        scene_dir;
        cell_flow_algos;
        algo_ids;
        uv_flows = [];
        uv_gt = [];
        uv_ang_err = [];
        uv_epe = [];
        result_ang = [];
        class_ang = [];
        result_epe = [];
        class_epe = [];
        epe_dist_btwfirstsec = [];
        gt_mask = [];
        algo_avg_epe = [];
        opt_avg_epe = 0.0;
    end
    
    
    properties (Access = private)
        no_algos;
        force_no_gt = 0;
        compute_refresh = 0;
    end
    
    
    methods
        function obj = CalcFlows( scene_dir, cell_flows, varargin )
            fprintf('Creating CalcFlows\n');
    
            obj.scene_dir = scene_dir;
            
            % store all flow algo objects
            obj.cell_flow_algos = cell_flows;
            obj.no_algos = length(obj.cell_flow_algos);
            
            % load images
            obj.im1 = imread(fullfile(obj.scene_dir, ComputeTrainTestData.IM1_PNG));
            obj.im2 = imread(fullfile(obj.scene_dir, ComputeTrainTestData.IM2_PNG));
            
            % if user wants to force that there is no GT
            if nargin > 2 && isscalar(varargin{1})
                obj.force_no_gt = varargin{1};
            end

            % if user wants to recompute everything and not pick up from file
            if nargin > 3 && isscalar(varargin{2})
                obj.compute_refresh = varargin{2};
            end
            
            % perform the main computation of this object
            obj.computeFlows();
        end
        
        
        function mask = loadGTMask( obj, border_gap )
        %LOADGTMASK Loads the mask to be used for finding valid regions (features 
        %   those will eventually be used for training the classifier). The 
        %   optional argument <border_gap> gives the number of pixels to ignore at
        %   the border

            mask = ~(obj.uv_gt(:,:,1)>200 | obj.uv_gt(:,:,2)>200);

            if ~exist('border_gap', 'var')
                border_gap = 0;
            end

            mask(1:border_gap,:) = 0;
            mask(:,1:border_gap) = 0;
            mask(end-border_gap+1:end,:) = 0;
            mask(:,end-border_gap+1:end) = 0;
        end
        
        
        function unique_id = getUniqueID( obj )
            unique_id = [];
            
            for algo_idx = 1:obj.no_algos
                unique_id = [unique_id obj.cell_flow_algos{algo_idx}.returnNoID()];
            end
            
            % sum them since order doesn't matter
            unique_id = sum(unique_id);
        end
    end
    
    
    methods (Access = private)
        % main function defined in m file
        computeFlows( obj );
        
        
        function bool = checkGTAvailable( obj )
        % checks if GT is available for the current image pair
            bool = (exist(fullfile(obj.scene_dir, CalcFlows.GT_FLOW_FILE), 'file') == 2) & (~obj.force_no_gt);
        end
        
        
        function bool = checkStoredObjAvailable( obj )
        % check if the stored object is available
            bool = (exist(fullfile(obj.scene_dir, obj.getMatFilename()), 'file') == 2) & (~obj.compute_refresh);
        end
        
        
        function deepCopy( obj, new_obj )
        % copies all the properties given in new_obj to the current object
            mc = metaclass(new_obj);
            for prop_idx = 1:length(mc.Properties)
                if strcmp(mc.Properties{prop_idx}.GetAccess, 'public') && strcmp(mc.Properties{prop_idx}.SetAccess, 'public')
                    prop_name = mc.Properties{prop_idx}.Name;
                    obj.(prop_name) = new_obj.(prop_name);
                end
            end
            
            % adjust no. of algos
            obj.no_algos = length(obj.cell_flow_algos);
        end
        
        
        function filename = getMatFilename( obj )
            % get the scene id
            [d sceneID] = fileparts(obj.scene_dir);
            if isempty(sceneID)
                [~, sceneID] = fileparts(d);
            end
            
            if obj.checkGTAvailable()
                filename = [sceneID '_' sprintf('%d', obj.getUniqueID()) '_gt.mat'];
            else
                filename = [sceneID '_' sprintf('%d', obj.getUniqueID()) '_nogt.mat'];
            end
        end
    end
    
    
    methods (Static)
        function addPaths()
        % add paths if not already in path
            addpath(genpath(ComputeTrainTestData.UTILS_PATH));
            addpath(genpath(CalcFlows.ALGOS_PATH));
        end
    end
end
