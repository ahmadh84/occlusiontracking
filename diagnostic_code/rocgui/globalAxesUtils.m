function [ varargout ] = globalAxesUtils( varargin )
% evaluate function according to the number of inputs and outputs
if nargout(varargin{1}) > 0
    [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
else
    feval(varargin{:});
end



function setBgImageForAllAxes( handles )
% sets the background image to all the axes and assigns the context menu to
%   that image

a = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re);
for axes_idx = 1:length(a)
    setBgImageForAxes( handles, axes_idx );
end

% adjust the uicontextmenu handles
adjustUicontextmenuCallback( handles );



function setBgImageForAxes( handles, axes_idx )
axes_handle = handles.([handles.user_data.axes_tag_prefix num2str(axes_idx)]);

tag_name = get(axes_handle, 'Tag');
    
% delete all the previous children
delete(get(axes_handle, 'Children'));

% choose image to show according to the im choice uipanel
if strcmp(get(get(handles.uipanel_im_choice, 'SelectedObject'), 'String'), 'image 1')
    im_to_show = handles.user_data.user_images(axes_idx).im1;
else
    im_to_show = handles.user_data.user_images(axes_idx).im2;
end
image(uint8(rgb2gray(im_to_show) * handles.user_data.colorspace_scaling_tp), 'Parent',axes_handle, 'Tag',[handles.user_data.im_bg_prefix num2str(axes_idx)]);

% set the axes properties
set(axes_handle, 'DataAspectRatio', [1 1 1], 'Box','off', 'XColor',get(handles.roc_gui,'Color'), 'YColor',get(handles.roc_gui,'Color'), ...
    'Units','pixels', 'Tag',tag_name, 'XTick',[], 'YTick',[], 'ZTick',[]);



function switchBgImageForAllAxes( handles )
% switches the background image (between im1 and im2) for all the axes and 
%   assigns the context menu to that image

a = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re);
for axes_idx = 1:length(a)
    switchBgImageForAxes( handles, axes_idx );
end

% adjust the uicontextmenu handles
adjustUicontextmenuCallback( handles );



function switchBgImageForAxes( handles, axes_idx )
% choose image to show according to the im choice uipanel
if strcmp(get(get(handles.uipanel_im_choice, 'SelectedObject'), 'String'), 'image 1')
    im_to_show = handles.user_data.user_images(axes_idx).im1;
else
    im_to_show = handles.user_data.user_images(axes_idx).im2;
end

if isempty(im_to_show)
    return;
end

axes_handle = handles.([handles.user_data.axes_tag_prefix num2str(axes_idx)]);

tag_name = get(axes_handle, 'Tag');
    
% find all children handles
children_h = get(axes_handle, 'Children');

% find the old image handle (if exists)
old_im_h = findall(axes_handle, 'Tag',[handles.user_data.im_bg_prefix num2str(axes_idx)]);

% find the order in which it lies
prv_child_order_no = find(children_h == old_im_h);

% delete old image
delete(old_im_h);

% draw image
new_im_h = image(uint8(rgb2gray(im_to_show) * handles.user_data.colorspace_scaling_tp), 'Parent',axes_handle, 'Tag',[handles.user_data.im_bg_prefix num2str(axes_idx)]);
% set the axes properties
set(axes_handle, 'DataAspectRatio', [1 1 1], 'Box','off', 'XColor',get(handles.roc_gui,'Color'), 'YColor',get(handles.roc_gui,'Color'), ...
    'Units','pixels', 'Tag',tag_name, 'XTick',[], 'YTick',[], 'ZTick',[]);

% find children again
children_h = get(axes_handle, 'Children');

% adjust order
children_h(children_h == new_im_h) = [];
set(axes_handle, 'Children',[children_h(1:prv_child_order_no-1); new_im_h; children_h(prv_child_order_no:end)]);


function adjustUicontextmenuCallback( handles )
% used for adjusting all the context menus (attaching it to the top-most 
%   image) in all the axes'. Also attaches it to any hggroup (flow quivers)
%   if available

% get all axes sorted
[ all_axes_h ] = getAllAxesHandlesSorted(handles);

