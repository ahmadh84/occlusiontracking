classdef HornSchunckOF < AbstractOF
    %HORNSCHUNCKOF 
    % get output for "Determining optical flow" (B. Horn, B. G. Schunck, 
    %   Artificial Intelligence, 1981)

    properties (Constant)
        OF_TYPE = 'Horn-Schunck';
        OF_SHORT_TYPE = 'HS';
        
        OF_DIRECTORY_NAME = 'Horn & Schunck';
        
        SAVE_FILENAME = '';
        FORWARD_FLOW_VAR = '';
        BCKWARD_FLOW_VAR = '';
        COMPUTATION_TIME_VAR = '';
    end
    
    
    methods (Static)
        function [ uv_hs hs_compute_time ] = calcFlow(im1, im2, extra_info)
            % calculates the Horn Schunk flow
            fprintf('--> Computing Horn Schunk flow\n');
            
            tic;
            
            % add paths for all the flow algorithms
            CalcFlows.addPaths();
            
            % add sub-directories for this algorithm
            sub_dirs = addSubDirsToPath( fullfile(CalcFlows.ALGOS_PATH, HornSchunckOF.OF_DIRECTORY_NAME) );
            
            uv_hs = estimate_flow_hs(im1, im2, 'lambda', 200);
            
            % remove the algo sub-directories after computation
            rmpath(sub_dirs);
            
            hs_compute_time = toc;
        end
    end
end

