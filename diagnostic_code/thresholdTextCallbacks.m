function [ output_args ] = thresholdTextCallbacks( varargin )
feval(varargin{:});


% --- Executes on threshold text change
function threshold_text_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshold_text as text
%        str2double(get(hObject,'String')) returns contents of threshold_text as a double

%get the string for the editText component
slider_value = get(handles.threshold_text,'String');
 
%convert from string to number if possible, otherwise returns empty
slider_value = str2double(slider_value);
 
%if user inputs something is not a number, or if the input is less than 0
%or greater than 100, then the slider value defaults to 0
if (isempty(slider_value) || isnan(slider_value) || slider_value < get(hObject,'Min') || slider_value > get(hObject,'Max'))
    set(handles.threshold_slider, 'Value', get(hObject,'Min'));
    set(handles.threshold_text, 'String', num2str(get(hObject,'Min')));
    slider_value = get(hObject,'Min');
else
    set(handles.threshold_slider,'Value',slider_value);
end

displayImage(handles, slider_value);


% --- Executes during object creation, after setting all properties.
function threshold_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
