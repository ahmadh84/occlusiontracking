function testing_reverse_occl_support
%TESTING_REVERSE_OCCL_SUPPORT Summary of this function goes here
%   Detailed explanation goes here

    % oisin + middlebury
    forward_flow_dir = '../../Data/oisin+middlebury';
    reverse_flow_dir = 'H:/oisin+middlebury_reverse';
    forward_results = 'H:/middlebury/features_comparison_tests2/ed_pc_st_stm_tg_av_lv_cs_rc_ra';
    reverse_results = 'H:/middlebury/features_comparison_tests3/ed_pc_st_stm_tg_av_lv_cs_rc_ra_reverse';
    out_dir_f = 'H:/middlebury/features_comparison_tests3/reverse_flow_support/forward';
    out_dir_r = 'H:/middlebury/features_comparison_tests3/reverse_flow_support/backward';
    sequences = [4 5 9 10 11 12 13 14 18 19];

    mkdir(out_dir_f);
    mkdir(out_dir_r);
    
    for scene_id = sequences
        load(fullfile(forward_flow_dir, num2str(scene_id), [num2str(scene_id) '_4518_gt.mat']));
        flow_info_f = flow_info;
        load(fullfile(reverse_flow_dir, num2str(scene_id), [num2str(scene_id) '_4518_nogt.mat']));
        flow_info_r = flow_info;

        % read in predicted file
        classifier_f = textread(fullfile(forward_results, [num2str(scene_id) '_508008_prediction.data']), '%f');
        classifier_f = reshape(classifier_f, size(flow_info_f.uv_flows,2), size(flow_info_f.uv_flows,1))';   % need the transpose to read correctly
        
        % read in predicted file
        classifier_r = textread(fullfile(reverse_results, [num2str(scene_id) '_508008_prediction.data']), '%f');
        classifier_r = reshape(classifier_r, size(flow_info_f.uv_flows,2), size(flow_info_f.uv_flows,1))';   % need the transpose to read correctly
        
        reverseFlowSupportF( classifier_f, classifier_r, flow_info_f, out_dir_f, scene_id );
        reverseFlowSupportR( classifier_f, classifier_r, flow_info_r, flow_info_f, out_dir_r, scene_id );
        close all;
    end
    
    
    % Evaluation
    forward_flow_dir = 'H:/evaluation_data';
    reverse_flow_dir = 'H:/evaluation_data_reverse';
    forward_results = 'H:/middlebury/Final_Tests/other_results';
    reverse_results = 'H:/middlebury/features_comparison_tests3/ed_pc_st_stm_tg_av_lv_cs_rc_ra_evalreverse';
    out_dir_f = 'H:/middlebury/features_comparison_tests3/reverse_flow_support_eval/forward';
    out_dir_r = 'H:/middlebury/features_comparison_tests3/reverse_flow_support_eval/backward';
    sequences = [1 2 13 14];

    mkdir(out_dir_f);
    mkdir(out_dir_r);
    
    for scene_id = sequences
        load(fullfile(forward_flow_dir, num2str(scene_id), [num2str(scene_id) '_4518_nogt.mat']));
        flow_info_f = flow_info;
        load(fullfile(reverse_flow_dir, num2str(scene_id), [num2str(scene_id) '_4518_nogt.mat']));
        flow_info_r = flow_info;

        % read in predicted file
        classifier_f = textread(fullfile(forward_results, [num2str(scene_id) '_508008_prediction.data']), '%f');
        classifier_f = reshape(classifier_f, size(flow_info_f.uv_flows,2), size(flow_info_f.uv_flows,1))';   % need the transpose to read correctly
        
        % read in predicted file
        classifier_r = textread(fullfile(reverse_results, [num2str(scene_id) '_508008_prediction.data']), '%f');
        classifier_r = reshape(classifier_r, size(flow_info_f.uv_flows,2), size(flow_info_f.uv_flows,1))';   % need the transpose to read correctly
        
        reverseFlowSupportF( classifier_f, classifier_r, flow_info_f, out_dir_f, scene_id );
        reverseFlowSupportR( classifier_f, classifier_r, flow_info_r, flow_info_f, out_dir_r, scene_id );
        close all;
    end
    
    
    % Stein
    forward_flow_dir = 'H:/evaluation_data/stein';
    reverse_flow_dir = 'H:/evaluation_data_reverse/stein';
    forward_results = 'H:/middlebury/Final_Tests/stein_results';
    reverse_results = 'H:/middlebury/features_comparison_tests3/ed_pc_st_stm_tg_av_lv_cs_rc_ra_evalreverse/stein';
    out_dir_f = 'H:/middlebury/features_comparison_tests3/reverse_flow_support_stein/forward';
    out_dir_r = 'H:/middlebury/features_comparison_tests3/reverse_flow_support_stein/backward';
    sequences = [1 2 10 15 21 26];

    mkdir(out_dir_f);
    mkdir(out_dir_r);
    
    for scene_id = sequences
        load(fullfile(forward_flow_dir, num2str(scene_id), [num2str(scene_id) '_4518_nogt.mat']));
        flow_info_f = flow_info;
        load(fullfile(reverse_flow_dir, num2str(scene_id), [num2str(scene_id) '_4518_nogt.mat']));
        flow_info_r = flow_info;

        % read in predicted file
        classifier_f = textread(fullfile(forward_results, [num2str(scene_id) '_508008_prediction.data']), '%f');
        classifier_f = reshape(classifier_f, size(flow_info_f.uv_flows,2), size(flow_info_f.uv_flows,1))';   % need the transpose to read correctly
        
        % read in predicted file
        classifier_r = textread(fullfile(reverse_results, [num2str(scene_id) '_508008_prediction.data']), '%f');
        classifier_r = reshape(classifier_r, size(flow_info_f.uv_flows,2), size(flow_info_f.uv_flows,1))';   % need the transpose to read correctly
        
        reverseFlowSupportF( classifier_f, classifier_r, flow_info_f, out_dir_f, scene_id );
        reverseFlowSupportR( classifier_f, classifier_r, flow_info_r, flow_info_f, out_dir_r, scene_id );
        close all;
    end
