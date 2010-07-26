classdef BlackAnandanOF < AbstractOF
    %BLACKANANDANOF
    % get output for "The robust estimation of multiple motions: Parametric 
    %   and piecewise-smooth flow-fields" (M. Black, P. Anandan. CVIU, 
    %   1996)
    
    properties (Constant)
        OF_TYPE = 'Black-Anandan';
        OF_SHORT_TYPE = 'BA';
    end
    

    methods (Static)
        function uv_ba = calcFlow(im1, im2)
            % calculates the Black Anandan flow
            fprintf('--> Computing Black Anandan flow\n');
            
            % add paths for the algorithms
            CalcFlows.addPaths();
            
            uv_ba = estimate_flow_ba(im1, im2);
        end
    end
end

