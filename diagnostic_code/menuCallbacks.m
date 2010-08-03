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
handles = axesGlobalFuncs('reInitImageData', handles);

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
        uiwait(errordlg([exception.identifier ' - Error while ' msg_prefix ': ' exception.message], 'Invalid directory', 'modal'));
        set(handles.roc_gui, 'Visible', 'on');
    end
end

% change to latest directory
handles.user_data.curr_dir = folder_name;

% get the current no. of axes
no_axes = length(findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re));

% replicate the data
user_image.im1 = i1;
user_image.im2 = i2;
user_image.gt = mask;
user_image.gt_boundary_im = 0.999*repmat(bwperim(user_image.gt), [1 1 3]);
user_image.values = [];
handles.user_data.user_images = repmat(user_image, [no_axes 1]);

axesGlobalFuncs('setImageForAllAxes', handles);

% Update handles structure
guidata(hObject, handles);



function menu_load_overlay_Callback(hObject, eventdata, handles, axes_tag, axes_idx)

RANDOM_FOREST_TXT = 'Random Forest Prediction';
COMPUTE_FEATURE_TXT = 'ComputeFeatureVectors';

% find which file type user wants for overlay
choice = questdlg('Choose file type for overlay:', 'Load Overlay', RANDOM_FOREST_TXT, COMPUTE_FEATURE_TXT, 'Cancel', RANDOM_FOREST_TXT);

if strcmp(choice, 'Cancel') || isempty(choice)
    return;
else
    not_done = 1;
    msg_prefix = '[unknown action]';

    while not_done
        try
            % check if it has all the necessary files are there and readable
            msg_prefix = ['choosing file'];
            if strcmp(choice, RANDOM_FOREST_TXT)
                [file_name folder_name] = uigetfile('*.data', 'Select file for overlay', handles.user_data.curr_prediction_dir{1});
            else
                [file_name folder_name] = uigetfile('*.mat', 'Select file for overlay', handles.user_data.curr_prediction_dir{2});
            end
            
            if isscalar(file_name) && file_name == 0
                return;
            end

            % load the file
            tok = regexp(file_name, '(\d+)_(\w+)_\w+.\w+$', 'tokens');
            assert(length(tok)==1 && length(tok{1})==2, 'Couldn''t decipher scene_id and unique_id from filename OR filename not supported');
            scene_id = tok{1}{1};
            
            
            if strcmp(choice, RANDOM_FOREST_TXT)
                msg_prefix = ['setting classifier output data'];
                obj.classifier_out = textread(fullfile(folder_name, file_name), '%f');
                
                if isempty(handles.user_data.user_images(axes_idx).im1)
                    % load the image from the scene dir
                    info = imfinfo(fullfile(handles.user_data.data_dir, scene_id, ComputeTrainTestData.IM1_PNG));
                    sz = [info.Height, info.Width];
                else
                    sz = size(handles.user_data.user_images(axes_idx).im1);
                end
                
                classifier_out = reshape(obj.classifier_out, sz(2), sz(1))';   % need the transpose to read correctly
                handles.user_data.user_images(axes_idx).values = classifier_out;
            else
                msg_prefix = ['setting feature data'];
                feature = getUserChoiceFeature(fullfile(folder_name, file_name));
                
                % in case the user cancelled at any moment, exit from selection
                if isempty(feature)
                    return;
                end
                handles.user_data.user_images(axes_idx).values = feature;
            end

            not_done = 0;
        catch exception
            set(handles.roc_gui, 'Visible', 'off');
            uiwait(errordlg([exception.identifier ' - Error while ' msg_prefix ': ' exception.message], 'Invalid directory', 'modal'));
            set(handles.roc_gui, 'Visible', 'on');
        end
    end
end

% change to latest directory
if strcmp(choice, RANDOM_FOREST_TXT)
    handles.user_data.curr_prediction_dir{1} = folder_name;
else
    handles.user_data.curr_prediction_dir{2} = folder_name;
end


% Update handles structure
guidata(hObject, handles);

% update the images on the all the axes
thresholdSliderCallbacks('threshold_slider_Callback', hObject, eventdata, handles);



function menu_clear_overlay_Callback(hObject, eventdata, handles, axes_tag, axes_idx)
disp('clearing overlay');

