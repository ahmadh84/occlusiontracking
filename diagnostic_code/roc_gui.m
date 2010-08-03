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

% Last Modified by GUIDE v2.5 29-Jul-2010 13:14:15

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


% disallow figure to have doct controls
set(hObject, 'DockControls','off');


% add any paths required for running the GUI
addpath(fullfile(pwd, '..', 'main_code'));
addpath(genpath(fullfile(pwd, '..', 'main_code', 'utils')));


% set user data defaults
handles = setUserDataDefaults(handles);


% create the starting axes and init the GUI
handles = adjustGUIandAxeses(hObject, handles.user_data.default_no_axes, handles);


% initialize the user image data
handles = globalDataUtils('reInitImageData', handles);


% create menu bar
h1 = uimenu('Parent',hObject, 'Label','&File', 'Tag','menu_file');
uimenu('Parent',h1, 'Label','&Load Directory', 'Tag','menu_load_directory', 'Callback',@(hObject,eventdata) menuCallbacks('menu_load_directory_Callback', hObject, eventdata, guidata(hObject)));

h1 = uimenu('Parent',hObject, 'Label','&Axes Options', 'Tag','menu_axes_options');
uimenu('Parent',h1, 'Label','&1 Axes', 'Tag','menu_axes_1', 'Callback',@(hObject,eventdata) menuCallbacks('menu_axes_num_Callback', hObject, eventdata, guidata(hObject), 1));
uimenu('Parent',h1, 'Label','&2 Axes', 'Tag','menu_axes_2', 'Callback',@(hObject,eventdata) menuCallbacks('menu_axes_num_Callback', hObject, eventdata, guidata(hObject), 2));
uimenu('Parent',h1, 'Label','&4 Axes', 'Tag','menu_axes_4', 'Callback',@(hObject,eventdata) menuCallbacks('menu_axes_num_Callback', hObject, eventdata, guidata(hObject), 4));
uimenu('Parent',h1, 'Label','&6 Axes', 'Tag','menu_axes_6', 'Callback',@(hObject,eventdata) menuCallbacks('menu_axes_num_Callback', hObject, eventdata, guidata(hObject), 6));


% Set callbacks for UI controls
set(handles.threshold_slider, 'Callback', @(hObject,eventdata) thresholdSliderCallbacks('threshold_slider_Callback', hObject, eventdata, guidata(hObject)) );
set(handles.threshold_slider, 'CreateFcn', @(hObject,eventdata) thresholdSliderCallbacks('threshold_slider_CreateFcn', hObject, eventdata, guidata(hObject)) );
addlistener(handles.threshold_slider, 'Action', @(hObject,eventdata) thresholdSliderCallbacks('threshold_slider_Action', hObject, eventdata, guidata(hObject)) );

set(handles.threshold_text, 'Callback', @(hObject,eventdata) thresholdTextCallbacks('threshold_text_Callback', hObject, eventdata, guidata(hObject)) );
set(handles.threshold_text, 'CreateFcn', @(hObject,eventdata) thresholdTextCallbacks('threshold_text_CreateFcn', hObject, eventdata, guidata(hObject)) );

set(handles.boundary_chkbox, 'Callback', @(hObject,eventdata) boundaryChkboxCallbacks('boundary_chkbox_Callback', hObject, eventdata, guidata(hObject)) );
set(handles.boundary_chkbox, 'Value', 0);


% set the colors for the text labels
set(handles.text_ctp, 'BackgroundColor', handles.user_data.ctp);
set(handles.text_cfn, 'BackgroundColor', handles.user_data.cfn);
set(handles.text_cfp, 'BackgroundColor', handles.user_data.cfp);

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



function handles = setUserDataDefaults(handles)
user_data = struct;

% put in any user data which needs to go into handles
if isfield(handles, 'user_data')
    user_data = handles.user_data;    
end

% colors for markers
user_data.ctp = [0 1.0 0];
user_data.cfn = [1.0 0 0];
user_data.cfp = [0 0 0.8];

user_data.colorspace_scaling_tp = 252;
user_data.colorspace_scaling_fn = 253;
user_data.colorspace_scaling_fp = 254;

user_data.data_dir = 'C:\Users\Ahmad\Documents\UCL\MS Thesis - Tracking powered by Superpixels\Data\oisin+middlebury\';
user_data.curr_dir = 'C:\Users\Ahmad\Documents\UCL\MS Thesis - Tracking powered by Superpixels\Data\oisin+middlebury\';
user_data.curr_prediction_dir = {'H:\middlebury\', 'C:\Users\Ahmad\Documents\UCL\MS Thesis - Tracking powered by Superpixels\Data\oisin+middlebury\'};
user_data.axes_tag_prefix = 'roc_axes_';
user_data.axes_txt_prefix = 'text_roc_axes_';
user_data.im_gt_prefix = 'im_gt_roc_';
user_data.axes_search_re = ['^' user_data.axes_tag_prefix '\d+$'];
user_data.axes_uicontext_menu_re = ['^context_menu_' user_data.axes_tag_prefix '\d+$'];

% no of axes by default
user_data.default_no_axes = 1;

handles.user_data = user_data;
