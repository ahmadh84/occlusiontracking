function displayImage(handles, threshold)

[ all_axes_h ] = globalAxesUtils('getAllAxesHandlesSorted', handles);

% iterate over all axes
for idx = 1:length(all_axes_h)
    curr_axes_h = all_axes_h(idx);
    
    % bottom most handle is the background image if:
    has_features = ~isempty(handles.user_data.user_images(idx).values);
    
    % if feature not available then nothing to do
    if ~has_features
        continue;
    end
    
    % delete previous overlay images
    globalAxesUtils('deleteOverlayImages', handles, idx);
    
    % delete any text on the axes
    delete(findall(handles.roc_gui, 'Tag',[handles.user_data.axes_txt_prefix num2str(idx)]));

    % compute the True Positive, False Negatives and False Positives
    [ tp fn fp ] = getInfoFromGT(handles.user_data.user_images(idx), threshold);

    tag_name = get(curr_axes_h, 'Tag');
    
    if ~isempty(handles.user_data.user_images(idx).im1)
        hold(curr_axes_h, 'on');
    end

    % display all the images
    image(tp+handles.user_data.colorspace_scaling_tp, 'AlphaData', double(tp)*.5, 'Parent', curr_axes_h);
    if ~isempty(fn)
        image(fn+handles.user_data.colorspace_scaling_fn, 'AlphaData', double(fn)*.5, 'Parent', curr_axes_h);
    end
    if ~isempty(fp)
        image(fp+handles.user_data.colorspace_scaling_fp, 'AlphaData', double(fp)*.5, 'Parent', curr_axes_h);
    end

    set(curr_axes_h, 'DataAspectRatio', [1 1 1], 'Box','off', 'XColor',get(handles.roc_gui,'Color'), 'YColor',get(handles.roc_gui,'Color'), ...
                'Units','pixels', 'Tag',tag_name, 'XTick',[], 'YTick',[], 'ZTick',[]);
    
    
    % SORT the images on the axes
    
    % get all children
    c = get(curr_axes_h, 'Children');
    
    % get background image
    bg_h = findall(curr_axes_h, 'Tag',[handles.user_data.im_bg_prefix num2str(idx)]);
    
    % get boundary image
    bdry_h = findall(curr_axes_h, 'Tag',[handles.user_data.im_gt_prefix num2str(idx)]);
    
    % get flow image
    flow_h = findall(curr_axes_h, 'Tag',[handles.user_data.axes_flow_prefix num2str(idx)]);
    
    % rest of the images
    i = findall(c, 'Type', 'image');    % filter out any thing other than images
    i(ismember(i, [bg_h bdry_h])) = [];
    
    % set the image order
    set(curr_axes_h, 'Children', [flow_h; bdry_h; i; bg_h]);
end

% adjust the position of the callbacks
globalAxesUtils('adjustUicontextmenuCallback', handles);



function [ tp fn fp ] = getInfoFromGT(user_data, threshold)

tmpC1 = user_data.values >= threshold;

% if GT exists
if ~isempty(user_data.gt)
    % compute the True/False Positive, True/False Negative
    tp = tmpC1 & user_data.gt;
    fn = user_data.gt;
    fn(tp) = 0;
    fp = tmpC1;
    fp(tp) = 0;
else
    % incase GT does not exist
    tp = tmpC1;
    fn = [];
    fp = [];
end