classdef HuberL1VSOF < AbstractOF
    %HUBERL1VSOF 
    % get output for "Anisotropic Huber-L1 optical flow" (M. Werlberger, W.
    %   Trobin, T. Pock, A. Wedel, D. Cremers, H. Bischof. BMVC, 2009)
    
    properties (Constant)
        OF_TYPE = 'Huber-L1-VS';
        OF_SHORT_TYPE = 'VS';
        VS_CODE_FLOW_CHECK = 1;
        
        TEMP_DIR = 'temp_huber_l1_vs';
        ALGO_HUBER_L1_VS_PATH = '/home/ahumayun/videoseg/gpu_flow_binary_bin/';
        ALGO_HUBER_L1_VS_EXEC = 'gpu-flow-binary --i %s --flow_type forward --renderflow';
        VIDEO_CONVERT_EXEC = 'ffmpeg -y -i %s -an -vcodec ffv1 %s';
        MOVIE_FILENAME = 'temp.avi';
        FLOW_FILENAME = 'temp.flow';
        
        SAVE_FILENAME = 'huberl1vs.mat';
        FORWARD_FLOW_VAR = 'uv_vs';
        BCKWARD_FLOW_VAR = 'uv_vs_r';
        COMPUTATION_TIME_VAR = 'vs_compute_time';
    end
    
        
    methods (Static)
        function [ uv_vs vs_compute_time ] = calcFlow(im1, im2, extra_info)
            % try load flow from file
            [ success uv_vs vs_compute_time all_loaded_info ] = AbstractOF.loadFromFile(eval(mfilename('class')), extra_info);
            
            if HuberL1VSOF.VS_CODE_FLOW_CHECK
                if extra_info.reverse == 0
                    % forward flow file
                    filename = fullfile(extra_info.scene_dir, 'flowbwd.flow');
                else
                    % backward flow file
                    filename = fullfile(extra_info.scene_dir, 'flowbwd.flow');
                end
                
                % load the flow if it exists
                if exist(filename, 'file') == 2
                    fid = fopen(filename);
                    [u] = fread(fid, [size(im1,2) size(im1,1)], 'float');
                    [v] = fread(fid, [size(im1,2) size(im1,1)], 'float');
                    uv_vs = cat(3,u',v');
                    vs_compute_time = 0;
                end
            end
            
            if ~success
                % calculates the anisotropic Huber-L1 flow
                fprintf('--> Computing Huber-L1 flow (from VideoSegmentation framework)\n');

                tic;

                curr_path = pwd;
                
                % create a new directory to do the computation
                if exist(HuberL1VSOF.TEMP_DIR, 'dir') == 7
                    rmdir(HuberL1VSOF.TEMP_DIR, 's');
                end
                mkdir(HuberL1VSOF.TEMP_DIR);
                
                % write images for converting to video (copy in reverse if
                % computing backward flow)
                if extra_info.reverse == 0
                    copyfile(fullfile(extra_info.scene_dir, ComputeTrainTestData.IM1_PNG), fullfile(HuberL1VSOF.TEMP_DIR, ComputeTrainTestData.IM1_PNG));
                    copyfile(fullfile(extra_info.scene_dir, ComputeTrainTestData.IM2_PNG), fullfile(HuberL1VSOF.TEMP_DIR, ComputeTrainTestData.IM2_PNG));
                else
                    copyfile(fullfile(extra_info.scene_dir, ComputeTrainTestData.IM1_PNG), fullfile(HuberL1VSOF.TEMP_DIR, ComputeTrainTestData.IM2_PNG));
                    copyfile(fullfile(extra_info.scene_dir, ComputeTrainTestData.IM2_PNG), fullfile(HuberL1VSOF.TEMP_DIR, ComputeTrainTestData.IM1_PNG));
                end
                
                cd(HuberL1VSOF.TEMP_DIR);
                
                % run ffmpeg to create video filestatus = 3;
                status = 3;
                while status ~= 0
                    [status, result] = system(sprintf(HuberL1VSOF.VIDEO_CONVERT_EXEC, '%d.png', HuberL1VSOF.MOVIE_FILENAME));
                    if status ~= 0
                        warning('HuberL1VSOF:FFMPEGConversion', 'Problem occured while attempting to convert images to video.\nOutput:\n%s', result);
                    end
                end
                
                tic;
                
                % call Video Segmentation flow computation on the 2 frame
                % video created above
                exec = sprintf(HuberL1VSOF.ALGO_HUBER_L1_VS_EXEC, HuberL1VSOF.MOVIE_FILENAME);
                status = 3;
                while status ~= 0
                    [status, result] = system([HuberL1VSOF.ALGO_HUBER_L1_VS_PATH exec]);
                    if status ~= 0
                        warning('HuberL1VSOF:VSFlowComputation', 'Problem occured while attempting to run flow computation in video segmentation framework.\nOutput:\n%s', result);
                    end
                end
                
                % read file for forward flow
                fid = fopen(HuberL1VSOF.FLOW_FILENAME);
                header_info = fread(fid, 3, 'int'); % read header
                [u] = fread(fid, [size(im1,2) size(im1,1)], 'float');
                [v] = fread(fid, [size(im1,2) size(im1,1)], 'float');
                uv_vs = cat(3,u',v');
                
                fclose(fid);
                
                % return to original path and delete the temp directory
                cd(curr_path);
                rmdir(HuberL1VSOF.TEMP_DIR, 's');
                
                vs_compute_time = toc;
            end
        end
    end
    
end

