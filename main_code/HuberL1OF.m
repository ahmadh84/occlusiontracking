classdef HuberL1OF < AbstractOF
    %HUBERL1OF 
    % get output for "Anisotropic Huber-L1 optical flow" (M. Werlberger, W.
    %   Trobin, T. Pock, A. Wedel, D. Cremers, H. Bischof. BMVC, 2009)
    
    properties (Constant)
        OF_TYPE = 'Huber-L1';
        OF_SHORT_TYPE = 'FL';
        ALGO_HUBER_L1_PATH = fullfile(CalcFlows.ALGOS_PATH, 'FlowLib');
        
        SAVE_FILENAME = 'huberl1.mat';
        FORWARD_FLOW_VAR = 'uv_fl';
        BCKWARD_FLOW_VAR = 'uv_fl_r';
        COMPUTATION_TIME_VAR = 'fl_compute_time';
    end
    
    
    methods (Static)
        function [ uv_fl fl_compute_time ] = calcFlow(im1, im2, extra_info)
            % try load flow from file
            [ success uv_fl fl_compute_time all_loaded_info ] = AbstractOF.loadFromFile(eval(mfilename('class')), extra_info);
            
            if ~success
                % calculates the anisotropic Huber-L1 flow
                fprintf('--> Computing Huber-L1 flow\n');

                tic;

                % add paths for all the flow algorithms
                CalcFlows.addPaths();

                curr_path = pwd;
                curr_path_im1 = fullfile(curr_path, 'temp_1_delete_if_found.pgm');
                curr_path_im2 = fullfile(curr_path, 'temp_2_delete_if_found.pgm');

                % create pgm files (the exe only works on pgm files)
                imwrite(im1, curr_path_im1);
                imwrite(im2, curr_path_im2);

                % move to executable files dir, execute and read flow file
                status = 3;
                while status ~= 1
                    cd(HuberL1OF.ALGO_HUBER_L1_PATH);
                    [status, result] = system(['flow_win_demo -v --flo flow.flo --texture_rescale -l 40 --diffusion --str_tex "' curr_path_im1 '" "'  curr_path_im2 '"']);
                end
                uv_fl = readFlowFile('flow.flo');

                % delete the flow file
                delete('flow.flo');

                % return to original path and delete the temp. pgm images
                cd(curr_path);
                delete(curr_path_im1);
                delete(curr_path_im2);

                fl_compute_time = toc;
            end
        end
    end
    
end

