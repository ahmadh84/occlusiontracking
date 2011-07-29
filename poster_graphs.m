function [ output_args ] = poster_graphs( input_args )
%POSTER_GRAPHS Summary of this function goes here
%   Detailed explanation goes here
    
    close all;
    run(fullfile('main_code/algorithms/vlfeat-0.9.9/toolbox/vl_setup'));
    addpath('main_code');
    addpath('main_code\algorithms\sparse-occlusion-detection');
    addpath('main_code\algorithms\sparse-occlusion-detection\utils');
    
    seq_nos = [9 10 17 18 19 22 24 26 29 30 39 49 50];
    
    flow_class_id = '1529';
    out_dir = 'C:\Users\Ahmad\Documents\UCL\MS Thesis - Learning Occlusion Regions\Presentations\CVPR_Poster_11\images\Quantitative';
    calc_flow_path = 'E:\Data\oisin+middlebury';
    lean_dir = 'E:\Results\features_comparison_tests7\LEAN1-ed_pc_tg_av_lv_cs-max_rc_ra_fa_fn';
    full_dir = 'E:\Results\features_comparison_tests7\FINAL-ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp';
    
    
    for seq = seq_nos
        fprintf(1, 'Getting PRs for seq %d\n', seq);
        
        figure
        hold on;
        box on;
        xlim([0 1]);
        ylim([0 1]);

        % load the flow file
        d = dir(fullfile(calc_flow_path, num2str(seq), sprintf('%d_%s_gt.mat', seq, flow_class_id)));
        assert(length(d) == 1, 'Can''t find CalcFlows file');
        load(fullfile(calc_flow_path, num2str(seq), d(1).name));

        h = zeros(5,1);

%         h(1) = kolmogorovPoint(seq, calc_flow_path, flow_info, 0);
        
        % get NIP'10 CGT PR's 
        h(1) = occlConvexPlotPR(seq, calc_flow_path, flow_info, 1, 'k:', 0, 'k', 'ks:');
        
        % get NIP'10 FGT PR's 
        h(2) = occlConvexPlotPR(seq, calc_flow_path, flow_info, 0, 'k-.', 0, 'k', 'ko-.');
        
        % get CGT PR
        h(3) = cgtLoadAndPlotPR(full_dir, seq, calc_flow_path, flow_info, 'b-.', 0, 'r', 'bs-.');
        
        % get lean PR's
        h(4) = loadAndPlotPR(lean_dir, seq, flow_info, 'm--', 0, 'm', 'md--');
        
        % get full PR's
        h(5) = loadAndPlotPR(full_dir, seq, flow_info, 'b-', 1, 'b', 'bo-');

%         legend(h, '[2] sparse e_1 CGT', '[2] sparse e_1 FGT', 'Ours CGT', 'Lean FGT', 'Ours FGT', 'Location','NorthWest');
        xlabel('Recall', 'fontsize',12,'fontweight','b');
        ylabel('Precision', 'fontsize',12,'fontweight','b');
        print('-depsc', '-r0', fullfile(out_dir, [num2str(seq) '_pr.eps']));
        
        close;
    end
end


function h = kolmogorovPoint(seq, calc_flow_path, flow_info, cgt_or_not)

    im1 = imread(fullfile(calc_flow_path, num2str(seq), ComputeTrainTestData.IM1_PNG));
    im2 = imread(fullfile(calc_flow_path, num2str(seq), ComputeTrainTestData.IM2_PNG));
    
    curr_path = pwd;
    curr_path_im1 = fullfile(curr_path, 'temp_1_delete_if_found.ppm');
    curr_path_im2 = fullfile(curr_path, 'temp_2_delete_if_found.ppm');

    % create pgm files (the exe only works on pgm files)
    imwrite(im1, curr_path_im1);
    imwrite(im2, curr_path_im2);

    % move to executable files dir, execute and read flow file
    status = 3;
    while status ~= 1
        cd('main_code/algorithms/kolmogCompar/bin');
        [status, result] = system('match kz2_ahmad.txt');
    end

    % return to original path and delete the temp. pgm images
    cd(curr_path);
    delete(curr_path_im1);
    delete(curr_path_im2);        
end


function h = occlConvexPlotPR(seq, calc_flow_path, flow_info, cgt_or_not, line_style, draw_nos, text_color, marker_style)

    occlconvex = load(fullfile(calc_flow_path, num2str(seq), 'occlconvex.mat'));
    
    im1 = imread(fullfile(calc_flow_path, num2str(seq), ComputeTrainTestData.IM1_PNG));
    im2 = imread(fullfile(calc_flow_path, num2str(seq), ComputeTrainTestData.IM2_PNG));
    
    if ~isfield(occlconvex, 'uv_oc_e') || ~isfield(occlconvex, 'uv_oc_ebar')
        [ uv_oc e ebar ] = estimate_flow_L2_rwL1_wTV_nesterov(im1, im2);
        occlconvex.uv_oc_e = e;
        occlconvex.uv_oc_ebar = ebar;
        save(fullfile(calc_flow_path, num2str(seq), 'occlconvex.mat'), '-struct', 'occlconvex')
    end
    
    % annotates regions that are warped out of the borders as occluded
    occl = abs(occlconvex.uv_oc_ebar);
    occl(occl > 1) = 1;
    
    if ~cgt_or_not
        res = compute_residual(double(rgb2gray(im1))/255, double(rgb2gray(im2))/255, occlconvex.uv_oc); 
        occl(isnan(res)) = 1;
        imwrite(occl, sprintf('%d.png',seq));
    else
        assert(exist(fullfile(calc_flow_path, num2str(seq), 'cgt.png'), 'file') == 2, 'CGT png image not found');
        cgt = imread(fullfile(calc_flow_path, num2str(seq), 'cgt.png'));
        temp = flow_info.gt_ignore_mask;
        flow_info.gt_ignore_mask = logical(cgt);
    end

    thresholds = 0:0.001:1;
    [ precision tpr ] = getPrecisionRecall(flow_info, occl, thresholds);
    
    h = plotPR(precision, tpr, thresholds, line_style, draw_nos, text_color, marker_style);
    
    if cgt_or_not
        flow_info.gt_ignore_mask = temp;
    end
