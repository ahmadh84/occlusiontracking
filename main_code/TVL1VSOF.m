classdef TVL1VSOF < AbstractOF
    %TVL1VSOF 
    % get output for "An Improved Algorithm for TV-L1 Optical Flow" (A. 
    %   Wedel, T. Pock, C. Zach, H. Bischof, D. Cremers, H. Bischof. 
    %   Statistical and Geometrical Approaches to Visual Motion Analysis, 
    %   2009)
    
    properties (Constant)
        OF_TYPE = 'TV-L1-VS';
        OF_SHORT_TYPE = 'TVV';
        VS_CODE_FLOW_CHECK = 1;
        
        TEMP_DIR = 'temp_tv_l1_vs';
        ALGO_TV_L1_VS_PATH = '/home/ahumayun/videoseg/gpu_flow_binary_bin/';
        ALGO_TV_L1_VS_EXEC = 'gpu-flow-binary --i %s --flow_type forward --renderflow';
        VIDEO_CONVERT_EXEC = 'ffmpeg -y -i %s -an -vcodec ffv1 %s';
        MOVIE_FILENAME = 'temp.avi';
        FLOW_FILENAME = 'temp.flow';
        
        SAVE_FILENAME = 'tvl1vs.mat';
        FORWARD_FLOW_VAR = 'uv_tvv';
        BCKWARD_FLOW_VAR = 'uv_tvv_r';
        COMPUTATION_TIME_VAR = 'tvv_compute_time';
    end
    
        
    methods (Static)
        function [ uv_tvv tvv_compute_time ] = calcFlow(im1, im2, extra_info)
            % try load flow from file
            [ success uv_tvv tvv_compute_time all_loaded_info ] = AbstractOF.loadFromFile(eval(mfilename('class')), extra_info);
            
            % try to load flow from file written by VideoSeg framework
            if TVL1VSOF.VS_CODE_FLOW_CHECK
                if extra_info.reverse == 0
                    % forward flow file
                    filename = fullfile(extra_info.scene_dir, 'flowfwd.flow');
                else
                    % backward flow file
                    filename = fullfile(extra_info.scene_dir, 'flowbwd.flow');
                end
                
                % load the flow if it exists
                if exist(filename, 'file') == 2
                    fid = fopen(filename);
                    [u] = fread(fid, [size(im1,2) size(im1,1)], 'float');
                    [v] = fread(fid, [size(im1,2) size(im1,1)], 'float');
                    uv_tvv = cat(3,u',v');
                    tvv_compute_time = 0;
                    success = 1;
                end
            end
            
            if ~success
                % calculates the anisotropic TV-L1 flow
                fprintf('--> Computing TV-L1 flow (from VideoSegmentation framework)\n');
                
                curr_path = pwd;
                
                % create a new directory to do the computation
                if exist(TVL1VSOF.TEMP_DIR, 'dir') == 7
                    rmdir(TVL1VSOF.TEMP_DIR, 's');
                end
                mkdir(TVL1VSOF.TEMP_DIR);
                
                % write images for converting to video
                imwrite(im1, fullfile(TVL1VSOF.TEMP_DIR, ComputeTrainTestData.IM1_PNG));
                imwrite(im2, fullfile(TVL1VSOF.TEMP_DIR, ComputeTrainTestData.IM2_PNG));
                
                cd(TVL1VSOF.TEMP_DIR);
                
                % run ffmpeg to create video filestatus = 3;
                status = 3;
                while status ~= 0
                    [status, result] = system(sprintf(TVL1VSOF.VIDEO_CONVERT_EXEC, '%d.png', TVL1VSOF.MOVIE_FILENAME));
                    if status ~= 0
                        warning('TVL1VSOF:FFMPEGConversion', 'Problem occured while attempting to convert images to video.\nOutput:\n%s', result);
                    end
                end
                
                tic;
                
                % call Video Segmentation flow computation on the 2 frame
                % video created above
                exec = sprintf(TVL1VSOF.ALGO_TV_L1_VS_EXEC, TVL1VSOF.MOVIE_FILENAME);
                status = 3;
                while status ~= 0
                    [status, result] = system([TVL1VSOF.ALGO_TV_L1_VS_PATH exec]);
                    if status ~= 0
                        warning('TVL1VSOF:VSFlowComputation', 'Problem occured while attempting to run flow computation in video segmentation framework.\nOutput:\n%s', result);
                    end
                end
                
                % read file for forward flow
                fid = fopen(TVL1VSOF.FLOW_FILENAME);
                header_info = fread(fid, 3, 'int'); % read header
                [u] = fread(fid, [size(im1,2) size(im1,1)], 'float');
                [v] = fread(fid, [size(im1,2) size(im1,1)], 'float');
                uv_tvv = cat(3,u',v');
                
                fclose(fid);
                
                % return to original path and delete the temp directory
                cd(curr_path);
                rmdir(TVL1VSOF.TEMP_DIR, 's');
                
                tvv_compute_time = toc;
            end
        end
    end
    
end

