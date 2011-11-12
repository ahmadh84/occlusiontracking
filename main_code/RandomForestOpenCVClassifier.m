classdef RandomForestOpenCVClassifier < AbstractClassifier
    %RANDOMFORESTOPENCVCLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CLSFR_TYPE = 'Random Forest OpenCV';
        CLSFR_SHORT_TYPE = 'RFO';
        
        CLSFR_EXEC_PATH = 'randomForest\src\predictDescriptor\Release\predictDescriptor.exe ';
    end
    
    methods
        
    end
    
end

