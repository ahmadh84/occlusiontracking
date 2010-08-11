function [ varargout ] = otherUICallbacks( varargin )
% evaluate function according to the number of inputs and outputs
if nargout(varargin{1}) > 0
    [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
else
    feval(varargin{:});
end



function ctp_button_callback(hObject, eventdata, handles)
c_selected = uisetcolor(get(handles.button_ctp, 'BackgroundColor'), 'True Positive color');

handles.user_data.ctp = c_selected;

% update the color of the background and text of the button
set(handles.button_ctp, 'BackgroundColor', handles.user_data.ctp);
set(handles.button_ctp, 'ForegroundColor', globalDataUtils('getOppositeColor', handles.user_data.ctp));

% Update handles structure
guidata(hObject, handles);

% adjust the colormaps for all axes
globalAxesUtils('adjustColormapAllAxes', handles);



function cfn_button_callback(hObject, eventdata, handles)
c_selected = uisetcolor(get(handles.button_cfn, 'BackgroundColor'), 'False Negative color');

handles.user_data.cfn = c_selected;

% update the color of the background and text of the button
set(handles.button_cfn, 'BackgroundColor', handles.user_data.cfn);
set(handles.button_cfn, 'ForegroundColor', globalDataUtils('getOppositeColor', handles.user_data.cfn));

% Update handles structure
guidata(hObject, handles);

% adjust the colormaps for all axes
globalAxesUtils('adjustColormapAllAxes', handles);




function cfp_button_callback(hObject, eventdata, handles)
c_selected = uisetcolor(get(handles.button_cfp, 'BackgroundColor'), 'False Positive color');

handles.user_data.cfp = c_selected;

% update the color of the background and text of the button
set(handles.button_cfp, 'BackgroundColor', handles.user_data.cfp);
set(handles.button_cfp, 'ForegroundColor', globalDataUtils('getOppositeColor', handles.user_data.cfp));

% Update handles structure
guidata(hObject, handles);

% adjust the colormaps for all axes
globalAxesUtils('adjustColormapAllAxes', handles);



function uibuttonchoice_im_switch(hObject, eventdata, handles)
% find all the axes handles
axes_hs = globalAxesUtils('getAllAxesHandlesSorted', handles);
for axes_no = 1:length(axes_hs)
    plotFlowOnAxes( axes_hs(axes_no), axes_no, handles.user_data.user_images(axes_no), handles );
end

globalAxesUtils('switchBgImageForAllAxes', handles);


