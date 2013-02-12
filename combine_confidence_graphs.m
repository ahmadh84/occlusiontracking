function combine_confidence_graphs(conf_dir, main_out_dir, data_dir, results_dir, confidence_epe_ths)
%COMBINE_CONFIDENCE_GRAPHS produces many graphs and images for visualizing
% the optical flow confidence classifier results (produced by for 
% testing_ofconfidence.m). This includes reproducing results for Fig 3. in
% the PAMI paper.
%
% @args
%   conf_dir: the directory where results for all the different confidence 
%                thresholds are stored in sub-directories - i.e. this
%                variable should be equal to [out_dir] in
%                testing_ofconfidence.m.
%
%   main_out_dir: output directory where the output imaages would be
%                written to
%
%   data_dir: the directory where all the sequences are stored - i.e. it
%                should be equivalent to [training_dir] in
%                testing_algosuitability.m and testing_ofconfidence.m
%
%   results_dir: where testing_algosuitability writes its results - i.e.
%                this variable should be equal to [temp_out_dir] in 
%                testing_algosuitability.m. If not given, KWay results are
%                not output for Confidence graphs (Fig 3).
%
%   confidence_epe_th: a vector of confidence values used for producing 
%                results in [conf_dir]. This is the set of values used in
%                testing_ofconfidence main for loop. If not defined it will
%                default to [0.1 0.25 0.5 2 10]

    seq_names = {'Venus', 'Urban3', 'Urban2', 'RubberWhale', 'Hydrangea', 'Grove3', 'Grove2', 'Dimetrodon', ...
        'Crates1*', 'Crates2*', 'Brickbox1*', 'Brickbox2*', 'Mayan1*', 'Mayan2*', 'YosemiteSun', 'GroveSun', ...
        'Robot*', 'Sponza1*', 'Sponza2*', 'Crates1Ltxtr*', 'Crates1Htxtr1*', 'Crates1Htxtr2*', 'Crates2Ltxtr*', ...
        'Crates2Htxtr1*', 'Crates2Htxtr2*', 'Brickbox1t1*', 'Brickbox1t2*', 'Brickbox2t1*', 'Brickbox2t2*', ...
        'GrassSky0*', 'GrassSky1*', 'GrassSky2*', 'GrassSky3*', 'GrassSky4*', 'GrassSky5*', 'GrassSky6*', 'GrassSky7*', ...
        'GrassSky8*', 'GrassSky9*', 'Crates1deg1LTxtr*', 'Crates1deg4LTxtr*', 'Crates1deg7LTxtr*', 'Crates1deg1HTxtr1*', ...
        'Crates1deg3HTxtr1*', 'Crates1deg7HTxtr1*', 'Crates1deg1HTxtr2*', 'Crates1deg4HTxtr2*', 'Crates1deg7HTxtr2*', ...
        'TxtRMovement*', 'TextLMovement*'};
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('blow%dTxtr1*',x), 1:19, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('blow%dTxtr2*',x), 1:19, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('drop%dTxtr1*',x), 1:9, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('drop%dTxtr2*',x), 1:9, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('roll%dTxtr1*',x), 1:9, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('roll%dTxtr2*',x), 1:9, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('street%dTxtr1*',x), 1:4, 'UniformOutput',false));
    
    
    calc_flows_id = '1529';
    if exist('confidence_epe_ths', 'var') == 0
        confidence_epe_ths = [0.1 0.25 0.5 2 10];
    end
    output_common_id = 'gm_ed_pb_pb_tg_pc';
    output_epe = 2.0;
    
    addpath('main_code');
    
    if exist('results_dir', 'var') == 0
        results_dir = [];
    end
    
    if ~exist(main_out_dir,'dir')
        mkdir(main_out_dir);
    end
    
    cell_flows = { TVL1OF, ...
                   HuberL1OF, ...
                   ClassicNLOF, ...
                   LargeDisplacementOF };
    
    % store the flow algorithms to be used and their ids
    flow_short_types = {};
    for algo_idx = 1:length(cell_flows)
        flow_short_types{end+1} = cell_flows{algo_idx}.OF_SHORT_TYPE;
    end
    
    % get all the testing sequenece numbers
    temp_conf_dir = fullfile(conf_dir, sprintf('FC_%0.2f-%s-%s', ...
        confidence_epe_ths(1), output_common_id, flow_short_types{1}));
    temp = dir(fullfile(temp_conf_dir, sprintf('*_*_%s_prediction.data', ...
        flow_short_types{1})));
    temp = arrayfun(@(x) regexp(x.name, '(\d+)_\d+', 'tokens'), temp, ...
        'UniformOutput',false);
    testing_seq = unique(cellfun(@(x) str2num(x{1}{1}), temp))';
    
    
    % get feature for each flow algo.
    for algo_idx = 1:length(flow_short_types)
        
        % iterate over multiple EPE confidence threshold values
        for seq_id = testing_seq
            close all;
            
            fprintf(1, 'Producing visualizations for sequence %d - %s\n', seq_id, flow_short_types{algo_idx});
            
            figure; pr_ah = axes; hold on;
            makePRCurve(pr_ah, confidence_epe_ths, flow_short_types{algo_idx}, seq_id, output_common_id, conf_dir, seq_names{seq_id});
            out_filename = sprintf('%d_PR_FC-%s-%s', seq_id, output_common_id, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(main_out_dir, out_filename));
            
            figure; roc_ah = axes; hold on;
            makeROCCurve(roc_ah, confidence_epe_ths, flow_short_types{algo_idx}, seq_id, output_common_id, conf_dir, seq_names{seq_id});
            out_filename = sprintf('%d_ROC_FC-%s-%s', seq_id, output_common_id, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(main_out_dir, out_filename));
            
            load(fullfile(data_dir, num2str(seq_id), sprintf('%d_%s_gt.mat', seq_id, calc_flows_id)));
            %%%%%%%%%%%%%%% ADJUST Calcflows %%%%%%%%%%%%%%%%%%
