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

a = findall(gcf, '-regexp', 'Tag', handles.user_data.axes_search_re);
for axes_idx = 1:length(a)
    tag_name = get(a(axes_idx), 'Tag');
    
    image(uint8(rgb2gray(handles.user_data.user_images(axes_idx).im1) * handles.user_data.colorspace_scaling_tp), 'Parent',a(axes_idx));
    
    colormap([linspace(0,1,handles.user_data.colorspace_scaling_tp)'*[1 1 1]; 
              handles.user_data.ctp; handles.user_data.cfn; handles.user_data.cfp]);
    
    % set the axes properties
    set(a(axes_idx), 'Box','off', 'XColor',get(handles.roc_gui,'Color'), 'YColor',get(handles.roc_gui,'Color'), ...
        'Units','pixels', 'Tag',tag_name, 'XTick',[], 'YTick',[], 'ZTick',[]);
end

% adjust the uicontextmenu handles
adjustUicontextmenuCallback( handles );



function adjustUicontextmenuCallback( handles )
% used for adjusting all the context menus (attaching to the most image) in
%   all the axes'

a = findall(gcf, '-regexp', 'Tag', handles.user_data.axes_search_re);
for axes_idx = 1:length(a)
    menu_callback = get(a(axes_idx), 'Uicontextmenu');
    axes_children = get(a(axes_idx), 'Children');
    
    if all(ishandle(menu_callback)) && ~isempty(axes_children)
       % add callback to top most image
       im_children = strcmp('image', get(axes_children, 'Type'));
       if any(im_children)
           set(axes_children(find(im_children,1,'first')), 'Uicontextmenu', menu_callback);
       end
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
