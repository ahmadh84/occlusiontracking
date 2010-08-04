function plotFlowOnAxes( axes_h, axes_no, user_data, handles )
%PLOTFLOWONAXES Summary of this function goes here
%   Detailed explanation goes here

    sz = get(axes_h, 'Position');
    width_vecs = sz(3) / handles.user_data.pixels_per_flow;
    height_vecs = sz(4) / handles.user_data.pixels_per_flow;

    sz_viewable = axis(axes_h);
    w = round((sz_viewable(2)-sz_viewable(1)) / width_vecs);
    h = round((sz_viewable(4)-sz_viewable(3)) / height_vecs);
    
    if w < 1
        w = 1;
    end
    if h < 1
        h = 1;
    end
    
    remove_pixels = (user_data.flow(:,:,1)>200 | user_data.flow(:,:,2)>200);
    remove_pixels = remove_pixels(1:h:end, 1:w:end);
    
    [X Y] = meshgrid(1:w:size(user_data.im1,2), 1:h:size(user_data.im1,1));
    u = user_data.flow(1:h:end, 1:w:end, 1);
    v = user_data.flow(1:h:end, 1:w:end, 2);
    
    % vectorize
    X = X(:);  Y = Y(:);  u = u(:);  v = v(:);
    remove_pixels = remove_pixels(:);
    
    % remove pixels which dont have flow
    X(remove_pixels) = [];
    Y(remove_pixels) = [];
    u(remove_pixels) = [];
    v(remove_pixels) = [];
    
    hold on;
    quiver(X,Y, u, v, 'Parent',axes_h, 0, 'y-', 'Tag',[handles.user_data.axes_flow_prefix num2str(axes_no)]);
end

