function thresholdSliderCallbacks( varargin )
feval(varargin{:});


% --- Executes during object creation, after setting all properties.
function threshold_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider mouse button up.
function threshold_slider_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

%obtains the slider value from the slider component
slider_value = get(hObject, 'Value');
 
%puts the slider value into the edit text component
set(handles.threshold_text, 'String', num2str(slider_value));

% Update handles structure
guidata(hObject, handles);

displayImage(handles, slider_value);


% --- Executes on slider's inbetween dragging movement.
function threshold_slider_Action(hObject, eventdata, handles)
threshold_slider_Callback(hObject, eventdata, handles);
