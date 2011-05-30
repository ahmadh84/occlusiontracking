function combine_confidence_graphs
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

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
    
    
    out_dir = 'E:/Results/oisin+results_flowconfidence2';
    data_dir = 'E:/Data/oisin+middlebury';
    calc_flows_id = '1529';
    
    addpath('main_code');
    
    confidence_epe_ths = [0.1 0.25 0.5 1 2 10];
    output_epe = 1;
    testing_seq = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 22 24 26 29 30 39 49 50 51 88 89 106 107 124 125];
    
    cell_flows = { TVL1OF, ...
                   HuberL1OF, ...
                   ClassicNLOF, ...
                   LargeDisplacementOF };
    
    % store the flow algorithms to be used and their ids
    flow_short_types = {};
    for algo_idx = 1:length(cell_flows)
        flow_short_types{end+1} = cell_flows{algo_idx}.OF_SHORT_TYPE;
    end
    
    % get feature for each flow algo.
    for algo_idx = 1:length(flow_short_types)
        
        % iterate over multiple EPE confidence threshold values
        for seq_id = testing_seq
            close all;
            
            figure; pr_ah = axes; hold on;
            makePRCurve(pr_ah, confidence_epe_ths, flow_short_types{algo_idx}, seq_id, out_dir, seq_names{seq_id});
            out_filename = sprintf('%d_PR_FC-gm_ed_tg_pc-%s', seq_id, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(out_dir, 'combined', out_filename));
            
            figure; roc_ah = axes; hold on;
            makeROCCurve(roc_ah, confidence_epe_ths, flow_short_types{algo_idx}, seq_id, out_dir, seq_names{seq_id});
            out_filename = sprintf('%d_ROC_FC-gm_ed_tg_pc-%s', seq_id, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(out_dir, 'combined', out_filename));
            
            load(fullfile(data_dir, num2str(seq_id), sprintf('%d_%s_gt.mat', seq_id, calc_flows_id)));
            epe_mat = flow_info.uv_epe(:,:,algo_idx);
            figure; avgepe_ah = axes; hold on;
            makeAvgEPECurve(avgepe_ah, epe_mat, flow_info.gt_mask, confidence_epe_ths, flow_short_types{algo_idx}, seq_id, out_dir, seq_names{seq_id});
            out_filename = sprintf('%d_AVGEPE_FC-gm_ed_tg_pc-%s', seq_id, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(out_dir, 'combined', out_filename));
            
            figure; epe_ah = axes; hold on;
            makeEPEImage(epe_ah, epe_mat, flow_info.gt_mask, flow_short_types{algo_idx}, seq_names{seq_id});
            out_filename = sprintf('%d_EPE_FC-gm_ed_tg_pc-%s', seq_id, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(out_dir, 'combined', out_filename));
            
            figure; conf_ah = axes; hold on;
            makeConfidenceImage(output_epe, size(epe_mat), conf_ah, flow_short_types{algo_idx}, seq_id, out_dir, seq_names{seq_id});
            out_filename = sprintf('%d_CONF_%d_FC-gm_ed_tg_pc-%s.eps', seq_id, output_epe*10, flow_short_types{algo_idx});
            print('-depsc', '-r0', fullfile(out_dir, 'combined', out_filename));
        end
    end

end


