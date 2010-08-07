function plotFlowOnAxes( axes_h, axes_no, user_data, handles )
%PLOTFLOWONAXES plots flow on the axes according to the window size
%   available (adjusting the density of flow according to the available
%   space on axes)

    flow_menu_h = findall(handles.roc_gui, 'Tag', [handles.user_data.axes_flow_menu_prefix num2str(axes_no)]);
    algo_menu_h = findall(handles.roc_gui, 'Tag', [handles.user_data.axes_algo_flow_menu_prefix num2str(axes_no)]);
    gt_flow = strcmp(get(flow_menu_h, 'Checked'), 'on');
    algo_flow = strcmp(get(algo_menu_h, 'Checked'), 'on');
    
    assert(~(gt_flow && algo_flow), 'Both GT flow and Algo flow can''t be checked at the same time');
    
    if gt_flow
        flow_im = user_data.flow;
    elseif algo_flow
        flow_im = user_data.flow_alternate;
    else
        return;
    end
    
    assert(~isempty(flow_im), 'The flow selected is unavailable');
    
    sz = get(axes_h, 'Position');
    width_vecs = sz(3) / handles.user_data.pixels_per_flow;
    height_vecs = sz(4) / handles.user_data.pixels_per_flow;

    % get the viewable axis region and adjust the flow vector gaps accordingly
    sz_viewable = axis(axes_h);
    
    % if this is the first time and the bg image is not there
    if all(sz_viewable == [0 1 0 1])
        sz_viewable([2,4]) = sz([3,4]);
    end
    w = round((sz_viewable(2)-sz_viewable(1)) / width_vecs);
    h = round((sz_viewable(4)-sz_viewable(3)) / height_vecs);
    
    if w < 1
        w = 1;
    end
    if h < 1
        h = 1;
    end
    
    [X Y] = meshgrid(1:w:size(flow_im,2), 1:h:size(flow_im,1));
    u = flow_im(1:h:end, 1:w:end, 1);
    v = flow_im(1:h:end, 1:w:end, 2);
    
    % vectorize
    X = X(:);  Y = Y(:);  u = u(:);  v = v(:);
    
    % only remove pixels if GT flow
    if gt_flow
        remove_pixels = (flow_im(:,:,1)>200 | flow_im(:,:,2)>200);
        remove_pixels = remove_pixels(1:h:end, 1:w:end);

        remove_pixels = remove_pixels(:);

        % remove pixels which dont have flow
        X(remove_pixels) = [];
        Y(remove_pixels) = [];
        u(remove_pixels) = [];
        v(remove_pixels) = [];
    end
    
    hold on;
    quiver(X,Y, u, v, 'Parent',axes_h, 2, 'y-', 'Tag',[handles.user_data.axes_flow_prefix num2str(axes_no)]);
    
    % adjust the position of the callbacks
    globalAxesUtils('adjustUicontextmenuCallback', handles);
end

