function menuCallbacks( varargin )
feval(varargin{:});

% --- Executes during axes number is tried to be changed from the menu
function menu_axes_num_Callback(hObject, eventdata, handles, no_axes)
% hObject    handle to menu_axes_X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = adjustGUIandAxeses(gcf, no_axes, handles);

% Update handles structure
guidata(hObject, handles);
