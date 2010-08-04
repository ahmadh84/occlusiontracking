function [ feature ] = getUserChoiceFeature( filepath )
%GETUSERCHOICEFEATURE Summary of this function goes here
%   Detailed explanation goes here

    feature = [];
    
    busy_h = busydlg('Please wait... Loading ComputeFeatureVectors object from file...', 'ROC gui', 'WindowStyle','modal');
    try
        % computation here %
        loaded_vars = load(filepath);
    catch
        delete(busy_h);
        return;
    end
    delete(busy_h);

    temp = fields(loaded_vars);
    comp_feature_vector = loaded_vars.(temp{1});
    assert(isa(comp_feature_vector, 'ComputeFeatureVectors'), 'Callback:InvalidInput', 'The loaded file doesn''t contain ComputeFeatureVectors object');

    % return the list of features available in this file
    feature_list = returnFeatureList( comp_feature_vector );

    selection_id = listdlg('ListString',feature_list, 'SelectionMode','single', 'ListSize',[500,450], 'Name','Select Feature for overlay', ...
            'PromptString','Select from the list of available features to be used as an overlay:');
    
    if isempty(selection_id)
        return
    end
    
    orig_feature = comp_feature_vector.features(:,selection_id);
    max_ftr = max(orig_feature);
    min_ftr = min(orig_feature);
    orig_feature = reshape(orig_feature, comp_feature_vector.image_sz([2 1]))';
    
    % launch figure to get all the user choices
    [ choices ] = makeChoiceFigure(min_ftr, max_ftr, orig_feature);

    % if the user choose and accepted any options
    if ~isempty(choices)
        [ feature ] = computeFeature( choices );
    end
end


function [ choices ] = makeChoiceFigure(min_ftr, max_ftr, feature)
    choices = struct;
    
    % delete any old figures
    delete(findobj('Tag','ftr_choice_gui'));
    
    fig_size = [200,200,300,550];
    gap = 20;
    
    h0 = figure('MenuBar','none', ...
                'Units','pixels', ...
                'Position',fig_size, ...
                'WindowStyle','modal', ...
                'Resize','off', ...
                'Name','Set options for features', ...
                'NumberTitle','off', ...
                'Tag','ftr_choice_gui');
    
    curr_h = 0;
    
    uicontrol('Parent',h0, ...
              'Style','pushbutton', ...
              'String','OK', ...
              'Position',[fig_size(3)-70-70-gap*2,curr_h+gap,70,25], ...
              'Tag','ftr_choice_ok', ...
              'Callback',@(hObject,eventdata) okbutton_Callback (hObject,eventdata,h0));
          
    uicontrol('Parent',h0, ...
              'Style','pushbutton', ...
              'String','Cancel', ...
              'Position',[fig_size(3)-70-gap,curr_h+gap,70,25], ...
              'Tag','ftr_choice_cancel', ...
              'Callback',@(hObject,eventdata) cancelbutton_Callback (hObject,eventdata,h0));
    
    curr_h = curr_h + gap + 25;
    
    % Create the button group.
    h1 = uibuttongroup('Parent',h0, ...
                       'visible','off', ...
                       'Units','pixels', ...
                       'Position',[gap,curr_h+gap,fig_size(3)-gap*2,70], ...
                       'Tag','ftr_scaling', ...
                       'Title','Feature scaling');
                   
    % Create radio buttons in the button group.
    u0 = uicontrol('Parent',h1, ...
                   'Style','Radio', ...
                   'String','Normal', ...
                   'pos',[gap 15 100 30], ...
                   'Tag','ftr_scaling_normal', ...
                   'HandleVisibility','off');
               
    u1 = uicontrol('Parent',h1, ...
                   'Style','Radio', ...
                   'String','Log', ...
                   'pos',[gap*2+100 15 100 30], ...
                   'Tag','ftr_scaling_log', ...
                   'HandleVisibility','off');

    % Initialize some button group properties. 
    set(h1,'SelectionChangeFcn',@selcscaling);
    set(h1,'SelectedObject',u0);
    set(h1,'Visible','on');
    
    curr_h = curr_h + gap + 70;
    
    % The clipping panel
    h2 = uipanel('Parent',h0, ...
                 'Units','pixels', ...
                 'Position',[gap,curr_h+gap,fig_size(3)-gap*2,100], ...
                 'Tag','ftr_clipping', ...
                 'Title','Clipping (default max/min values)', ...
                 'visible','off');
    
    t0 = uicontrol('Parent',h2, ...
                   'Style','Text', ...
                   'String','Lower bound: ', ...
                   'Position',[gap gap+15+gap 90 15], ...
                   'Tag','ftr_min_txt', ...
                   'HandleVisibility','off');
    
    t0 = uicontrol('Parent',h2, ...
                   'Style','Edit', ...
                   'String',num2str(min_ftr), ...
                   'Position',[gap+90 gap+15+gap 100 15], ...
                   'BackgroundColor',[1 1 1], ...
                   'Tag','ftr_min_edit_txt', ...
                   'Callback',@minclipping, ...
                   'HandleVisibility','off');
    
    t0 = uicontrol('Parent',h2, ...
                   'Style','Text', ...
                   'String','Upper bound: ', ...
                   'Position',[gap gap 90 15], ...
                   'Tag','ftr_max_txt', ...
                   'HandleVisibility','off');
    
    t1 = uicontrol('Parent',h2, ...
                   'Style','Edit', ...
                   'String',num2str(max_ftr), ...
                   'Position',[gap+90 gap 100 15], ...
                   'BackgroundColor',[1 1 1], ...
                   'Tag','ftr_max_edit_txt', ...
                   'Callback',@maxclipping, ...
                   'HandleVisibility','off');
    
    curr_h = curr_h + gap + 100;
    
    c1 = uicontrol('Parent',h0, ...
                   'Style','checkbox', ...
                   'String','Invert Feature: ', ...
                   'Position',[gap curr_h+gap 100 15], ...
                   'BackgroundColor',get(h0,'Color'), ...
                   'Tag','ftr_invert_chkbx', ...
                   'Callback',@invertfeature, ...
                   'HandleVisibility','off');
    
    curr_h = curr_h + gap + 15;
               
    set(h2,'Visible','on');

    a0 = axes('Parent',h0, ...
              'Box', 'on', ...
              'Units','pixels', ...
              'Position',[0,curr_h+gap,fig_size(3),200], ...
              'Tag','ftr_preview_axes', ...
              'XTick', [], ...
              'YTick', [], ...
              'ZTick', []);
    
    curr_h = curr_h + gap + 100;

    user_data.orig_feature = feature;
    user_data.scaling = 0;
    user_data.min_value = min_ftr;
    user_data.max_value = max_ftr;
    user_data.invert = 0;
    user_data.accept = 0;
    setappdata(0,'rocgui_userdata',user_data);
    
    adjustImageOntoAxes(user_data);
    
    try
        uiwait(h0);
    catch
        if ishghandle(h0)
            delete(h0)
        end
    end
    
    choices = getappdata(0, 'rocgui_userdata');
    rmappdata(0, 'rocgui_userdata');
    
    if choices.accept ~= 1
        choices = [];
    end
