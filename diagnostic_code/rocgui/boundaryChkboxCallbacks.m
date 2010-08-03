function [ varargout ] = boundaryChkboxCallbacks( varargin )
%BOUNDARYCHKBOXCALLBACKS Summary of this function goes here
%   Detailed explanation goes here

% evaluate function according to the number of inputs and outputs
if nargout(varargin{1}) > 0
    [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
else
    feval(varargin{:});
end



% --- Executes on button press in boundary_chkbox.
function boundary_chkbox_Callback(hObject, eventdata, handles)
% hObject    handle to boundary_chkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of boundary_chkbox

% find all the axes
[ all_axes_h ] = globalAxesUtils('getAllAxesHandlesSorted', handles);


% iterate over all axes
for idx = 1:length(all_axes_h)
    % GT available
    gt_available = ~isempty(handles.user_data.user_images(idx).gt_boundary_im);
    
    if get(handles.boundary_chkbox, 'Value') && gt_available
        hold(all_axes_h(idx), 'on');
        image(handles.user_data.user_images(idx).gt_boundary_im, 'AlphaData', handles.user_data.user_images(idx).gt_boundary_mask, 'Parent', all_axes_h(idx), 'Tag',[handles.user_data.im_gt_prefix num2str(idx)]);
    else
        % if boundary was being shown previously then delete it
        c = findall(handles.roc_gui, 'Tag', [handles.user_data.im_gt_prefix num2str(idx)]);
        delete(c);
    end
end

% adjust the position of the callbacks
globalAxesUtils('adjustUicontextmenuCallback', handles);
