function [ output_args ] = compare_lean_features( input_args )
%COMPARE_LEAN_FEATURES Summary of this function goes here
%   Detailed explanation goes here
    
    d = 'H:\middlebury\features_comparison_tests5\FINAL-ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp\result\';
    
    files = dir(fullfile(d, '*_rffeatureimp.mat'));
    files = {files.name};

    compute_times = [];
    feature_importance = [];
    extra_compute_times = {};
    flow_compute_times = [];
    
    for idx = 1:length(files)
        load(fullfile(d, files{idx}));
        compute_times = [compute_times; classifier_output.feature_compute_times];
        feature_importance = [feature_importance; classifier_output.feature_importance'];
        flow_compute_times = [flow_compute_times; classifier_output.flow_compute_times];
        if isempty(extra_compute_times)
            extra_compute_times = classifier_output.extra_compute_times;
        else
            extra_compute_times(:,2) = arrayfun(@(idx) [extra_compute_times{idx,2} classifier_output.extra_compute_times{idx,2}], 1:size(extra_compute_times,1), 'UniformOutput',false)';
        end
    end
    
    feature_types = classifier_output.feature_types;
    compute_times = mean(compute_times, 1);
    flow_compute_times = mean(flow_compute_times, 1);
    feature_importance = mean(feature_importance,1);
    
    extra_compute_times(:,2) = cellfun(@(x) mean(x), extra_compute_times(:,2), 'UniformOutput',false);
    
    printRFFeatureImp( classifier_output, feature_importance, compute_times, flow_compute_times, extra_compute_times );
end



function printRFFeatureImp( classifier_output, feature_importance, feature_compute_times, flow_compute_times, extra_compute_times )

    feature_divs = [ 0 cumsum(classifier_output.feature_depths) ] + 0.5;
    
    figure;
    
    x_temp = feature_divs(1:end-1) + ((feature_divs(2:end) - feature_divs(1:end-1))/2);
    flow_x = (max(feature_divs) * 0.09);
    flow_x = fliplr(-[flow_x/2:flow_x:flow_x*length(flow_compute_times)-flow_x/2  flow_x*length(flow_compute_times)+flow_x/2]);
    
    clf_time_idx = strcmp(classifier_output.extra_compute_times(:,1), 'classifier_compute_time');
    
    [AX,H1,H2] = plotyy([flow_x x_temp], [extra_compute_times{clf_time_idx,2} flow_compute_times feature_compute_times], ...
            1:length(feature_importance), feature_importance, ...
            'bar', 'plot');
    
    xlim(AX(1), [floor(flow_x(1)+2*flow_x(end)) ceil(2*x_temp(1)+x_temp(end))]);
    xlim(AX(2), [floor(flow_x(1)+2*flow_x(end)) ceil(2*x_temp(1)+x_temp(end))]);
    
    h = get(AX(1));
    hold on;

    for feature_idx = 1:length(feature_divs)-1
        x_axis_1 = feature_divs(feature_idx);
        x_axis_2 = feature_divs(feature_idx+1);

        plot([x_axis_2; x_axis_2], [0; h.YLim(2)], 'Color', [0.6 0.6 0.6], 'LineStyle','--');
        text((x_axis_1+x_axis_2)/2, h.YLim(2)*0.95, classifier_output.feature_types{feature_idx}, ...
            'Color', [0.6 0.6 0.6], 'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
    plot([0; 0], [0; h.YLim(2)], 'Color', [0 0 0], 'LineStyle','-');
    hold off;
    
    title('Importance of individual features as given by Random Forest classifier');
    xlabel('Feature no.');
    
    set(get(AX(1),'Ylabel'),'String','Computation time (s)');
    set(get(AX(2),'Ylabel'),'String','Feature importance %');

    set(H1, 'FaceColor', [0.7 0.7 0.7]);
    set(H1, 'EdgeColor', [0.4 0.4 0.4]);
    
    x_tickers = get(gca, 'XTick');
    x_tickers(x_tickers < 0) = [];
    x_tickers = [flow_x x_tickers];
    set(AX(1), 'XTick', x_tickers);
    set(AX(2), 'XTick', x_tickers);
    temp = get(gca, 'XTickLabel');
    temp = mat2cell(temp, ones(1,size(temp,1)), size(temp,2));
    if length(classifier_output.flow_compute_times) == 4
        temp(1:5) = {'clsfr', 'TV','FL','CN','LD'};
    elseif length(classifier_output.flow_compute_times) == 6
        temp(1:7) = {'clsfr', 'BA','TV','HS','FL','CN','LD'};
    end
    temp = cellfun(@strtrim, temp, 'UniformOutput', false);
    set(AX(2), 'XTickLabel', repmat({''}, [size(temp,1),1]));
    set(AX(1), 'XTickLabel', temp);
    set(AX(1), 'FontSize', 8);
    
    set(gcf, 'Position', [100 100 950 450]);
    
%     imp_filepath = classifier_output.getRFFeatureFilename();
%     if ~strcmp(imp_filepath, '')
%         print('-depsc', '-r0', imp_filepath);
%     end
end