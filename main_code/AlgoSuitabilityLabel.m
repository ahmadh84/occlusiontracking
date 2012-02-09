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
        
        
        function [ label data_idxs labels2 idxs_per_label ] = calcLabelTraining( obj, comp_feat_vec, MAX_MARKINGS_PER_LABEL, extra_label_info )
            
            [ labels labels2 ignore_labels ] = obj.calcLabelWhole( comp_feat_vec, extra_label_info );
            
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
            labels2 = double(labels2);
            labels(ignore_labels,:) = inf;
            labels2(ignore_labels,:) = inf;
            
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
        
        
        function [ labels labels2 ignore_labels ] = calcLabelWhole( obj, comp_feat_vec, extra_label_info )
        % outputs all the labels given the data features (usually not used) 
        % and customizable extra information (here the GT flow)
        
            assert(isfield(extra_label_info, 'calc_flows'), 'CalcFlows object is needed for computing occlusion label');
            
            %%%%%%%%%%%%%%% ADJUST Calcflows %%%%%%%%%%%%%%%%%%
%             no_algos = size(extra_label_info.calc_flows.uv_epe,3);
%             extra_label_info.calc_flows.uv_ang_err = zeros(size(extra_label_info.calc_flows.uv_flows,1), size(extra_label_info.calc_flows.uv_flows,2), no_algos);
%             extra_label_info.calc_flows.uv_epe = extra_label_info.calc_flows.uv_ang_err;
%             for algo_idx = 1:no_algos
% %                [ extra_label_info.calc_flows.uv_ang_err(:,:,algo_idx) extra_label_info.calc_flows.uv_epe(:,:,algo_idx) ] = flowAngErrMe(extra_label_info.calc_flows.uv_gt(:,:,1), extra_label_info.calc_flows.uv_gt(:,:,2), ...
% %                                                                               extra_label_info.calc_flows.uv_flows(:,:,1,algo_idx), extra_label_info.calc_flows.uv_gt(:,:,2));
%                  [ extra_label_info.calc_flows.uv_ang_err(:,:,algo_idx) extra_label_info.calc_flows.uv_epe(:,:,algo_idx) ] = flowAngErrMe(extra_label_info.calc_flows.uv_gt(:,:,1), extra_label_info.calc_flows.uv_gt(:,:,2), ...
%                                                                                  extra_label_info.calc_flows.uv_gt(:,:,1), extra_label_info.calc_flows.uv_flows(:,:,2,algo_idx));
%             end
% 
%             % find the best algorithm according to Angular error
%             [ extra_label_info.calc_flows.result_ang extra_label_info.calc_flows.class_ang ] = min(extra_label_info.calc_flows.uv_ang_err,[],3);
% 
%             % find the best algorithm according to EPE
%             [ extra_label_info.calc_flows.result_epe extra_label_info.calc_flows.class_epe ] = min(extra_label_info.calc_flows.uv_epe,[],3);
% 
%             % find the distance between first and second best score
%             [vals ind] = sort(extra_label_info.calc_flows.uv_epe, 3);
%             if size(extra_label_info.calc_flows.uv_epe,3) > 1
%                 extra_label_info.calc_flows.epe_dist_btwfirstsec = vals(:,:,2) - vals(:,:,1);
%             else
%                 extra_label_info.calc_flows.epe_dist_btwfirstsec = vals;
%             end
% 
%             % GT mask
%             %obj.gt_mask = obj.loadGTMask( 0 );
% 
%             % check if unsure/ignore mask is available
%             %if exist(fullfile(obj.scene_dir, CalcFlows.GT_UNSURE_MASK), 'file') == 2
%              %   obj.gt_ignore_mask = imread(fullfile(obj.scene_dir, CalcFlows.GT_UNSURE_MASK));
%             %end
% 
%             % check if CGT mask is available
%             %if exist(fullfile(obj.scene_dir, CalcFlows.OCCL_CGT_MASK), 'file') == 2
%              %   obj.cgt_ignore_mask = imread(fullfile(obj.scene_dir, CalcFlows.OCCL_CGT_MASK));
%             %end
% 
%             % Average EPE relative to the mask
%             pts = nnz(extra_label_info.calc_flows.gt_mask);
%             for algo_idx = 1:no_algos
%                 temp_uv_epe = extra_label_info.calc_flows.uv_epe(:,:,algo_idx);
%                 extra_label_info.calc_flows.algo_avg_epe(algo_idx) = sum(sum(temp_uv_epe(extra_label_info.calc_flows.gt_mask)))/pts;
%             end
%             extra_label_info.calc_flows.opt_avg_epe = sum(sum(extra_label_info.calc_flows.result_epe(extra_label_info.calc_flows.gt_mask)))/pts;
            %%%%%%%%%%%%%%% ADJUST Calcflows fin %%%%%%%%%%%%%%%%%%
            
            mask = extra_label_info.calc_flows.gt_mask;
            labels = extra_label_info.calc_flows.class_epe;
            labels(mask == 0) = length(extra_label_info.calc_flows.cell_flow_algos) + 1;
            labels = labels';
            labels = labels(:);
            
            % prepare label having all class EPE values
            labels2 = extra_label_info.calc_flows.uv_epe;
            labels2(repmat(mask == 0, [1 1 length(extra_label_info.calc_flows.cell_flow_algos)])) = length(extra_label_info.calc_flows.cell_flow_algos) + 1;
            labels2 = permute(labels2, [2 1 3:ndims(labels2)]);        % labels = labels' for 2 dimensional case
            sz = [size(labels2) 1];
            labels2 = reshape(labels2, [sz(1)*sz(2) sz(3:end)]);       % labels = labels(:) for 2 dimensional case
            
            % inform user about the labels they should ignore
            if ~isempty(extra_label_info.calc_flows.gt_ignore_mask)
                fprintf(1, 'IGNORING labelling of %d/%d pixels for %s\n', nnz(extra_label_info.calc_flows.gt_ignore_mask), numel(extra_label_info.calc_flows.gt_ignore_mask), comp_feat_vec.scene_dir);
                
                ignore_labels = extra_label_info.calc_flows.gt_ignore_mask';
                ignore_labels = ignore_labels(:);
            else
                ignore_labels = false([size(labels,1) 1]);
            end
        end
    end
    
end

