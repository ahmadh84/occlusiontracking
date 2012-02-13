classdef LargeDisplacementVSOF < AbstractOF
    %LARGEDISPLACEMENTOF 
    % Thomas Brox, Jitendra Malik. 
    %  Large Displacement Optical Flow: Descriptor Matching in Variational
    %  Motion Estimation
    %  IEEE PAMI, 2010.
    
    
    properties (Constant)
        OF_TYPE = 'Large Displacement OF VS';
        OF_SHORT_TYPE = 'LDV';
        VS_CODE_FLOW_CHECK = 1;
        
        TEMP_DIR = 'temp_largedispof_vs';
        ALGO_LDOF_VS_PATH = '/home/ahumayun/algosuitability/code/ldof_flow_binary';
        ALGO_LDOF_VS_EXEC = './ldof "%s" "%s"';
        OUTPUTFLOW_FILENAME = 'temp.flow';
        
        SAVE_FILENAME = 'largedispof_vs.mat';
        FORWARD_FLOW_VAR = 'uv_ldv';
        BCKWARD_FLOW_VAR = 'uv_ldv_r';
        COMPUTATION_TIME_VAR = 'ldv_compute_time';
    end
    
    
    methods (Static)
        function [ uv_ldv ldv_compute_time ] = calcFlow(im1, im2, extra_info)
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
            [ success uv_ldv ldv_compute_time all_loaded_info ] = AbstractOF.loadFromFile(eval(mfilename('class')), extra_info);
            
            if ~success
                % calculates the Brox's Large Displacement Optical flow
                fprintf('--> Computing Large Displacement Optical flow (from VideoSegmentation framework)\n');
                
                curr_path = pwd;
                
                curr_path_im1 = fullfile(curr_path, 'temp_1_delete_if_found.ppm');
                curr_path_im2 = fullfile(curr_path, 'temp_2_delete_if_found.ppm');
                
                % create pgm files (the exe only works on pgm files)
                imwrite(im1, curr_path_im1);
                imwrite(im2, curr_path_im2);
                
                % move to executable files dir, execute and read flow file
                status = 3;
                while status ~= 0
                    cd(LargeDisplacementVSOF.ALGO_LDOF_VS_PATH);
                    [status, result] = system(sprintf(LargeDisplacementVSOF.ALGO_LDOF_VS_EXEC, curr_path_im1, curr_path_im2));
                end
                
                % return to original path
                cd(curr_path);
                
                % read the flow output
                uv_ldv = readFlowFile('temp_1_delete_if_foundLDOF.flo');
                
                % delete the temp. ppm images
                delete(curr_path_im1);
                delete(curr_path_im2);
                
                % delete the flow file and all extrea images
                delete('temp_1_delete_if_foundLDOF.flo');
                delete('temp_1_delete_if_foundLDOF.ppm');
                
                ldv_compute_time = toc;
            end
        end
    end
    
end

