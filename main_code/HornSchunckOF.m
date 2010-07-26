classdef HornSchunckOF < AbstractOF
    %HORNSCHUNCKOF 
    % get output for "Determining optical flow" (B. Horn, B. G. Schunck, 
    %   Artificial Intelligence, 1981)

    properties (Constant)
        OF_TYPE = 'Horn-Schunck';
        OF_SHORT_TYPE = 'HS';
    end
    
    
    methods (Static)
        function uv_hs = calcFlow(im1, im2)
            % calculates the Horn Schunk flow
            fprintf('--> Computing Horn Schunk flow\n');
            
            % add paths for the algorithms
            CalcFlows.addPaths();
            
            uv_hs = estimate_flow_hs(im1, im2, 'lambda', 200);
        end
    end
end

