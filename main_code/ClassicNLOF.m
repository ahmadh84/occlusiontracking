classdef ClassicNLOF < AbstractOF
    %CLASSICNLOF
    % Sun, D.; Roth, S. & Black, M. J. 
    %   "Secrets of Optical Flow Estimation and Their Principles" IEEE Int. 
    %   Conf. on Comp. Vision & Pattern Recognition, 2010
    
    
    properties (Constant)
        OF_TYPE = 'Classic NL';
        OF_SHORT_TYPE = 'CN';
    end
    
    
    methods (Static)
        function uv_cn = calcFlow(im1, im2)
            % calculates the Sun's Classic NL flow
            fprintf('--> Computing Classic NL flow\n');
            
            % add paths for the algorithms
%             CalcFlows.addPaths();
            addpath(genpath('algorithms/Classic NL'));
            
            uv_cn = estimate_flow_interface(im1, im2, 'classic+nl-fast');
        end
    end
    
end

