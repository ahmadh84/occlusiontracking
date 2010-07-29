function axesGlobalFuncs( varargin )
feval(varargin{:});


function setImageForAllAxes( handles )
%SETIMAGEFORALLAXES Summary of this function goes here
%   Detailed explanation goes here

a = findall(gcf, '-regexp', 'Tag', handles.user_data.axes_search_re);
for axes_idx = 1:length(a)
    tag_name = get(a(axes_idx), 'Tag');
    
    image(uint8(rgb2gray(handles.user_data.im1) * handles.user_data.colorspace_scaling_tp), 'Parent',a(axes_idx));
    
    colormap([linspace(0,1,handles.user_data.colorspace_scaling_tp)'*[1 1 1]; 
              handles.user_data.ctp; handles.user_data.cfn; handles.user_data.cfp]);
    
    % set the axes properties
    set(a(axes_idx), 'Box','off', 'XColor',get(handles.roc_gui,'Color'), 'YColor',get(handles.roc_gui,'Color'), ...
        'Units','pixels', 'Tag',tag_name, 'XTick',[], 'YTick',[], 'ZTick',[]);
end

% adjust the uicontextmenu handles
adjustUicontextmenuCallback( handles );



function adjustUicontextmenuCallback( handles )

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

