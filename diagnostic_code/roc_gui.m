function varargout = roc_gui(varargin)
% ROC_GUI M-file for roc_gui.fig
%      ROC_GUI, by itself, creates a new ROC_GUI or raises the existing
%      singleton*.
%
%      H = ROC_GUI returns the handle to a new ROC_GUI or the handle to
%      the existing singleton*.
%
%      ROC_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROC_GUI.M with the given input arguments.
%
%      ROC_GUI('Property','Value',...) creates a new ROC_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before roc_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to roc_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help roc_gui

% Last Modified by GUIDE v2.5 24-Jul-2010 21:44:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @roc_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @roc_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before roc_gui is made visible.
function roc_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to roc_gui (see VARARGIN)

% Choose default command line output for roc_gui
handles.output = hObject;

user_images.ctp = [0 1 0];
user_images.cfn = [1 0 0];
user_images.cfp = [0 0 0.8];

user_images.im1 = rgb2gray(varargin{1});
user_images.posterior = varargin{2};
user_images.gt = varargin{3};
user_images.ngt = ~varargin{3};
user_images.gt_boundary = bwperim(user_images.gt);
user_images.gt_boundary_im = 0.999*repmat(user_images.gt_boundary, [1 1 3]);

set(handles.text2, 'BackgroundColor', user_images.ctp);
set(handles.text3, 'BackgroundColor', user_images.cfn);
set(handles.text4, 'BackgroundColor', user_images.cfp);

imshow(user_images.im1);

handles.user_images = user_images;

threshold = get(handles.threshold_slider, 'Value');
displayImage(handles, threshold);

lh1 = addlistener(handles.threshold_slider,'Action',@lfun1);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes roc_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function lfun1(hObject, eventdata)
threshold_slider_Callback(hObject, eventdata, guidata(hObject));


% --- Outputs from this function are returned to the command line.
function varargout = roc_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on slider movement.
function threshold_slider_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

%obtains the slider value from the slider component
slider_value = get(hObject, 'Value');
 
%puts the slider value into the edit text component
set(handles.thresold_text, 'String', num2str(slider_value));

% Update handles structure
guidata(hObject, handles);

displayImage(handles, slider_value);



% --- Executes during object creation, after setting all properties.
function threshold_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function thresold_text_Callback(hObject, eventdata, handles)
% hObject    handle to thresold_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thresold_text as text
%        str2double(get(hObject,'String')) returns contents of thresold_text as a double

%get the string for the editText component
slider_value = get(handles.thresold_text,'String');
 
%convert from string to number if possible, otherwise returns empty
slider_value = str2num(slider_value);
 
%if user inputs something is not a number, or if the input is less than 0
%or greater than 100, then the slider value defaults to 0
if (isempty(slider_value) || slider_value < 0 || slider_value > 255)
    set(handles.threshold_slider,'Value',0);
    set(handles.thresold_text,'String','0');
else
    set(handles.threshold_slider,'Value',slider_value);
end

displayImage(handles, slider_value);


% --- Executes during object creation, after setting all properties.
function thresold_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thresold_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in boundary_chkbox.
function boundary_chkbox_Callback(hObject, eventdata, handles)
% hObject    handle to boundary_chkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of boundary_chkbox

%obtains the slider value from the slider component
slider_value = get(handles.threshold_slider, 'Value');

displayImage(handles, slider_value);


function displayImage(handles, threshold)
c = get(handles.axes1, 'Children');
if length(c) > 1
    delete(c(1:end-1));
end

[ tp fp fn ] = getInfoFromGT(handles, threshold/255);

hold(handles.axes1, 'on');

image(cat(3, tp*handles.user_images.ctp(1), tp*handles.user_images.ctp(2), tp*handles.user_images.ctp(3)), 'AlphaData', tp*.5, 'Parent', handles.axes1);
image(cat(3, fn*handles.user_images.cfn(1), fn*handles.user_images.cfn(2), fn*handles.user_images.cfn(3)), 'AlphaData', fn*.5, 'Parent', handles.axes1);
image(cat(3, fp*handles.user_images.cfp(1), fp*handles.user_images.cfp(2), fp*handles.user_images.cfp(3)), 'AlphaData', fp*.5, 'Parent', handles.axes1);

if get(handles.boundary_chkbox, 'Value')
    image(handles.user_images.gt_boundary_im, 'AlphaData', handles.user_images.gt_boundary, 'Parent', handles.axes1);
end


function [ tp fp fn ] = getInfoFromGT(handles, threshold)

tmpC1 = handles.user_images.posterior >= threshold;
tmpC2 = ~tmpC1;

% compute the True/False Positive, True/False Negative
tp = tmpC1 & handles.user_images.gt;
fp = tmpC1 & handles.user_images.ngt;
fn = tmpC2 & handles.user_images.gt;


% --------------------------------------------------------------------
function File_Callback(hObject, eventdata, handles)
% hObject    handle to File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
