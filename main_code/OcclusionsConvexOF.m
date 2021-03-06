classdef OcclusionsConvexOF < AbstractOF
    %OcclusionsConvexOF 
    % get output for "Occlusion Detection and Motion Estimation with Convex 
    %   Optimization" (A. Ayvaci, M. Raptis, S. Soatto NIPS, 2010)
    
    properties (Constant)
        OF_TYPE = 'Occlusion-Motion-ConvexOpt';
        OF_SHORT_TYPE = 'OC';
        
        SAVE_FILENAME = 'occlconvex.mat';
        FORWARD_FLOW_VAR = 'uv_oc';
        BCKWARD_FLOW_VAR = 'uv_oc_r';
        COMPUTATION_TIME_VAR = 'oc_compute_time';
    end
    
    
    methods (Static)
        function [ uv_oc oc_compute_time ] = calcFlow(im1, im2, extra_info)
            % try load flow from file
            [ success uv_oc oc_compute_time all_loaded_info ] = AbstractOF.loadFromFile(eval(mfilename('class')), extra_info);
            
            if ~success
                % calculates the Occlusion-Motion-ConvexOpt flow
                fprintf('--> Computing Occlusion-Motion-ConvexOpt flow\n');

                tic;

                % add paths for all the flow algorithms
                CalcFlows.addPaths();
                addpath(fullfile(CalcFlows.ALGOS_PATH, 'sparse-occlusion-detection/utils'));

                [ uv_oc e ebar ] = estimate_flow_L2_rwL1_wTV_nesterov(im1, im2);

                oc_compute_time = toc;
            end
        end
    end
    
end

