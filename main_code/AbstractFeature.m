classdef AbstractFeature
    %ABSTRACTFEATURE Abstract class for computing a feature
    
    properties (Abstract, Constant)
        FEATURE_TYPE;
        FEATURE_SHORT_TYPE;
    end
    
    
    methods (Abstract)
        [ grad feature_depth ] = calcFeatures( obj, calc_feature_vec );
    end
    
    
    methods
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = uint8(obj.FEATURE_SHORT_TYPE);
            nos = double(nos) .* ([1:length(nos)].^2);
            feature_no_id = sum(nos);
        end
        
        
        function return_feature_list = returnFeatureList(obj)
        % creates a cell vector where each item contains a string of the
        % feature type (in the order the will be spit out by calcFeatures)
            
            return_feature_list{1} = {obj.FEATURE_TYPE, 'no scaling'};
        end
    end
    
end

