classdef FlowAEConfidenceLabel < AbstractLabel
    %FLOWAECONFIDENCELABEL is the label used to train/test for getting
    % pixels whose angular-error is under a certain threshold (specified 
    % by epe_threshold). Training with this label essentially gives a
    % confidence score for a certain pixel's AE being under the set
    % threshold.
    
    properties
        ae_threshold = [];
    end
    
    
    properties (Constant)
        LABEL_TYPE = 'Flow AE Confidence Label';
        LABEL_SHORT_TYPE = 'FACL';
        LABEL_IS_BINARY = 1;
        LABEL_PURPOSE = 'choosing Flow with AE under a threshold';
    end
    
    
    methods
        function obj = FlowAEConfidenceLabel( ae_threshold )
            obj.ae_threshold = ae_threshold;
        end
        
        
        function [ label data_idxs idxs_per_label ] = calcLabelTraining( obj, comp_feat_vec, MAX_MARKINGS_PER_LABEL, extra_label_info )
        % creates label data which can be used in training stage of a
        % classifier. It would produce at maximum MAX_MARKINGS_PER_LABEL
        % labels belonging to data_idxs
        
            [ labels ignore_labels ] = obj.calcLabelWhole( comp_feat_vec, extra_label_info );
            
            % remove the ignored labels
            labels = double(labels);
            labels(ignore_labels) = inf;
            
            % want equal contribution from each class
            non_occl_regions = find(labels==0);
            occl_regions = find(labels==1);
            
            % shuffle
            idxs_per_label  = min([length(non_occl_regions) length(occl_regions) MAX_MARKINGS_PER_LABEL]);

            data_idxs = {};
            
            shuff = randperm(length(non_occl_regions));
            label(1) = 0;
            data_idxs{1} = non_occl_regions(shuff(1:idxs_per_label));

            shuff = randperm(length(occl_regions));
            label(2) = 1;
            data_idxs{2} = occl_regions(shuff(1:idxs_per_label));
        end
        
        
        function [ labels ignore_labels ] = calcLabelWhole( obj, comp_feat_vec, extra_label_info )
        % outputs all the labels given the data features (usually not used) 
        % and customizable extra information (here the GT flow)
        
            assert(isfield(extra_label_info, 'uv_ang_err'), 'uv_ang_err matrix is needed for computing FlowAEConfidenceLabel');
            
            mask = extra_label_info.uv_ang_err;
            labels = (mask < obj.ae_threshold)';
            labels = labels(:);
            
            ignore_labels = false(size(labels));
        end
        
        
        function label_no_id = returnNoID(obj)
        % creates unique label number, good for storing with the file
        % name
        
            % create unique ID
            nos = returnNoID@AbstractLabel(obj);
        
            label_no_id = nos + round(obj.ae_threshold*100);
        end
    end
    
end