function makePRCurve(pr_ah, confidence_epe_ths, flow_short_type, seq_id, out_dir, seq_name)
    box(pr_ah, 'on');
    
    line_styles = {':', '-.', '--', '-', ':', '-.'};
    
    hs = zeros(length(confidence_epe_ths),1);
    clr = [0 0 1; 0 0 1; 0 0 0; 0 0 0; 0 0 0; 0 0 0];
    
    for idx = 1:length(confidence_epe_ths)
        confidence_epe_th = confidence_epe_ths(idx);
        temp_out_dir = fullfile(out_dir, sprintf('FC_%0.2f-gm_ed_tg_pc-%s', confidence_epe_th, flow_short_type));

        temp = dir(fullfile(temp_out_dir, 'result', sprintf('%d_*_rffeatureimp.mat', seq_id)));
        clsfrout_hndlr = load(fullfile(temp_out_dir, 'result', temp.name));

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
    
    legend(hs, arrayfun(@(x) sprintf('% 5.1f pixels', x), confidence_epe_ths, 'UniformOutput',false)', 'Location','SouthWest');
    
end


function makeROCCurve(roc_ah, confidence_epe_ths, flow_short_type, seq_id, out_dir, seq_name)
    box(roc_ah, 'on');
    
    line_styles = {':', '-.', '--', '-', ':', '-.'};
    
    hs = zeros(length(confidence_epe_ths),1);
    clr = [0 0 1; 0 0 1; 0 0 0; 0 0 0; 0 0 0; 0 0 0];

    for idx = 1:length(confidence_epe_ths)
        confidence_epe_th = confidence_epe_ths(idx);
        temp_out_dir = fullfile(out_dir, sprintf('FC_%0.2f-gm_ed_tg_pc-%s', confidence_epe_th, flow_short_type));

        temp = dir(fullfile(temp_out_dir, 'result', sprintf('%d_*_rffeatureimp.mat', seq_id)));
        clsfrout_hndlr = load(fullfile(temp_out_dir, 'result', temp.name));

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
    
    legend(hs, arrayfun(@(x) sprintf('% 5.1f pixels', x), confidence_epe_ths, 'UniformOutput',false)', 'Location','SouthEast');
end


function makeAvgEPECurve(avgepe_ah, epe_mat, gt_mask, confidence_epe_ths, flow_short_type, seq_id, out_dir, seq_name)
    box(avgepe_ah, 'on');
    
    image_sz = size(epe_mat);
    epe_vals = epe_mat(gt_mask);
    
    line_styles = {':', '-.', '--', '-', ':', '-.'};
    
    hs = zeros(length(confidence_epe_ths),1);
    clr = [0 0 1; 0 0 1; 0 0 0; 0 0 0; 0 0 0; 0 0 0];
    thresholds = 0:0.001:1;
    
    no_pixels = zeros(1,length(thresholds));
    avg_epe = zeros(1,length(thresholds));
    
    for idx = 1:length(confidence_epe_ths)
        confidence_epe_th = confidence_epe_ths(idx);
        temp_out_dir = fullfile(out_dir, sprintf('FC_%0.2f-gm_ed_tg_pc-%s', confidence_epe_th, flow_short_type));
        
        temp = dir(fullfile(temp_out_dir, sprintf('%d_*_%s_prediction.data', seq_id, flow_short_type)));
        classifier_out = textread(fullfile(temp_out_dir, temp.name), '%f');
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
    end
    
    set(avgepe_ah, 'XLim',[0 100]);
    xlabel('% Pixels');
    ylabel('Average EPE');
    title(sprintf('Confidence Thresholding for %s Flow - %s', flow_short_type, seq_name));
    
    legend(hs, arrayfun(@(x) sprintf('% 5.1f pixels', x), confidence_epe_ths, 'UniformOutput',false)', 'Location','NorthWest');
end


function makeEPEImage(epe_ah, epe_mat, gt_mask, flow_short_type, seq_name)
    epe_mat(~gt_mask) = 0;
    imagesc(epe_mat, 'Parent',epe_ah);
    axis(epe_ah, 'ij', 'image', 'off');
    colorbar;
    colormap gray;
    title(sprintf('%s EPE - %s', flow_short_type, seq_name));
end


function makeConfidenceImage(confidence_epe_th, image_sz, conf_ah, flow_short_type, seq_id, out_dir, seq_name)
    temp_out_dir = fullfile(out_dir, sprintf('FC_%0.2f-gm_ed_tg_pc-%s', confidence_epe_th, flow_short_type));

    temp = dir(fullfile(temp_out_dir, sprintf('%d_*_%s_prediction.data', seq_id, flow_short_type)));
    classifier_out = textread(fullfile(temp_out_dir, temp.name), '%f');
    classifier_out = reshape(classifier_out, image_sz(2), image_sz(1))';   % need the transpose to read correctly

    imagesc(classifier_out, 'Parent',conf_ah);
    axis(conf_ah, 'ij', 'image', 'off');
    colorbar;
    colormap gray;
    title(sprintf('%s Decision Confidence (Training EPE threshold %.1f pixels) - %s', flow_short_type, confidence_epe_th, seq_name));
end