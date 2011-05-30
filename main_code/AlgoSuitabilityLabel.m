classdef AlgoSuitabilityLabel < AbstractLabel
    %ALGOSUITABILITYLABEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        label_names = {};
        DISC_EPE_TH = 0.30;
    end
    
    properties (Constant)
        LABEL_TYPE = 'Algo Suitability Label';
        LABEL_SHORT_TYPE = 'AS';
        LABEL_IS_BINARY = 0;
        LABEL_PURPOSE = 'finding most Suitable Flow Algo.';
    end
    
    methods
        function obj = AlgoSuitabilityLabel( cell_flows, disc_epe_th )
            % store the label names in order
            obj.label_names = cellfun(@(x) x.OF_SHORT_TYPE, cell_flows, 'UniformOutput',false);
            
            % store the EPE threshold btw the best and second best label
            % needed for training
            obj.DISC_EPE_TH = disc_epe_th;
        end
        
        
        function [ label data_idxs idxs_per_label ] = calcLabelTraining( obj, comp_feat_vec, MAX_MARKINGS_PER_LABEL, extra_label_info )
            
            [ labels ignore_labels ] = obj.calcLabelWhole( comp_feat_vec, extra_label_info );
            
%             max_label = length(extra_label_info.calc_flows.cell_flow_algos)+ 1;
            max_label = length(extra_label_info.calc_flows.cell_flow_algos);
            
            % dont train on pixels which are not discriminative enough
            if obj.DISC_EPE_TH > 0
                not_discr_enough = extra_label_info.calc_flows.epe_dist_btwfirstsec <= obj.DISC_EPE_TH;
                not_discr_enough = not_discr_enough';
                ignore_labels = ignore_labels | not_discr_enough(:);
            end
            
            % remove the ignored labels
            labels = double(labels);
            labels(ignore_labels) = inf;
            
            % want equal contribution from each class
            class_regions = arrayfun(@(x) find(labels==x), 1:max_label, 'UniformOutput',false);
            
            % shuffle
            idxs_per_label  = min([cellfun(@length, class_regions) MAX_MARKINGS_PER_LABEL]);

            data_idxs = {};
            
            for idx = 1:max_label
                shuff = randperm(length(class_regions{idx}));
                label(idx) = idx;
                data_idxs{idx} = class_regions{idx}(shuff(1:idxs_per_label));
            end
        end
        
        
        function [ labels ignore_labels ] = calcLabelWhole( obj, comp_feat_vec, extra_label_info )
        % outputs all the labels given the data features (usually not used) 
        % and customizable extra information (here the GT flow)
        
            assert(isfield(extra_label_info, 'calc_flows'), 'CalcFlows object is needed for computing occlusion label');
            
            mask = extra_label_info.calc_flows.gt_mask;
            labels = extra_label_info.calc_flows.class_epe;
            labels(mask == 0) = length(extra_label_info.calc_flows.cell_flow_algos) + 1;
            labels = labels';
            labels = labels(:);
            
            % inform user about the labels they should ignore
            if ~isempty(extra_label_info.calc_flows.gt_ignore_mask)
                fprintf(1, 'IGNORING labelling of %d/%d pixels for %s\n', nnz(extra_label_info.calc_flows.gt_ignore_mask), numel(extra_label_info.calc_flows.gt_ignore_mask), comp_feat_vec.scene_dir);
                
                ignore_labels = extra_label_info.calc_flows.gt_ignore_mask';
                ignore_labels = ignore_labels(:);
            else
                ignore_labels = false(size(labels));
            end
        end
    end
    
end