end


function reverseFlowSupportF( forward_occl, reverse_occl, calc_flow_f, out_dir, scene_id )

    median_flow = computeMedianFlow( calc_flow_f.uv_flows );

    [cols rows] = meshgrid(1:size(calc_flow_f.uv_flows,2), 1:size(calc_flow_f.uv_flows,1));

    % project the second image to the first according to the flow
    reverse_proj = interp2(reverse_occl, ...
        cols + median_flow(:,:,1), ...
        rows + median_flow(:,:,2), 'cubic');
    reverse_proj(isnan(reverse_proj)) = 0;
    
    final_occl = forward_occl .* (1 - reverse_proj);
    
    printPosteriorImage( final_occl, fullfile(out_dir, [num2str(scene_id) '_508008_posterior.png']) );
    printROCCurve( scene_id, calc_flow_f, final_occl, fullfile(out_dir, [num2str(scene_id) '_508008_roc']) );
end


function reverseFlowSupportR( forward_occl, reverse_occl, flow_info_r, calc_flow_f, out_dir, scene_id )

    median_flow = computeMedianFlow( flow_info_r.uv_flows );

    [cols rows] = meshgrid(1:size(flow_info_r.uv_flows,2), 1:size(flow_info_r.uv_flows,1));

    % project the second image to the first according to the flow
    reverse_proj = interp2(reverse_occl, ...
        cols - median_flow(:,:,1), ...
        rows - median_flow(:,:,2), 'cubic');
    reverse_proj(isnan(reverse_proj)) = 0;
    
    final_occl = forward_occl .* (1 - reverse_proj);
    
    printPosteriorImage( final_occl, fullfile(out_dir, [num2str(scene_id) '_508008_posterior.png']) );
    printROCCurve( scene_id, calc_flow_f, final_occl, fullfile(out_dir, [num2str(scene_id) '_508008_roc']) );
end


function printPosteriorImage( classifier_out, posterior_filepath )
    figure, imshow(classifier_out);
    colormap summer;
    set(gcf, 'units', 'pixels', 'position', [100 100 size(classifier_out,2) size(classifier_out,1)], 'paperpositionmode', 'auto');
    set(gca, 'position', [0 0 1 1], 'visible', 'off');

    print('-dpng', '-r0', posterior_filepath);
end


function printROCCurve( scene_id, calc_flows_f, classifier_out, roc_filepath )

    thresholds = 0:0.001:1;
    comp_feat_vec.scene_dir = num2str(scene_id);
    extra_label_info.calc_flows = calc_flows_f;
    label_obj = OcclusionLabel();
    [ labels ignore_labels ] = label_obj.calcLabelWhole( comp_feat_vec, extra_label_info );
            
    if isempty(labels)
        return;
    end

    % remove labels which we are unsure about
    labels(ignore_labels) = [];

    not_labels = ~labels;

    % get the number of positives and negatives
    T = nnz(labels);
    N = nnz(~labels);
    
    fpr = zeros(length(thresholds),1);
    tpr = zeros(length(thresholds),1);

    temp_classifier_out = classifier_out';
    temp_classifier_out = temp_classifier_out(:);

    % remove classifier output which we are unsure about
    temp_classifier_out(ignore_labels) = [];

    for idx = 1:length(thresholds)
        tmpC1 = temp_classifier_out >= thresholds(idx);

        % compute the True/False Positive, True/False Negative
        tp = nnz( tmpC1 & labels );
        fn = T - tp;
        fp = nnz( tmpC1 & not_labels );
        tn = N - fp;

        fpr(idx) = fp / (fp+tn);
        tpr(idx) = tp / (tp+fn);
    end

    % compute the area under the curve
    area_under_roc = sum((fpr(1:end-1)-fpr(2:end)).*((tpr(1:end-1) + tpr(2:end)).*0.5));

    % print to new figure
    figure
    plot(fpr, tpr);
    hold on;

    if ~isempty(fpr)
        for i=0.1:0.1:0.9
            plot(fpr(thresholds==i), tpr(thresholds==i), 'bo');
        end

        text(fpr(thresholds==0.8)+0.02, tpr(thresholds==0.8), '0.8', 'Color',[0 0 1]);
        text(fpr(thresholds==0.5)+0.02, tpr(thresholds==0.5), '0.5', 'Color',[0 0 1]);
        text(fpr(thresholds==0.2)+0.02, tpr(thresholds==0.2), '0.2', 'Color',[0 0 1]);
    end

    title(sprintf('ROC of Occlusion Region detection - Area under ROC %.4f', area_under_roc));
    line([0;1], [0;1], 'Color', [0.7 0.7 0.7], 'LineStyle','--', 'LineWidth', 1.5);     % draw the line of no-discrimination

    xlabel('FPR');
    ylabel('TPR');
    print('-depsc', '-r0', roc_filepath);
end


function median_flow = computeMedianFlow( uv_flow )

    % get the median flow (make 2 dim matrix - quicker! :s)
    sz_temp = size(uv_flow);
    uv_flow = reshape(uv_flow, [sz_temp(1)*sz_temp(2)*sz_temp(3) sz_temp(4)]);
    median_flow = median(uv_flow, 2);
    median_flow = reshape(median_flow, [sz_temp(1) sz_temp(2) sz_temp(3)]);
end