classdef LargeDisplacementOF < AbstractOF
    %LARGEDISPLACEMENTOF 
    % Thomas Brox, Jitendra Malik. 
    %  Large Displacement Optical Flow: Descriptor Matching in Variational
    %  Motion Estimation
    %  IEEE PAMI, 2010.
    
    
    properties (Constant)
        OF_TYPE = 'Large Displacement OF';
        OF_SHORT_TYPE = 'LD';
        
        SAVE_FILENAME = 'largedispof.mat';
        FORWARD_FLOW_VAR = 'uv_ld';
        BCKWARD_FLOW_VAR = 'uv_ld_r';
        COMPUTATION_TIME_VAR = 'ld_compute_time';
    end
    
    
    methods (Static)
        function [ uv_ld ld_compute_time ] = calcFlow(im1, im2, extra_info)
            % When there was no 64 bit windows mex
%             % DON'T HAVE 64BIT MEX FOR LDOF
%             warning('CalcFlows:computeFlows', 'loading directly from file');
%             
%             % if file doesn't exist, attempt to compute it on a remote linux machine
%             if exist(fullfile(obj.scene_dir, 'largedispof.mat'), 'file') ~= 2
%                 addpath('remoteexec');
%                 status = remote_ldof(fullfile(obj.scene_dir, ComputeTrainTestData.IM1_PNG), fullfile(obj.scene_dir, ComputeTrainTestData.IM2_PNG));
%                 assert(status == 0, 'Something went wrong while computing LDOF remotely');
%             end
            
            % try load flow from file
            [ success uv_ld ld_compute_time all_loaded_info ] = AbstractOF.loadFromFile(eval(mfilename('class')), extra_info);
            
            if ~success
                % calculates the Brox's Large Displacement Optical flow
                fprintf('--> Computing Large Displacement Optical flow\n');

                % make color images out of B/W
                if ndims(im1) == 2;
                    im1 = repmat(im1, [1 1 3]);
                end
                if ndims(im2) == 2;
                    im2 = repmat(im2, [1 1 3]);
                end
                
                tic;

                % add paths for all the flow algorithms
                CalcFlows.addPaths();

                uv_ld = mex_LDOF(double(im1), double(im2));

                ld_compute_time = toc;
            end
        end
    end
    
end

