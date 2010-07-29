function [ handles ] = adjustGUIandAxeses(hObject, no_axes, handles)
bottom_ui_height = 100;
top_ui_height = 0;
border_pxls = 20;
aspect_ratio_to_maintain = 1.333;
min_gap = 10;
gui_starting_pos = [ 40 100 ];
axes_tag_prefix = 'roc_axes_';

            %Axes Axes_rows Axes_cols Gui_Width Gui_Height
layouts = [ 1     1         1         850       650;        % for 1 axes
            2     1         2        1200       550;        % for 2 axes
            4     2         2         900       750;        % for 4 axes
            6     2         3        1200       750 ];      % for 6 axes

% delete all old axes handles
axes_h = findall(hObject, '-regexp', 'Tag', [axes_tag_prefix '\d+']);
delete(axes_h);

set(hObject, 'Units', 'pixels');
fig_size = get(hObject, 'Position');

total_avail_height = fig_size(4)-bottom_ui_height-2*border_pxls;
total_avail_width = fig_size(3)-2*border_pxls;

% the layout positioning is from bottom left corner in row major order
% calculate position for each axes
position = zeros(no_axes, 4);
layout_idx = layouts(:,1)==no_axes;
assert(nnz(layout_idx)==1, 'The number of axes demanded is not supported by adjustGUIandAxeses');

% set the GUI position
set(hObject, 'Position', [gui_starting_pos layouts(layout_idx,[4 5])]);

% get the extents where to fit the axes
axes_extents = [ border_pxls, bottom_ui_height+border_pxls, layouts(layout_idx,4)-border_pxls, layouts(layout_idx,5)-top_ui_height-border_pxls ];

[x y] = meshgrid(axes_extents(1):(axes_extents(3)-axes_extents(1))/layouts(layout_idx,3):axes_extents(3), ...
                 axes_extents(2):(axes_extents(4)-axes_extents(2))/layouts(layout_idx,2):axes_extents(4));

tempx = x(1:end-1,1:end-1)'+min_gap/2;
tempy = y(1:end-1,1:end-1)'+min_gap/2;
axes_width = x(1,2)-x(1,1)-min_gap/2;
axes_height = y(2,1)-y(1,1)-min_gap/2;

% fix the height or width according to the aspect ratio
if axes_width/axes_height > aspect_ratio_to_maintain
    axes_width = axes_height * aspect_ratio_to_maintain;
else
    axes_height = axes_width / aspect_ratio_to_maintain;
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

    handles.(axes_tag) = h1;
end

% insert the axes handles into guidata
guidata(hObject, handles);
% 
% a = findall(hObject, '-regexp', 'Tag', [axes_tag_prefix '\d+']);
% for axes_idx = 1:no_axes
%     scene_id = '18';
%     main_dir = 'C:\Users\Ahmad\Documents\UCL\MS Thesis - Tracking powered by Superpixels\Data\oisin+middlebury\';
%     i = im2double(imread(fullfile(main_dir, scene_id, '1.png')));
%     
%     axes_tag = [axes_tag_prefix num2str(axes_idx)];
%     
%     axes(a(axes_idx));
%     imshow(i);
% end