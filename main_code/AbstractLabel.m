classdef AbstractLabel
    %ABSTRACTLABEL Feature used as labelling for training and testing the
    %   classifier
    
    properties (Abstract, Constant)
        LABEL_TYPE;
        LABEL_SHORT_TYPE;
    end
    
    
    methods (Abstract)
        [ label data_idxs idxs_per_label ] = calcLabelTraining( obj, comp_feat_vec, MAX_MARKINGS_PER_LABEL, extra_label_info );
        
        [ labels ignore_labels ] = calcLabelWhole( obj, comp_feat_vec, extra_label_info );
    end
    
    
    methods
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = uint8(obj.LABEL_SHORT_TYPE);
            nos = double(nos) .* ([1:length(nos)].^2);
            feature_no_id = sum(nos);
        end
    end
    
end

