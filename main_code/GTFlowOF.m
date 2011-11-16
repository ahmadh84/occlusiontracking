classdef GTFlowOF < AbstractOF
    %GTFlowOF
    % Loads from file
    
    
    properties (Constant)
        OF_TYPE = 'GT Flow';
        OF_SHORT_TYPE = 'GF';
        
        OF_FILE_NAME = '1_2_orig.flo';
        
        SAVE_FILENAME = '';
        FORWARD_FLOW_VAR = '';
        BCKWARD_FLOW_VAR = '';
        COMPUTATION_TIME_VAR = '';
    end
    
    
    methods (Static)
        function [ uv_gf gf_compute_time ] = calcFlow(im1, im2, extra_info)
            % calculates the GT flow
            fprintf('--> Computing GT flow\n');
            
            assert(~extra_info.reverse, 'Can''t get reverse flow with GT flow');
            
            tic;
            
            % add paths for all the flow algorithms
            CalcFlows.addPaths();
            
            % get gt flow
            uv_gf = readFlowFile(fullfile(extra_info.dir_path, GTFlowOF.OF_FILE_NAME));
            
            gf_compute_time = toc;
        end
    end
    
end

