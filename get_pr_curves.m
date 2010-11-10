function [ output_args ] = get_pr_curves( input_args )
%GET_PR_CURVES Summary of this function goes here
%   Detailed explanation goes here
    
    close all;
    
    flow_class_id = '3058';
    main_dir = 'D:\ahumayun\Data\oisin+middlebury';
    out_dir = 'D:\ahumayun\Results\features_comparison_tests5\FINAL-ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp';
    output_prs(main_dir, out_dir, flow_class_id);
end


function output_prs(main_dir, out_dir, flow_class_id)
    thresholds = 0:0.001:1;
    
    d = dir(out_dir);
    filenames = {d.name};
    files = regexp(filenames, '(\d+)_(\d+)_prediction.data', 'tokens');
    filenames = filenames(~cellfun(@isempty, files));
    files = files(~cellfun(@isempty, files));
    
    for idx = 1:length(files)
        seq_no = files{idx}{1}{1};
        clsfr_id = files{idx}{1}{2};
        calc_flow_filepath = fullfile(main_dir, seq_no, [seq_no '_' flow_class_id '_gt.mat']);
        if exist(calc_flow_filepath, 'file') == 0
            continue;
        end
        fprintf('Computing PR for %s\n', seq_no);
        load(calc_flow_filepath);

        classifier_out = textread(fullfile(out_dir, filenames{idx}), '%f');
        classifier_out = reshape(classifier_out, size(flow_info.gt_mask,2), size(flow_info.gt_mask,1))';   % need the transpose to read correctly
        
        mask = flow_info.gt_mask;
        labels = (mask == 0)';
        labels = labels(:);

        % inform user about the labels they should ignore
        if ~isempty(flow_info.gt_ignore_mask)
            fprintf(1, 'IGNORING labelling of %d/%d pixels for %s\n', nnz(flow_info.gt_ignore_mask), numel(flow_info.gt_ignore_mask), flow_info.scene_dir);

            ignore_labels = flow_info.gt_ignore_mask';
            ignore_labels = ignore_labels(:);
        else
            ignore_labels = false(size(labels));
        end
            
        [recall precision] = computeCurve(labels, ignore_labels, thresholds, classifier_out);
        
        figure
        plot(recall, precision);
        hold on;

        xlim([0 1]);
        ylim([0 1]);
        if ~isempty(precision)
            for i=0.1:0.1:0.9
                plot(recall(thresholds==i), precision(thresholds==i), 'bo');
            end

            text(recall(thresholds==0.8)+0.02, precision(thresholds==0.8), '0.8', 'Color',[0 0 1]);
            text(recall(thresholds==0.5)+0.02, precision(thresholds==0.5), '0.5', 'Color',[0 0 1]);
            text(recall(thresholds==0.2)+0.02, precision(thresholds==0.2), '0.2', 'Color',[0 0 1]);
        end

%         line([0;1], [1;0], 'Color', [0.7 0.7 0.7], 'LineStyle','--', 'LineWidth', 1.5);     % draw the line of no-discrimination

        xlabel('Recall');
        ylabel('Precision');
        print('-depsc', '-r0', fullfile(out_dir, 'result', [seq_no '_' clsfr_id '_pr.eps']));
        
        close;
    end
    
end


function [recall precision] = computeCurve(labels, ignore_labels, thresholds, classifier_out)
    % remove labels which we are unsure about
    labels(ignore_labels) = [];

    not_labels = ~labels;

    % get the number of positives and negatives
    T = nnz(labels);
    N = nnz(~labels);

    precision = zeros(length(thresholds),1);
    recall = zeros(length(thresholds),1);

    temp_classifier_out = classifier_out';
    temp_classifier_out = temp_classifier_out(:);

    % remove classifier output which we are unsure about
    temp_classifier_out(ignore_labels) = [];

    for idx = 1:length(thresholds)
        tmpC1 = temp_classifier_out >= thresholds(idx);
%                 tmpE1 = ((epe.*tmpC1)<errorToTest);

%                 tmpC2 = ~tmpC1;
%                 tmpE2 = ((epe.*tmpC2)>=errorToTest);

        % compute the True/False Positive, True/False Negative
        tp = nnz( tmpC1 & labels );
        fn = T - tp;
        fp = nnz( tmpC1 & not_labels );
        tn = N - fp;

        precision(idx) = tp / (tp+fp);
        recall(idx) = tp / (tp+fn);
    end
end
