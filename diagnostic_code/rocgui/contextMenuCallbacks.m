function [ varargout ] = contextMenuCallbacks( varargin )
% evaluate function according to the number of inputs and outputs
if nargout(varargin{1}) > 0
    [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
else
    feval(varargin{:});
end


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
            uiwait(errordlg([exception.identifier ' - Error while ' msg_prefix ': ' exception.message], 'Invalid file', 'modal'));
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

% check if the boundary image is needed on any axes
boundaryChkboxCallbacks('boundary_chkbox_Callback', hObject, eventdata, handles);

% disable overlay clear button
globalAxesUtils('switchContextMenuClear', handles, axes_idx, 'on');



function menu_clear_overlay_Callback(hObject, eventdata, handles, axes_tag, axes_idx)
[ handles ] = globalDataUtils('resetOverlayImageData', handles, axes_idx );

% delete previous overlay images
globalAxesUtils('deleteOverlayImages', handles, axes_idx);

% Update handles structure
guidata(hObject, handles);

% update the images on the all the axes
thresholdSliderCallbacks('threshold_slider_Callback', hObject, eventdata, handles);

% disable overlay clear button
globalAxesUtils('switchContextMenuClear', handles, axes_idx, 'off');



function menu_flow_overlay_Callback(hObject, eventdata, handles, axes_tag, axes_no)
% get what the tick value was
flow_menu_h = findall(handles.roc_gui, 'Tag', [handles.user_data.axes_flow_menu_prefix num2str(axes_no)]);

% toggle
display_flow = strcmp(get(flow_menu_h, 'Checked'), 'off');
if display_flow
    if isempty(handles.user_data.user_images(axes_no).flow)
        uiwait(errordlg('Flow data not available', 'Data error', 'modal'));
        return;
    end
    
    % empty the algo flow
    handles = globalDataUtils('resetAlgoFlowData', handles, axes_no);
    
    % delete the flow image from the axes
    globalAxesUtils('deleteFlowImage', handles, axes_no, 1);
    
    % check GT flow button
    globalAxesUtils('switchAndToggleContextMenuFlow', handles, axes_no, 'on', 'on');
    
    axes_h = handles.([handles.user_data.axes_tag_prefix num2str(axes_no)]);
    plotFlowOnAxes( axes_h, axes_no, handles.user_data.user_images(axes_no), handles );
else
    % delete the flow image from the axes
    globalAxesUtils('deleteFlowImage', handles, axes_no, 1);
end

% Update handles structure
guidata(hObject, handles);



function menu_algo_flow_overlay_Callback(hObject, eventdata, handles, axes_tag, axes_no)
% get what the tick value was
algo_menu_h = findall(handles.roc_gui, 'Tag', [handles.user_data.axes_algo_flow_menu_prefix num2str(axes_no)]);

% toggle
display_flow = strcmp(get(algo_menu_h, 'Checked'), 'off');
if display_flow
    not_done = 1;
    msg_prefix = '[unknown action]';

    % loop until either user gives up (cancels) or finds the flow algo
    while not_done
        try
            % check if it has all the necessary files are there and readable
            msg_prefix = ['choosing file'];
            [file_name folder_name] = uigetfile('*.mat', 'Select file for algo. flow overlay', handles.user_data.curr_dir);

            if isscalar(file_name) && file_name == 0
                return;
            end

            msg_prefix = ['setting flow algorithm data'];
            busy_h = busydlg('Please wait... Loading CalcFlows object from file...', 'ROC gui', 'WindowStyle','modal');
            loaded_vars = load(fullfile(folder_name, file_name));
            delete(busy_h);

            temp = fields(loaded_vars);
            calc_flows = loaded_vars.(temp{1});
            assert(isa(calc_flows, 'CalcFlows'), 'Callback:InvalidInput', 'The loaded file doesn''t contain CalcFlows object');

            % check if it matches with the background
            if ~isempty(handles.user_data.user_images(axes_no).im1)
                bg_sz = size(handles.user_data.user_images(axes_no).im1);
                flow_sz = size(calc_flows.uv_flows);
                assert(all(bg_sz(1:2)==flow_sz(1:2)), 'Callback:InvalidInput', 'The loaded flow is incompatible in size with the current background');
            end

            flow_list = arrayfun(@(i) calc_flows.cell_flow_algos{i}.OF_TYPE, 1:length(calc_flows.cell_flow_algos), 'UniformOutput',false);

            selection_id = listdlg('ListString',flow_list, 'SelectionMode','single', 'ListSize',[300,200], 'Name','Select flow algo.', ...
                    'PromptString','Select from the list of available flow algorithms for overlay:');

            if isempty(selection_id)
                return
            end

            % delete the flow image from the axes
            globalAxesUtils('deleteFlowImage', handles, axes_no, 1);

            handles.user_data.user_images(axes_no).flow_alternate(:,:,:,1) = calc_flows.uv_flows(:,:,:,selection_id);

            % if reverse flow is available
            if ~isempty(calc_flows.uv_flows_reverse)
                handles.user_data.user_images(axes_no).flow_alternate(:,:,:,2) = calc_flows.uv_flows_reverse(:,:,:,selection_id);
            end
            
            not_done = 0;
        catch exception
            uiwait(errordlg([exception.identifier ' - Error while ' msg_prefix ': ' exception.message], 'Invalid file', 'modal'));
        end
    end
    
    % check Algo. flow button
    globalAxesUtils('switchAndToggleContextMenuAlternateFlow', handles, axes_no, 'on');
    
    axes_h = handles.([handles.user_data.axes_tag_prefix num2str(axes_no)]);
    plotFlowOnAxes( axes_h, axes_no, handles.user_data.user_images(axes_no), handles );
else
    % empty the algo flow
    handles = globalDataUtils('resetAlgoFlowData', handles, axes_no);
    
    % delete the flow image from the axes
    globalAxesUtils('deleteFlowImage', handles, axes_no, 1);
end

% Update handles structure
guidata(hObject, handles);


function menu_print_image_Callback(hObject, eventdata, handles, axes_tag, axes_no)
not_done = 1;
msg_prefix = '[unknown action]';

% loop until either user gives up (cancels) or finds the flow algo
while not_done
    try
        % check if it has all the necessary files are there and readable
        msg_prefix = ['choosing file'];
        [file_name folder_name] = uiputfile('*.eps;*.bmpl;*.jpg;*.png;*.tiff', 'Indicate where to save the image', handles.user_data.curr_dir);

        if isscalar(file_name) && file_name == 0
            return;
        end


        not_done = 0;
    catch exception
        uiwait(errordlg([exception.identifier ' - Error while ' msg_prefix ': ' exception.message], 'Invalid file', 'modal'));
    end
end
