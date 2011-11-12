classdef TVL1OF < AbstractOF
    %TVL1OF 
    % get output for "An improved algorithm for TV-L1 optical flow" (A. 
    %   Wedel, T. Pock, C. Zach, H. Bischof, D. Cremers. In Proc. of the 
    %   Dagstuhl Motion Workshop, LNCS. 2008)
    
    properties (Constant)
        OF_TYPE = 'TV-L1';
        OF_SHORT_TYPE = 'TV';
    end
    
    
    methods (Static)
        function [ uv_tv tv_compute_time ] = calcFlow(im1, im2)
            % calculates the TV-L1 flow
            fprintf('--> Computing TV-L1 flow\n');
            
            tic;
            
            % add paths for all the flow algorithms
            CalcFlows.addPaths();

            % smoothness of flow
            lambda = 50;

            % warping parameters
            pyramid_levels = 1000; % as much as possible
            pyramid_factor = 0.9;
            warps = 1;
            maxits = 50;
            
            % this TV_L1 implementation only takes grayscale values
            im1 = im2double(rgb2gray(im1));
            im2 = im2double(rgb2gray(im2));
            
            [uv_tv illumination] = ...
                coarse_to_fine(im1, im2, lambda, warps, maxits, pyramid_levels, pyramid_factor, 1);
            %uv_tv = tvl1of(im1, im2);
            
            tv_compute_time = toc;
        end
    end
    
end

