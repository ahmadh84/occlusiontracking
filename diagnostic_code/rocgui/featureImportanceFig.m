function featureImportanceFig( filepath )
% Plots graph and sets up a custom data tip update function

    feature = [];
    
    busy_h = busydlg('Please wait... Loading ClassifierOutputHandler from file...', 'ROC gui', 'WindowStyle','modal');
    try
        % computation here %
        loaded_vars = load(filepath);
    catch
        delete(busy_h);
        return;
    end
    delete(busy_h);

    temp = fields(loaded_vars);
    classifier_output = loaded_vars.(temp{1});
    assert(isa(classifier_output, 'ClassifierOutputHandler'), 'Callback:InvalidInput', 'The loaded file doesn''t contain ClassifierOutputHandler object');
            
    % return the list of features available in this file
    feature_list = returnFeatureList( classifier_output, 1 );
    
    fig = figure('DockControls','off', 'MenuBar','none', 'NumberTitle','off', 'Name',['Feature Importance: ' filepath], 'Position',[50, 246, 1098, 552]);
    plot(classifier_output.feature_importance);
    h = gca;
    props = get(h);
    hold on;

    feature_divs = [ 0 cumsum(classifier_output.feature_depths) ] + 0.5;
    
    set(h, 'XTick',feature_divs, 'XGrid','on');
    
    % print text for feature types
    for feature_idx = 1:length(feature_divs)-1
        x_axis_1 = feature_divs(feature_idx);
        x_axis_2 = feature_divs(feature_idx+1);
        
        text((x_axis_1+x_axis_2)/2, props.YLim(2)*0.95, classifier_output.feature_types{feature_idx}, ...
            'Color', [0.6 0.6 0.6], 'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end

    title('Importance of individual features as given by Random Forest classifier');
    xlabel('Feature no.');
    ylabel('Feature importance %');
    
    dcm_obj = datacursormode(fig);
    set(dcm_obj, 'Enable','on', 'SnapToDataVertex','on', 'UpdateFcn',@(obj, event_obj) myupdatefcn(obj, event_obj, feature_list));
end


function txt = myupdatefcn(obj, event_obj, feature_list)
    % Customizes text of data tips

    pos = get(event_obj,'Position');
    if pos(1) >= 1 && pos(1) <= length(feature_list)
        txt = [['FEATURE ' num2str(pos(1)) ':'], feature_list{uint32(pos(1))}];
    else
        txt = '';
    end
end