end


function okbutton_Callback( hObject, eventdata, parent_h )
    user_data = getappdata(0, 'rocgui_userdata');
    user_data.accept = 1;
    setappdata(0, 'rocgui_userdata',user_data);
    
    delete(parent_h);
end


function cancelbutton_Callback( hObject, eventdata, parent_h )
    delete(parent_h);
end


function selcscaling(hObject, eventdata)
    user_data = getappdata(0, 'rocgui_userdata');
    
    if strcmp(get(get(hObject, 'SelectedObject'), 'String'), 'Log')
        user_data.scaling = 1;
    else
        user_data.scaling = 0;
    end
    
    setappdata(0, 'rocgui_userdata',user_data);
    
    adjustImageOntoAxes(user_data);
end


function minclipping(hObject, eventdata)
    user_data = getappdata(0, 'rocgui_userdata');
    
    val = get(hObject, 'String');
    [val status] = str2num(val);
    if status
        user_data.min_value = val;
        setappdata(0, 'rocgui_userdata',user_data);

        adjustImageOntoAxes(user_data);
    else
        uiwait(errordlg('Min clipping value should be numeric', 'Numeric error', 'modal'));
        uicontrol(hObject);
    end
end


function maxclipping(hObject, eventdata)
    user_data = getappdata(0, 'rocgui_userdata');
    
    val = get(hObject, 'String');
    [val status] = str2num(val);
    if status
        user_data.max_value = val;
        setappdata(0, 'rocgui_userdata',user_data);

        adjustImageOntoAxes(user_data);
    else
        uiwait(errordlg('Max clipping value should be numeric', 'Numeric error', 'modal'));
        uicontrol(hObject);
    end
end


function invertfeature(hObject, eventdata)
    user_data = getappdata(0, 'rocgui_userdata');
    
    val = get(hObject, 'Value');
    user_data.invert = val;
    
    setappdata(0, 'rocgui_userdata',user_data);
    adjustImageOntoAxes(user_data);
end


function adjustImageOntoAxes(user_data)
    figure_h = findobj('Tag','ftr_choice_gui');
    
    [ feature ] = computeFeature( user_data );
    
    im_h = findobj('Tag','ftr_preview_axes_im');
    if ~isempty(im_h)
        delete(im_h);
    end
    
    axes_h = findobj('Tag','ftr_preview_axes');
    image(feature*255, 'Parent',axes_h, 'Tag','ftr_preview_axes_im');

    figure;
    image(feature*255);
    pause;
    close;
    
    % set the axes properties
    set(axes_h, 'DataAspectRatio', [1 1 1], 'Box','off', 'XColor',get(figure_h,'Color'), 'YColor',get(figure_h,'Color'), ...
        'Units','pixels', 'Tag','ftr_preview_axes', 'XTick',[], 'YTick',[], 'ZTick',[]);
    
    colormap(axes_h, 'Summer') ;
end


function [ feature ] = computeFeature( user_data )
    feature = user_data.orig_feature;
    
    feature(feature > user_data.max_value) = user_data.max_value;
    feature(feature < user_data.min_value) = user_data.min_value;
    
    if user_data.invert == 1
        feature = (user_data.max_value - feature) + user_data.min_value;
    end
    
    if user_data.scaling == 1
        feature = real(log(feature));
        user_data.min_value = real(log(user_data.min_value));
        user_data.max_value = real(log(user_data.max_value));
    end
    
    % scale to between 0 and 1
    feature = (feature - user_data.min_value)./(user_data.max_value - user_data.min_value);
end
