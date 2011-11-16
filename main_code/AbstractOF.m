classdef AbstractOF
    %ABSTRACTOF Abstract class for calculating flow
    
    properties (Abstract, Constant)
        OF_TYPE;
        OF_SHORT_TYPE;
        
        SAVE_FILENAME;
        FORWARD_FLOW_VAR;
        BCKWARD_FLOW_VAR;
        COMPUTATION_TIME_VAR;
    end
    
    
    methods (Abstract, Static)
        [ uv_of compute_time ] = calcFlow(im1, im2, extra_info);
    end
    
    
    methods (Static)
        function [ success uv_flow uv_compute_time all_loaded_info ] = loadFromFile(class_ref, extra_info)
        % this function tries to load the flow from file
            
            success = 0;
            uv_flow = [];
            uv_compute_time = 0;
            
            if ~isempty(class_ref.SAVE_FILENAME) && exist(fullfile(extra_info.scene_dir, class_ref.SAVE_FILENAME), 'file') == 2
                warning('CalcFlows:computeFlows', 'loading directly from file');
                all_loaded_info = load(fullfile(extra_info.scene_dir, class_ref.SAVE_FILENAME));
                
                if isfield(extra_info,'reverse') && ~extra_info.reverse
                    uv_flow = all_loaded_info.(class_ref.FORWARD_FLOW_VAR);
                else
                    % if we need to compute the flow in reverse
                    uv_flow = all_loaded_info.(class_ref.BCKWARD_FLOW_VAR);
                end

                uv_compute_time = all_loaded_info.(class_ref.COMPUTATION_TIME_VAR);
                uv_compute_time = uv_compute_time / 2;
                
                success = 1;
            end
        end
    end
    
    
    methods
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = uint8(obj.OF_SHORT_TYPE);
            nos = double(nos) .* ([1:length(nos)].^2);
            feature_no_id = sum(nos);
        end
    end
    
end