end


function h = cgtLoadAndPlotPR(load_dir, seq, calc_flow_path, flow_info, line_style, draw_nos, text_color, marker_style)

    d = dir(fullfile(load_dir, 'result', sprintf('%d_*_rffeatureimp.mat', seq)));
    assert(length(d) == 1, 'ClassifierOutput file not found');
    load(fullfile(load_dir, 'result', d(1).name));
    
    d = dir(fullfile(load_dir, sprintf('%d_*_prediction.data', seq)));
    assert(length(d) == 1, 'Can''t find Prediction file');
    classifier_out = textread(fullfile(load_dir, d(1).name), '%f');
    classifier_out = reshape(classifier_out, size(flow_info.gt_mask,2), size(flow_info.gt_mask,1))';   % need the transpose to read correctly
    
    assert(exist(fullfile(calc_flow_path, num2str(seq), 'cgt.png'), 'file') == 2, 'CGT png image not found');
    cgt = imread(fullfile(calc_flow_path, num2str(seq), 'cgt.png'));
    temp = flow_info.gt_ignore_mask;
    flow_info.gt_ignore_mask = logical(cgt);
    
    [ precision recall ] = getPrecisionRecall(flow_info, classifier_out, classifier_output.thresholds);
    classifier_output.precision = precision;
    classifier_output.tpr = recall;
    
    h = plotPR(classifier_output.precision, classifier_output.tpr, classifier_output.thresholds, line_style, draw_nos, text_color, marker_style);
    
    flow_info.gt_ignore_mask = temp;
end


function h = loadAndPlotPR(load_dir, seq, flow_info, line_style, draw_nos, text_color, marker_style)

    d = dir(fullfile(load_dir, 'result', sprintf('%d_*_rffeatureimp.mat', seq)));
    assert(length(d) == 1, 'ClassifierOutput file not found');
    load(fullfile(load_dir, 'result', d(1).name));
    
    if isempty(classifier_output.precision)
        d = dir(fullfile(load_dir, sprintf('%d_*_prediction.data', seq)));
        assert(length(d) == 1, 'Can''t find Prediction file');
        classifier_out = textread(fullfile(load_dir, d(1).name), '%f');
        classifier_out = reshape(classifier_out, size(flow_info.gt_mask,2), size(flow_info.gt_mask,1))';   % need the transpose to read correctly

        [ precision ] = getPrecisionRecall(flow_info, classifier_out, classifier_output.thresholds);
        classifier_output.precision = precision;
        save(fullfile(load_dir, 'result', d(1).name), 'classifier_output');
    end

    h = plotPR(classifier_output.precision, classifier_output.tpr, classifier_output.thresholds, line_style, draw_nos, text_color, marker_style);
end


function [ h ] = plotPR(precision, recall, thresholds, line_style, draw_nos, text_color, marker_style)
    plot(recall, precision, line_style, 'LineWidth',2);

    for i=0.1:0.1:0.9
        h = plot(recall(thresholds==i), precision(thresholds==i), marker_style);
    end
    
    if draw_nos
        text(recall(thresholds==0.8)+0.02, precision(thresholds==0.8)+0.02, '0.8', 'Color',text_color);
        text(recall(thresholds==0.5)+0.02, precision(thresholds==0.5)+0.02, '0.5', 'Color',text_color);
        text(recall(thresholds==0.2)+0.02, precision(thresholds==0.2)+0.02, '0.2', 'Color',text_color);
    end
end


function [precision recall] = getPrecisionRecall(flow_info, classifier_out, thresholds)
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
end


function [recall precision fpr] = computeCurve(labels, ignore_labels, thresholds, classifier_out)
    % remove labels which we are unsure about
    labels(ignore_labels) = [];

    not_labels = ~labels;

    % get the number of positives and negatives
    T = nnz(labels);
    N = nnz(~labels);

    precision = zeros(length(thresholds),1);
    recall = zeros(length(thresholds),1);
    fpr = zeros(length(thresholds),1);
    
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
        precision(idx) = tp / (tp+fp);
        recall(idx) = tp / (tp+fn);
    end
    
    precision(isnan(precision)) = 1;
end



function [residual, Iwarped] = compute_residual(I0, I1, w)
% 	COMPUTE_RESIDUAL  
% 		[RESIDUAL] = COMPUTE_RESIDUAL(I0, I1, W)
% 
% 	

	[M, N, D] = size(I0);
	[x,y] = meshgrid(1:N,1:M); 
	
	I0 = double(I0); I1 = double(I1);

	Iwarped = zeros(size(I0));
	for k = 1:D
		Iwarped(:,:,k) = interp2(I1(:,:,k), x+w(:,:,1), y+w(:,:,2));
	end
	
	res = I0 - Iwarped;
	residual = sqrt(sum(res.^2, 3)); 
	
end %  function