%             [ flow_info.uv_ang_err(:,:,algo_idx) flow_info.uv_epe(:,:,algo_idx) ] = flowAngErrMe(flow_info.uv_gt(:,:,1), flow_info.uv_gt(:,:,2), ...
%                                                                               flow_info.uv_flows(:,:,1,algo_idx), flow_info.uv_gt(:,:,2));
%              [ flow_info.uv_ang_err(:,:,algo_idx) flow_info.uv_epe(:,:,algo_idx) ] = flowAngErrMe(flow_info.uv_gt(:,:,1), flow_info.uv_gt(:,:,2), ...
%                                                                              flow_info.uv_gt(:,:,1), flow_info.uv_flows(:,:,2,algo_idx));
            %%%%%%%%%%%%%%% ADJUST Calcflows fin %%%%%%%%%%%%%%%%%%
            epe_mat = flow_info.uv_epe(:,:,algo_idx);
            figure; avgepe_ah = axes; hold on;
            makeAvgEPECurve(avgepe_ah, epe_mat, flow_info.gt_mask, confidence_epe_ths, flow_short_types{algo_idx}, seq_id, output_common_id, conf_dir, results_dir, output_epe, seq_names{seq_id});
            out_filename = sprintf('%d_AVGEPE_FC-%s-%s', seq_id, output_common_id, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(main_out_dir, out_filename));
            
            figure; epe_ah = axes; hold on;
            makeEPEImage(epe_ah, epe_mat, flow_info.gt_mask, flow_short_types{algo_idx}, seq_names{seq_id});
            out_filename = sprintf('%d_EPE_FC-%s-%s', seq_id, output_common_id, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(main_out_dir, out_filename));
            
            figure; conf_ah = axes; hold on;
            makeConfidenceImage(output_epe, size(epe_mat), conf_ah, flow_short_types{algo_idx}, seq_id, output_common_id, conf_dir, seq_names{seq_id});
            out_filename = sprintf('%d_CONF_%d_FC-%s-%s', seq_id, output_epe*10, output_common_id, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(main_out_dir, out_filename));
        end
    end

