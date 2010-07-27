function [ output_args ] = boundaryChkboxCallbacks( varargin )
%BOUNDARYCHKBOXCALLBACKS Summary of this function goes here
%   Detailed explanation goes here
feval(varargin{:});



% --- Executes on button press in boundary_chkbox.
function boundary_chkbox_Callback(hObject, eventdata, handles)
% hObject    handle to boundary_chkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of boundary_chkbox

hold(handles.axes1, 'on');

if get(handles.boundary_chkbox, 'Value')
    image(handles.user_data.gt_boundary_im, 'AlphaData', handles.user_data.gt_boundary, 'Parent', handles.axes1);
else
    % if boundary was being shown previously then delete it
    c = get(handles.axes1, 'Children');
    if length(c) > 1
        delete(c(1));
    end
end
    