for axes_no = 1:length(all_axes_h)
    menu_callback = get(all_axes_h(axes_no), 'Uicontextmenu');
    axes_children = get(all_axes_h(axes_no), 'Children');
    
    im_children = findobj(axes_children, 'Type', 'image');
    
    if all(ishandle(menu_callback)) && ~isempty(im_children)
       % add callback to top most image
       set(im_children(1), 'Uicontextmenu', menu_callback);
    end
    
    % also attach to topmost hggroup
    hg_children = findobj(axes_children, 'Type', 'hggroup');
    
    if all(ishandle(menu_callback)) && ~isempty(hg_children)
       % add callback to top most image
       set(hg_children(1), 'Uicontextmenu', menu_callback);
    end
end



function recursiveHandleDelete(handle_list)
% recursively (by going down the children tree) deletes all the handles in a list

if isempty(handle_list)
    return;
end

for hndl = handle_list
    if ishandle(hndl)
        children_hndls = get(hndl, 'Children');
        recursiveHandleDelete(children_hndls);
        delete(hndl);
    end
end



function [ all_axes_h ] = getAllAxesHandlesSorted(handles)
% find all the axes
all_axes_h = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re)';

if length(all_axes_h) > 1
    % sort by axes no.
    [temp sorted_idx] = sort(cellfun(@(x) str2num(x{1}{1}), regexp(get(all_axes_h, 'Tag'), '(\d+)$', 'tokens')));
    all_axes_h = all_axes_h(sorted_idx);
end



function deleteOverlayImages(handles, axes_no)
curr_axes_h = handles.([handles.user_data.axes_tag_prefix num2str(axes_no)]);
c = get(curr_axes_h, 'Children');

c = findall(c, 'Type', 'image');    % filter out any thing other than images

if ~isempty(c)
    % check if there is a background image
    has_background = ~isempty(handles.user_data.user_images(axes_no).im1);

    % check if there is a boundary image
    gt_available = ~isempty(handles.user_data.user_images(axes_no).gt_boundary_im);
    has_boundary = get(handles.boundary_chkbox, 'Value') && gt_available;
    
    % get list of handles to delete
    del_handles = c(has_boundary+1:end-has_background);
    del_handles = del_handles(ishandle(del_handles));
    
    % delete the handles to the overlay images
    delete(del_handles);
end


function deleteFlowImage(handles, axes_no, reset_menu_buttons)
% find quiver handle and delete if any
quiver_h = findall(handles.roc_gui, 'Tag',[handles.user_data.axes_flow_prefix num2str(axes_no)]);
delete(quiver_h);

if reset_menu_buttons
    % check GT flow button
    switchAndToggleContextMenuFlow(handles, axes_no, 'keep', 'off');

    % check off Algo. flow button
    switchAndToggleContextMenuAlternateFlow(handles, axes_no, 'off');
end



function switchContextMenuClear(handles, axes_no, enable_disable)
% disable/enable overlay clear button
uicontextmenu_clear_h = findobj('Tag', [handles.user_data.axes_clear_menu_prefix num2str(axes_no)]);
set(uicontextmenu_clear_h, 'Enable', enable_disable);



function switchAndToggleContextMenuFlow(handles, axes_no, enable_disable, ticked_not_ticked)
% disable/enable tick/untick GT flow button
uicontextmenu_flow_h = findobj('Tag', [handles.user_data.axes_flow_menu_prefix num2str(axes_no)]);
set(uicontextmenu_flow_h, 'Checked',ticked_not_ticked);
if ~strcmp(enable_disable, 'keep')
    set(uicontextmenu_flow_h, 'Enable',enable_disable);
end


function switchAndToggleContextMenuAlternateFlow(handles, axes_no, ticked_not_ticked)
% tick/untick flow algo button
uicontextmenu_aflow_h = findobj('Tag', [handles.user_data.axes_algo_flow_menu_prefix num2str(axes_no)]);
set(uicontextmenu_aflow_h, 'Checked',ticked_not_ticked);



function adjustColormapAllAxes( handles )
% readjusts colormaps for all axes
all_axes_h = getAllAxesHandlesSorted(handles);
    
% loop over to create all the axes
for axes_no = 1:length(all_axes_h)
    axes_h = all_axes_h(axes_no);
    
    colormap(axes_h, [linspace(0,1,handles.user_data.colorspace_scaling_tp)'*[1 1 1]; 
              handles.user_data.ctp; handles.user_data.cfn; handles.user_data.cfp]);
end