end


function makePRCurve(pr_ah, confidence_epe_ths, flow_short_type, seq_id, output_common_id, conf_dir, seq_name)
    box(pr_ah, 'on');
    
    line_styles = {':', '-.', '--', '-', ':', '-.'};
    
    hs = zeros(length(confidence_epe_ths),1);
    clr = [0 0 1; 0 0 1; 0 0 0; 0 0 0; 0 0 0; 0 0 0];
    
    for idx = 1:length(confidence_epe_ths)
        confidence_epe_th = confidence_epe_ths(idx);
        temp_conf_dir = fullfile(conf_dir, sprintf('FC_%0.2f-%s-%s', confidence_epe_th, output_common_id, flow_short_type));

        temp = dir(fullfile(temp_conf_dir, 'result', sprintf('%d_*_rffeatureimp.mat', seq_id)));
        clsfrout_hndlr = load(fullfile(temp_conf_dir, 'result', temp.name));

        recall = clsfrout_hndlr.classifier_output.tpr;
        precision = clsfrout_hndlr.classifier_output.precision;
        thresholds = clsfrout_hndlr.classifier_output.thresholds;

        hs(idx) = plot(pr_ah, recall, precision, 'LineStyle',line_styles{idx}, 'Color',clr(idx,:));

        if ~isempty(precision)
            if find(confidence_epe_th == confidence_epe_ths) == 1
                plot(pr_ah, recall(ismember(thresholds, 0.1:0.1:0.9)), precision(ismember(thresholds, 0.1:0.1:0.9)), 'o', 'Color',clr(idx,:));
                
                axes(pr_ah);
                text(recall(thresholds==0.8)-0.02, precision(thresholds==0.8), '0.8', 'Color',clr(idx,:), 'HorizontalAlignment','right', 'VerticalAlignment','top');
                text(recall(thresholds==0.5)-0.02, precision(thresholds==0.5), '0.5', 'Color',clr(idx,:), 'HorizontalAlignment','right', 'VerticalAlignment','top');
                text(recall(thresholds==0.2)-0.02, precision(thresholds==0.2), '0.2', 'Color',clr(idx,:), 'HorizontalAlignment','right', 'VerticalAlignment','top');
            end
        end

    end
    
    set(pr_ah, 'XLim',[0 1]);%, 'YLim',[0 1]);
    xlabel('Recall');
    ylabel('Precision');
    title(sprintf('PR Curve of %s Flow Confidence - %s', flow_short_type, seq_name));
    
    legend(hs, arrayfun(@(x) sprintf('% 5.2f pixels', x), confidence_epe_ths, 'UniformOutput',false)', 'Location','SouthWest');
    
end


function makeROCCurve(roc_ah, confidence_epe_ths, flow_short_type, seq_id, output_common_id, conf_dir, seq_name)
    box(roc_ah, 'on');
    
    line_styles = {':', '-.', '--', '-', ':', '-.'};
    
    hs = zeros(length(confidence_epe_ths),1);
    clr = [0 0 1; 0 0 1; 0 0 0; 0 0 0; 0 0 0; 0 0 0];

    for idx = 1:length(confidence_epe_ths)
        confidence_epe_th = confidence_epe_ths(idx);
        temp_conf_dir = fullfile(conf_dir, sprintf('FC_%0.2f-%s-%s', confidence_epe_th, output_common_id, flow_short_type));

        temp = dir(fullfile(temp_conf_dir, 'result', sprintf('%d_*_rffeatureimp.mat', seq_id)));
        clsfrout_hndlr = load(fullfile(temp_conf_dir, 'result', temp.name));

        tpr = clsfrout_hndlr.classifier_output.tpr;
        fpr = clsfrout_hndlr.classifier_output.fpr;
        thresholds = clsfrout_hndlr.classifier_output.thresholds;

        hs(idx) = plot(roc_ah, fpr, tpr, 'LineStyle',line_styles{idx}, 'Color',clr(idx,:));

        if ~isempty(fpr)
            if find(confidence_epe_th == confidence_epe_ths) == 1
                plot(roc_ah, fpr(ismember(thresholds, 0.1:0.1:0.9)), tpr(ismember(thresholds, 0.1:0.1:0.9)), 'o', 'Color',clr(idx,:));

                axes(roc_ah);
                text(fpr(thresholds==0.8)+0.02, tpr(thresholds==0.8), '0.8', 'Color',clr(idx,:), 'HorizontalAlignment','left', 'VerticalAlignment','top');
                text(fpr(thresholds==0.5)+0.02, tpr(thresholds==0.5), '0.5', 'Color',clr(idx,:), 'HorizontalAlignment','left', 'VerticalAlignment','top');
                text(fpr(thresholds==0.2)+0.02, tpr(thresholds==0.2), '0.2', 'Color',clr(idx,:), 'HorizontalAlignment','left', 'VerticalAlignment','top');
            end
        end
    end
    
    set(roc_ah, 'XLim',[0 1], 'YLim',[0 1]);
    line([0;1], [0;1], 'Color', [0.7 0.7 0.7], 'LineStyle','--', 'LineWidth', 1.5);     % draw the line of no-discrimination
    xlabel('FPR');
    ylabel('TPR');
    title(sprintf('ROC of %s Flow Confidence - %s', flow_short_type, seq_name));
    
    legend(hs, arrayfun(@(x) sprintf('% 5.2f pixels', x), confidence_epe_ths, 'UniformOutput',false)', 'Location','SouthEast');
end


function makeAvgEPECurve(avgepe_ah, epe_mat, gt_mask, confidence_epe_ths, flow_short_type, seq_id, output_common_id, conf_dir, results_dir, output_epe, seq_name)
    box(avgepe_ah, 'on');
    
    image_sz = size(epe_mat);
    epe_vals = epe_mat(gt_mask);
    
    line_styles = {':', '-.', '--', '-', ':', '-.', '-', '-'};
    
    hs = zeros(length(confidence_epe_ths)+2,1);
    clr = [1 0 0; 0 1 0; 0 0 1; 0 0 0; 0 1 1; 0 0 0; 1 1 0; 1 0 1];
    thresholds = 0:0.001:1;
    
    no_pixels = zeros(1,length(thresholds));
    avg_epe = zeros(1,length(thresholds));
    
    max_conf = -inf(image_sz);
    
    for idx = 1:length(confidence_epe_ths)
        confidence_epe_th = confidence_epe_ths(idx);
        temp_conf_dir = fullfile(conf_dir, sprintf('FC_%0.2f-%s-%s', confidence_epe_th, output_common_id, flow_short_type));
        
        temp = dir(fullfile(temp_conf_dir, sprintf('%d_*_%s_prediction.data', seq_id, flow_short_type)));
        classifier_out = textread(fullfile(temp_conf_dir, temp.name), '%f');
        classifier_out = reshape(classifier_out, image_sz(2), image_sz(1))';   % need the transpose to read correctly
        
        temp_classifier_out = classifier_out(gt_mask);
        
        for idx2 = 1:length(thresholds)
            tmpC1 = temp_classifier_out >= thresholds(idx2);
            
            no_pixels(idx2) = 100*nnz(tmpC1)/length(epe_vals);
            avg_epe(idx2) = mean(epe_vals(tmpC1));
        end
        
        hs(idx) = plot(avgepe_ah, no_pixels, avg_epe, 'LineStyle',line_styles{idx}, 'Color',clr(idx,:));
        
        if ~isempty(no_pixels)
            if find(confidence_epe_th == confidence_epe_ths) == 1
                plot(avgepe_ah, no_pixels(ismember(thresholds, 0.1:0.1:0.9)), avg_epe(ismember(thresholds, 0.1:0.1:0.9)), 'o', 'Color',clr(idx,:));
            
                axes(avgepe_ah);
                text(no_pixels(thresholds==0.8)+2, avg_epe(thresholds==0.8), '0.8', 'Color',clr(idx,:), 'HorizontalAlignment','left', 'VerticalAlignment','top');
                text(no_pixels(thresholds==0.5)+2, avg_epe(thresholds==0.5), '0.5', 'Color',clr(idx,:), 'HorizontalAlignment','left', 'VerticalAlignment','top');
                text(no_pixels(thresholds==0.2)+2, avg_epe(thresholds==0.2), '0.2', 'Color',clr(idx,:), 'HorizontalAlignment','left', 'VerticalAlignment','top');
            end
        end
        
        max_conf(classifier_out > max_conf) = classifier_out(classifier_out > max_conf);
    end
    
    % max_conf EPE value
    temp_classifier_out = max_conf(gt_mask);
    for idx2 = 1:length(thresholds)
        tmpC1 = temp_classifier_out >= thresholds(idx2);

        no_pixels(idx2) = 100*nnz(tmpC1)/length(epe_vals);
        avg_epe(idx2) = mean(epe_vals(tmpC1));
    end

    hs(end-1) = plot(avgepe_ah, no_pixels, avg_epe, 'LineStyle',line_styles{end-1}, 'Color',clr(end-1,:));

    
    % optimal confidence graph
    epe_vals = sort(epe_vals);
    temp_classifier_out = 1 - (epe_vals-min(epe_vals))/(max(epe_vals)-min(epe_vals));
    for idx2 = 1:length(thresholds)
        tmpC1 = temp_classifier_out >= thresholds(idx2);

        no_pixels(idx2) = 100*nnz(tmpC1)/length(epe_vals);
        avg_epe(idx2) = mean(epe_vals(tmpC1));
    end
    
    hs(end) = plot(avgepe_ah, no_pixels, avg_epe, 'LineStyle',line_styles{end}, 'Color',clr(end,:));
    
    set(avgepe_ah, 'XLim',[0 100]);
    xlabel('% Pixels');
    ylabel('Average EPE');
    title(sprintf('Confidence Thresholding for %s Flow - %s', flow_short_type, seq_name));
    
    legend(hs, [arrayfun(@(x) sprintf('% 5.2f pixels', x), confidence_epe_ths, 'UniformOutput',false)'; 'Ours Confd'; 'Opt Confd'], 'Location','NorthWest');
end


function makeEPEImage(epe_ah, epe_mat, gt_mask, flow_short_type, seq_name)
    epe_mat(~gt_mask) = 0;
    imagesc(epe_mat, 'Parent',epe_ah);
    axis(epe_ah, 'ij', 'image', 'off');
    colorbar;
    colormap gray;
    title(sprintf('%s EPE - %s', flow_short_type, seq_name));
end


function makeConfidenceImage(confidence_epe_th, image_sz, conf_ah, flow_short_type, seq_id, output_common_id, conf_dir, seq_name)
    temp_conf_dir = fullfile(conf_dir, sprintf('FC_%0.2f-%s-%s', confidence_epe_th, output_common_id, flow_short_type));

    temp = dir(fullfile(temp_conf_dir, sprintf('%d_*_%s_prediction.data', seq_id, flow_short_type)));
    classifier_out = textread(fullfile(temp_conf_dir, temp.name), '%f');
    classifier_out = reshape(classifier_out, image_sz(2), image_sz(1))';   % need the transpose to read correctly

    imagesc(classifier_out, 'Parent',conf_ah);
    axis(conf_ah, 'ij', 'image', 'off');
    colorbar;
    colormap gray;
    title(sprintf('%s Decision Confidence (Training EPE threshold %.1f pixels) - %s', flow_short_type, confidence_epe_th, seq_name));
end