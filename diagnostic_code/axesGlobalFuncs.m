function [ varargout ] = axesGlobalFuncs( varargin )
% evaluate function according to the number of inputs and outputs
if nargout(varargin{1}) > 0
    [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
else
    feval(varargin{:});
end


function setImageForAllAxes( handles )
% sets the background image to all the axes and assigns the context menu to
%   that image

a = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re);
for axes_idx = 1:length(a)
    setImageForAxes( handles, axes_idx );
end

% adjust the uicontextmenu handles
adjustUicontextmenuCallback( handles );


function setImageForAxes( handles, axes_idx )
axes_handle = handles.([handles.user_data.axes_tag_prefix num2str(axes_idx)]);

tag_name = get(axes_handle, 'Tag');
    
% delete all the previous children
delete(get(axes_handle, 'Children'));

image(uint8(rgb2gray(handles.user_data.user_images(axes_idx).im1) * handles.user_data.colorspace_scaling_tp), 'Parent',axes_handle);

% set the axes properties
set(axes_handle, 'DataAspectRatio', [1 1 1], 'Box','off', 'XColor',get(handles.roc_gui,'Color'), 'YColor',get(handles.roc_gui,'Color'), ...
    'Units','pixels', 'Tag',tag_name, 'XTick',[], 'YTick',[], 'ZTick',[]);


function adjustUicontextmenuCallback( handles )
% used for adjusting all the context menus (attaching to the most image) in
%   all the axes'

a = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re);
for axes_idx = 1:length(a)
    menu_callback = get(a(axes_idx), 'Uicontextmenu');
    axes_children = get(a(axes_idx), 'Children');
    
    im_children = findobj(axes_children, 'Type', 'image');
    
    if all(ishandle(menu_callback)) && ~isempty(im_children)
       % add callback to top most image
       set(im_children(1), 'Uicontextmenu', menu_callback);
    end
end



function [ handles ] = reInitImageData( handles )
% resets all the data for all the axes'

% get the current no. of axes
no_axes = length(findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re));

% store the axes image
user_image.im1 = [];
user_image.im2 = [];
user_image.gt = [];
user_image.gt_boundary_im = [];
user_image.values = [];
handles.user_data.user_images = repmat(user_image, [no_axes 1]);
