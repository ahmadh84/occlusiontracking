function [ varargout ] = menuCallbacks( varargin )
% evaluate function according to the number of inputs and outputs
if nargout(varargin{1}) > 0
    [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
else
    feval(varargin{:});
end


% --- Executes during axes number is tried to be changed from the menu
function menu_axes_num_Callback(hObject, eventdata, handles, no_axes)
% hObject    handle to menu_axes_X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = adjustGUIandAxeses(gcf, no_axes, handles);

% initialize the user image data
handles = globalDataUtils('reInitImageData', handles);

% Update handles structure
guidata(gcf, handles);


function menu_load_directory_Callback(hObject, eventdata, handles)

not_done = 1;
msg_prefix = '[unknown action]';

while not_done
    try
        % check if it has all the necessary files are there and readable
        msg_prefix = ['choosing directory'];
        folder_name = uigetdir(handles.user_data.curr_dir, 'Select Directory for the input images and GT flow');
        
        if isscalar(folder_name) && folder_name == 0
            return;
        end
        
        msg_prefix = ['reading ' ComputeTrainTestData.IM1_PNG];
        i1 = im2double(imread(fullfile(folder_name, ComputeTrainTestData.IM1_PNG)));
        msg_prefix = ['reading ' ComputeTrainTestData.IM2_PNG];
        i2 = im2double(imread(fullfile(folder_name, ComputeTrainTestData.IM2_PNG)));

        msg_prefix = ['reading ' ComputeTrainTestData.IM2_PNG];
        uv_gt = readFlowFile(fullfile(folder_name, CalcFlows.GT_FLOW_FILE));

        not_done = 0;
    catch exception
        set(handles.roc_gui, 'Visible', 'off');
        uiwait(errordlg([exception.identifier ' - Error while ' msg_prefix ': ' exception.message], 'Invalid directory', 'modal'));
        set(handles.roc_gui, 'Visible', 'on');
    end
end

% change to latest directory
handles.user_data.curr_dir = folder_name;

% get the current no. of axes
no_axes = length(findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re));

% adjust data and disable the clear button
for axes_no = 1:no_axes
    [ handles ] = globalDataUtils('setBackgroundImageData', i1, i2, uv_gt, handles, axes_no );
    [ handles ] = globalDataUtils('resetOverlayImageData', handles, axes_no );

    % disable overlay clear button
    globalAxesUtils('switchContextMenuClear', handles, axes_no, 'off');
    
    % enable flow button
    globalAxesUtils('switchAndToggleContextMenuFlow', handles, axes_no, 'on', 'off');
end

% Update handles structure
guidata(hObject, handles);

% set the background image on all axes
globalAxesUtils('setImageForAllAxes', handles);

% check if the boundary image is needed on any axes
boundaryChkboxCallbacks('boundary_chkbox_Callback', hObject, eventdata, handles);



function menu_ftr_imp_Callback(hObject, eventdata, handles)
not_done = 1;
msg_prefix = '[unknown action]';

while not_done
    try
        % check if it has all the necessary files are there and readable
        msg_prefix = ['choosing file'];
        
        [file_name folder_name] = uigetfile('*.mat', 'Select file for feature importance', handles.user_data.curr_prediction_dir{3});

        if isscalar(file_name) && file_name == 0
            return;
        end
        
        msg_prefix = ['getting feature data'];
        featureImportanceFig(fullfile(folder_name, file_name));
        
        not_done = 0;
    catch exception
        set(handles.roc_gui, 'Visible', 'off');
        uiwait(errordlg([exception.identifier ' - Error while ' msg_prefix ': ' exception.message], 'Invalid file', 'modal'));
        set(handles.roc_gui, 'Visible', 'on');
    end
end

handles.user_data.curr_prediction_dir{3} = folder_name;

% Update handles structure
guidata(hObject, handles);



function setZoomingFunction(hObject, eventdata, handles, func_type)
% if their was a previous button pressed then declick it
prv_button = getappdata(handles.roc_gui, handles.user_data.appdata_currtoolbar_button);
if ~isempty(prv_button)  % aborting one operation and starting another
    if ishghandle(prv_button) ...
        && strcmp(get(prv_button,'Type'),'uitoggletool') ...
        && prv_button ~= gcbo ...  % not the same button
        && ancestor(prv_button,'Figure') == handles.roc_gui % Same Window
        
        set(prv_button,'State','off');
    end
end

% set the current tool to the current button
setappdata(handles.roc_gui, handles.user_data.appdata_currtoolbar_button,hObject);

if any(ishghandle(hObject))
    % get the state of the current button
    onoff = get(hObject,'State');
    
    % activate or deactivate according to the button that was clicked
    switch func_type
        case 'zoomin'
            if strcmpi(onoff,'on')
                h = zoom(handles.roc_gui);
                set(h, 'Direction','in');
                set(h, 'ActionPostCallback',@(objFigure,eventdata) menuCallbacks('adjustFlowDensity', objFigure, eventdata, guidata(objFigure), func_type));
                set(h,'Enable','on');
            else
                zoom(handles.roc_gui,'off')
            end
        case 'zoomout'
            if strcmpi(onoff,'on')
                h = zoom(handles.roc_gui);
                set(h, 'Direction','out');
                set(h, 'ActionPostCallback',@(objFigure,eventdata) menuCallbacks('adjustFlowDensity', objFigure, eventdata, guidata(objFigure), func_type));
                set(h,'Enable','on');
            else
                zoom(handles.roc_gui,'off')
            end
        case 'pan'
            if strcmpi(onoff,'on')
                pan(handles.roc_gui,'onkeepstyle');
            else
                pan(handles.roc_gui,'off');
            end
    end
end



function adjustFlowDensity( objFigure, eventdata, handles, func_type )
%This function gets the quiver arrows for flow according to the available
%   height and width of the image

% find the axes no
tok = regexp(get(eventdata.Axes, 'Tag'), handles.user_data.axes_search_re, 'Tokens');
axes_idx = str2num(tok{1}{1});

% new_limits = axis(eventdata.Axes);
% fprintf(1, 'The new X-Limits are [%.2f %.2f %.2f %.2f].\n',new_limits);

% get what the tick value was
flow_menu_h = findall(handles.roc_gui, 'Tag', [handles.user_data.axes_flow_menu_prefix num2str(axes_idx)]);

% toggle
display_flow = strcmp(get(flow_menu_h, 'Checked'), 'on');
if display_flow
    % find quiver handle
    quiver_h = findall(handles.roc_gui, 'Tag',[handles.user_data.axes_flow_prefix num2str(axes_idx)]);
    delete(quiver_h);
    
    plotFlowOnAxes( eventdata.Axes, axes_idx, handles.user_data.user_images(axes_idx), handles );
end
