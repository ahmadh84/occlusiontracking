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

% Last Modified by GUIDE v2.5 27-Jul-2010 14:21:00

% if GUI already running, then exit
set(0,'showhiddenhandles','on');
p = findobj('tag','roc_gui','parent',0);
set(0,'showhiddenhandles','off');
if ishandle(p)
    delete(p);
end

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

set(handles.threshold_slider, 'Callback', @(hObject,eventdata) thresholdSliderCallbacks('threshold_slider_Callback', hObject, eventdata, guidata(hObject)) );
set(handles.threshold_slider, 'CreateFcn', @(hObject,eventdata) thresholdSliderCallbacks('threshold_slider_CreateFcn', hObject, eventdata, guidata(hObject)) );
addlistener(handles.threshold_slider, 'Action', @(hObject,eventdata) thresholdSliderCallbacks('threshold_slider_Action', hObject, eventdata, guidata(hObject)) );

set(handles.threshold_text, 'Callback', @(hObject,eventdata) thresholdTextCallbacks('threshold_text_Callback', hObject, eventdata, guidata(hObject)) );
set(handles.threshold_text, 'CreateFcn', @(hObject,eventdata) thresholdTextCallbacks('threshold_text_CreateFcn', hObject, eventdata, guidata(hObject)) );

set(handles.boundary_chkbox, 'Callback', @(hObject,eventdata) boundaryChkboxCallbacks('boundary_chkbox_Callback', hObject, eventdata, guidata(hObject)) );
set(handles.boundary_chkbox, 'Value', 0);

% call init to get the user data
handles = init(handles, varargin{:});

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes roc_gui wait for user response (see UIRESUME)
% uiwait(handles.roc_gui);


% --- Outputs from this function are returned to the command line.
function varargout = roc_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function [ handles ] = init(handles, varargin)
% user init function for creating user data and misc. initialization

% colors for markers
user_data.ctp = [0 1.0 0];
user_data.cfn = [1.0 0 0];
user_data.cfp = [0 0 0.8];

user_data.im1 = rgb2gray(varargin{1});
user_data.im1(end-10,end-10) = 1.0;
user_data.posterior = varargin{2};
user_data.gt = varargin{3};
user_data.gt_boundary = bwperim(user_data.gt);
user_data.gt_boundary_im = 0.999*repmat(user_data.gt_boundary, [1 1 3]);

set(handles.text2, 'BackgroundColor', user_data.ctp);
set(handles.text3, 'BackgroundColor', user_data.cfn);
set(handles.text4, 'BackgroundColor', user_data.cfp);

user_data.colorspace_scaling_tp = 252;
user_data.colorspace_scaling_fn = 253;
user_data.colorspace_scaling_fp = 254;

% delete the axes images if any
c = get(handles.axes1, 'Children');
delete(c);

% display image and set colormap
imshow(uint8(user_data.im1*user_data.colorspace_scaling_tp));
colormap([linspace(0,1,user_data.colorspace_scaling_tp)'*[1 1 1]; user_data.ctp; user_data.cfn; user_data.cfp]);

threshold = get(handles.threshold_slider, 'Value');

% fit user data in handles
handles.user_data = user_data;

displayImage(handles, threshold);
