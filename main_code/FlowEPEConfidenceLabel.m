classdef FlowEPEConfidenceLabel < AbstractLabel
    %FLOWCONFIDENCE label which gives occluded regions in flow
    
    properties
        epe_threshold = [];
    end
    
    
    properties (Constant)
        LABEL_TYPE = 'Flow EPE Confidence Label';
        LABEL_SHORT_TYPE = 'FECL';
        LABEL_IS_BINARY = 1;
        LABEL_PURPOSE = 'choosing Flow with EPE under a threshold';
    end
    
    
    methods
        function obj = FlowEPEConfidenceLabel( epe_threshold )
            obj.epe_threshold = epe_threshold;
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
        
            assert(isfield(extra_label_info, 'uv_epe'), 'uv_epe matrix is needed for computing FlowEPEConfidenceLabel');
            
            mask = extra_label_info.uv_epe;
            labels = (mask < obj.epe_threshold)';
            labels = labels(:);
            
            ignore_labels = false(size(labels));
        end
    end
    
end

