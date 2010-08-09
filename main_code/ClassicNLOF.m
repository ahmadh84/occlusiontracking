classdef ClassicNLOF < AbstractOF
    %CLASSICNLOF
    % Sun, D.; Roth, S. & Black, M. J. 
    %   "Secrets of Optical Flow Estimation and Their Principles" IEEE Int. 
    %   Conf. on Comp. Vision & Pattern Recognition, 2010
    
    
    properties (Constant)
        OF_TYPE = 'Classic NL';
        OF_SHORT_TYPE = 'CN';
        
        OF_DIRECTORY_NAME = 'Classic NL';
    end
    
    
    methods (Static)
        function uv_cn = calcFlow(im1, im2)
            % calculates the Sun's Classic NL flow
            fprintf('--> Computing Classic NL flow\n');
            
            % add paths for all the flow algorithms
            CalcFlows.addPaths();
            
            % add sub-directories for this algorithm
            sub_dirs = addSubDirsToPath( fullfile(CalcFlows.ALGOS_PATH, ClassicNLOF.OF_DIRECTORY_NAME) );
            
            uv_cn = estimate_flow_interface(im1, im2, 'classic+nl-fast');
            
            % remove the algo sub-directories after computation
            rmpath(sub_dirs);
        end
    end
    
end

