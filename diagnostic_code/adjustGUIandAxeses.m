function [ handles ] = adjustGUIandAxeses(hObject, no_axes, handles)
top_ui_height = 0;
border_pxls = 20;
aspect_ratio_to_maintain = 1.333;
min_gap = 10;
gui_starting_pos = [ 40 100 ];
axes_tag_prefix = 'roc_axes_';

            %Axes Axes_rows Axes_cols Gui_Width Gui_Height
layouts = [ 1     1         1         850       650;        % for 1 axes
            2     1         2        1100       550;        % for 2 axes
            4     2         2         850       750;        % for 4 axes
            6     2         3        1200       750 ];      % for 6 axes

% delete all old axes handles
axes_h = findall(hObject, '-regexp', 'Tag', [axes_tag_prefix '\d+']);
delete(axes_h);

set(hObject, 'Units', 'pixels');
fig_size = get(hObject, 'Position');

% the layout positioning is from bottom left corner in row major order
% calculate position for each axes
layout_idx = layouts(:,1)==no_axes;
assert(nnz(layout_idx)==1, 'The number of axes demanded is not supported by adjustGUIandAxeses');

% set the GUI position
set(hObject, 'Position', [gui_starting_pos layouts(layout_idx,[4 5])]);

% center the controls panel
pos = get(handles.uipanel_main_controls, 'Position');
set(handles.uipanel_main_controls, 'Position', [ layouts(layout_idx,4)/2-pos(3)/2, border_pxls pos([3 4])]);

% get the extents where to fit the axes
axes_extents = [ border_pxls, pos(4)+2*border_pxls, layouts(layout_idx,4)-border_pxls, layouts(layout_idx,5)-top_ui_height-border_pxls ];

[x y] = meshgrid(axes_extents(1):(axes_extents(3)-axes_extents(1))/layouts(layout_idx,3):axes_extents(3), ...
                 axes_extents(2):(axes_extents(4)-axes_extents(2))/layouts(layout_idx,2):axes_extents(4));

tempx = x(1:end-1,1:end-1)'+min_gap/2;
tempy = y(1:end-1,1:end-1)'+min_gap/2;
axes_width = x(1,2)-x(1,1)-min_gap;
axes_height = y(2,1)-y(1,1)-min_gap;

% fix the height or width according to the aspect ratio
if axes_width/axes_height > aspect_ratio_to_maintain
    old_axes_width = axes_width;
    axes_width = axes_height * aspect_ratio_to_maintain;
    tempx = tempx+(old_axes_width-axes_width)/2;
else
    old_axes_height = axes_height;
    axes_height = axes_width / aspect_ratio_to_maintain;
    tempy = tempy+(old_axes_height-axes_height)/2;
end

pos = [tempx(:), tempy(:), repmat([axes_width axes_height], [no_axes 1])];

% loop over to create all the axes
for axes_idx = 1:no_axes
    axes_tag = [axes_tag_prefix num2str(axes_idx)];
    
    h1 = axes('Parent',hObject, ...
        'Box', 'on', ...
        'Units','pixels', ...
        'Position',pos(axes_idx,:), ...
        'Tag',axes_tag, ...
        'XColor',[0 0 0], ...
        'XTickMode','manual', ...
        'YColor',[0 0 0], ...
        'YTickMode','manual', ...
        'ZColor',[0 0 0], ...
        'ZTickMode','manual');

    text(0.5,0.5, ['{\color{red}Axes ' num2str(axes_idx) '}'], 'FontSize',12, 'FontWeight','bold', 'HorizontalAlignment','center', 'VerticalAlignment','middle');
    
    handles.(axes_tag) = h1;
end

% put in any user data which needs to go into handles
if isfield(handles, 'user_data')
    handles.user_data.axes_tag_prefix = axes_tag_prefix;
else
    user_data.axes_tag_prefix = axes_tag_prefix;
    handles.user_data = user_data;
end
