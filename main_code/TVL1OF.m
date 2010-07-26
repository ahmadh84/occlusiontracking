classdef TVL1OF < AbstractOF
    %TVL1OF 
    % get output for "An improved algorithm for TV-L1 optical flow" (A. 
    %   Wedel, T. Pock, C. Zach, D. Cremers, H. Bischof. In Proc. of the 
    %   Dagstuhl Motion Workshop, LNCS. 2008)
    
    properties (Constant)
        OF_TYPE = 'TV-L1';
        OF_SHORT_TYPE = 'TV';
    end
    
    
    methods (Static)
        function uv_tv = calcFlow(im1, im2)
            % calculates the TV-L1 flow
            fprintf('--> Computing TV-L1 flow\n');
            
            % add paths for the algorithms        
            CalcFlows.addPaths();
            
            uv_tv = tvl1of(im1, im2);
        end
    end
    
end

