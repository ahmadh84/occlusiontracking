function menuCallbacks( varargin )
feval(varargin{:});

% --- Executes during axes number is tried to be changed from the menu
function menu_axes_num_Callback(hObject, eventdata, handles, no_axes)
% hObject    handle to menu_axes_X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = adjustGUIandAxeses(gcf, no_axes, handles);

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
        mask = (uv_gt(:,:,1)>200 | uv_gt(:,:,2)>200);

        not_done = 0;
    catch exception
        set(handles.roc_gui, 'Visible', 'off');
        uiwait(errordlg([exception.identifier ' - Error while ' msg_prefix ': ' exception.message], 'Invalid directory'));
        set(handles.roc_gui, 'Visible', 'on');
    end
end

% change to latest directory
handles.user_data.curr_dir = folder_name;

handles.user_data.im1 = i1;
handles.user_data.im2 = i2;
handles.user_data.gt = mask;
handles.user_data.gt_boundary_im = 0.999*repmat(bwperim(handles.user_data.gt), [1 1 3]);

setImageForAllAxes(handles);

% Update handles structure
guidata(gcf, handles);
