function graph_imp(feature_imp_graph, imp_filepath)

    close all;
    
    load(feature_imp_graph);
    
    printRFFeatureImpWithTimes( classifier_output, imp_filepath );
end


function printRFFeatureImpWithTimes( classifier_output, imp_filepath )

    feature_divs = [ 0 cumsum(classifier_output.feature_depths) ] + 0.5;
    
    figure;
    
    x_temp = feature_divs(1:end-1) + ((feature_divs(2:end) - feature_divs(1:end-1))/2);
    flow_x = (max(feature_divs) * 0.09);
    flow_x = fliplr(-[flow_x/2:flow_x:flow_x*length(classifier_output.flow_compute_times)-flow_x/2  flow_x*length(classifier_output.flow_compute_times)+flow_x/2]);
    
    clf_time_idx = strcmp(classifier_output.extra_compute_times(:,1), 'classifier_compute_time');
    
    [AX,H1,H2] = plotyy([flow_x x_temp], [classifier_output.extra_compute_times{clf_time_idx,2} classifier_output.flow_compute_times classifier_output.feature_compute_times], ...
            1:length(classifier_output.feature_importance), classifier_output.feature_importance, ...
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
    if ~strcmp(imp_filepath, '')
        print('-depsc', '-r0', imp_filepath);
    end
end