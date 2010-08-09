classdef HuberL1OF < AbstractOF
    %HUBERL1OF 
    % get output for "Anisotropic Huber-L1 optical flow" (M. Werlberger, W.
    %   Trobin, T. Pock, A. Wedel, D. Cremers, H. Bischof. BMVC, 2009)
    
    properties (Constant)
        OF_TYPE = 'Huber-L1';
        OF_SHORT_TYPE = 'FL';
        ALGO_HUBER_L1_PATH = fullfile(CalcFlows.ALGOS_PATH, 'FlowLib');
    end
    
    
    methods (Static)
        function uv_fl = calcFlow( im1, im2 )
            % calculates the anisotropic Huber-L1 flow
            fprintf('--> Computing Huber-L1 flow\n');
            
            % add paths for all the flow algorithms
            CalcFlows.addPaths();
            
            curr_path = pwd;
            curr_path_im1 = fullfile(curr_path, 'temp_1_delete_if_found.pgm');
            curr_path_im2 = fullfile(curr_path, 'temp_2_delete_if_found.pgm');
            
            % create pgm files (the exe only works on pgm files)
            imwrite(im1, curr_path_im1);
            imwrite(im2, curr_path_im2);
            
            % move to executable files dir, execute and read flow file
            cd(HuberL1OF.ALGO_HUBER_L1_PATH);
            system(['flow_win_demo -v --flo flow.flo --texture_rescale -l 40 --diffusion --str_tex "' curr_path_im1 '" "'  curr_path_im2 '"']);
            uv_fl = readFlowFile('flow.flo');
            
            % delete the flow file
            delete('flow.flo');
            
            % return to original path and delete the temp. pgm images
            cd(curr_path);
            delete(curr_path_im1);
            delete(curr_path_im2);
        end
    end
    
end

