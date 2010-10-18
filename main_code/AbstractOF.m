classdef AbstractOF
    %ABSTRACTOF Abstract class for calculating flow
    
    properties (Abstract, Constant)
        OF_TYPE;
        OF_SHORT_TYPE;
    end
    
    
    methods (Abstract, Static)
        [ uv_of compute_time ] = calcFlow( im1, im2 )
    end
    
    
    methods
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = uint8(obj.OF_SHORT_TYPE);
            nos = double(nos) .* ([1:length(nos)].^2);
            feature_no_id = sum(nos);
        end
    end
    
end

