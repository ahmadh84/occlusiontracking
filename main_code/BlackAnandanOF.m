classdef BlackAnandanOF < AbstractOF
    %BLACKANANDANOF
    % get output for "The robust estimation of multiple motions: Parametric 
    %   and piecewise-smooth flow-fields" (M. Black, P. Anandan. CVIU, 
    %   1996)
    
    properties (Constant)
        OF_TYPE = 'Black-Anandan';
        OF_SHORT_TYPE = 'BA';
        
        OF_DIRECTORY_NAME = 'Black & Anandan 3';
    end
    

    methods (Static)
        function uv_ba = calcFlow(im1, im2)
            % calculates the Black Anandan flow
            fprintf('--> Computing Black Anandan flow\n');
            
            % add paths for all the flow algorithms
            CalcFlows.addPaths();
            
            % add sub-directories for this algorithm
            sub_dirs = addSubDirsToPath( fullfile(CalcFlows.ALGOS_PATH, BlackAnandanOF.OF_DIRECTORY_NAME) );
            
            uv_ba = estimate_flow_ba(im1, im2);
            
            % remove the algo sub-directories after computation
            rmpath(sub_dirs);
        end
    end
end

