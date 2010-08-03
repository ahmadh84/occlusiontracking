function displayImage(handles, threshold)
% find all the axes
all_axes_h = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re);

% sort by axes no.
[temp sorted_idx] = sort(cellfun(@(x) str2num(x{1}{1}), regexp(get(all_axes_h, 'Tag'), '(\d+)$', 'tokens')));
all_axes_h = all_axes_h(sorted_idx);

% iterate over all axes
for idx = 1:length(all_axes_h)
    curr_axes_h = all_axes_h(idx);
    c = get(curr_axes_h, 'Children');
    
    c = findall(c, 'Type', 'image');    % filter out any thing other than images
    
    % bottom most handle is the background image if:
    has_background = ~isempty(handles.user_data.user_images(idx).im1);
    has_features = ~isempty(handles.user_data.user_images(idx).values);
    
    % if feature not available then nothing to do
    if ~has_features
        continue;
    end
    
    if ~isempty(c)
        % dont delete the boundary image on the axes
        if get(handles.boundary_chkbox, 'Value')
            % delete the lower image only if the background has not been set
            delete(c(2:end-has_background));
        else
            % delete the lower image only if the background has not been set
            delete(c(1:end-has_background));
        end
    end

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
    
    % incase there is a boundary image rearrange handles
    if get(handles.boundary_chkbox, 'Value')
        c = get(curr_axes_h, 'Children');
        c = findall(c, 'Type', 'image');    % filter out any thing other than images
        set(curr_axes_h, 'Children', [c(end-1); c([1:end-2 end])]);
    end
end

% adjust the position of the callbacks
axesGlobalFuncs('adjustUicontextmenuCallback', handles);



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