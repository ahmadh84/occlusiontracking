classdef GTFlowOF < AbstractOF
    %GTFlowOF
    % Loads from file
    
    
    properties (Constant)
        OF_TYPE = 'GT Flow';
        OF_SHORT_TYPE = 'GF';
        
        OF_FILE_NAME = '1_2_orig.flo';
    end
    
    
    methods (Static)
        function [ uv_gf gf_compute_time ] = calcFlow(dir_path)
            % calculates the GT flow
            fprintf('--> Computing GT flow\n');
            
            tic;
            
            % add paths for all the flow algorithms
            CalcFlows.addPaths();
            
            % get gt flow
            uv_gf = readFlowFile(fullfile(dir_path, GTFlowOF.OF_FILE_NAME));
            
            gf_compute_time = toc;
        end
    end
    
end

