classdef TVL1OF < AbstractOF
    %TVL1OF 
    % get output for "A Duality Based Approach for Realtime TV-L1 Optical 
    %   Flow" (C. Zach and T. Pock and H. Bischof. In Pattern Recognition 
    %   (Proc. DAGM), 2007)
    
    properties (Constant)
        OF_TYPE = 'TV-L1';
        OF_SHORT_TYPE = 'TV';
        
        SAVE_FILENAME = '';
        FORWARD_FLOW_VAR = '';
        BCKWARD_FLOW_VAR = '';
        COMPUTATION_TIME_VAR = '';
    end
    
    
    methods (Static)
        function [ uv_tv tv_compute_time ] = calcFlow(im1, im2, extra_info)
            % calculates the TV-L1 flow
            fprintf('--> Computing TV-L1 flow\n');
            
            tic;
            
            % add paths for all the flow algorithms
            CalcFlows.addPaths();
            
            uv_tv = tvl1of(im1, im2);
            
            tv_compute_time = toc;
        end
    end
    
end

