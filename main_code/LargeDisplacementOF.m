classdef LargeDisplacementOF < AbstractOF
    %LARGEDISPLACEMENTOF 
    % Thomas Brox, Jitendra Malik. 
    %  Large Displacement Optical Flow: Descriptor Matching in Variational
    %  Motion Estimation
    %  IEEE PAMI, 2010.
    
    
    properties (Constant)
        OF_TYPE = 'Large Displacement OF';
        OF_SHORT_TYPE = 'LD';
    end
    
    
    methods (Static)
        function [ uv_ld ld_compute_time ] = calcFlow(im1, im2)
            % calculates the Brox's Large Displacement Optical flow
            fprintf('--> Computing Large Displacement Optical flow\n');
            
            tic;
            
            % add paths for all the flow algorithms
            CalcFlows.addPaths();
            
            uv_ld = mex_LDOF(double(im1), double(im2));
            
            ld_compute_time = toc;
        end
    end
    
end

