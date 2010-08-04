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
