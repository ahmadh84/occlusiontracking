function displayImage(handles, threshold)
c = get(handles.axes1, 'Children');
if length(c) > 1
    % dont delete the boundary image on the axes
    if get(handles.boundary_chkbox, 'Value')
        delete(c(2:end-1));
    else
        delete(c(1:end-1));
    end
end

[ tp fn fp ] = getInfoFromGT(handles, threshold);

hold(handles.axes1, 'on');

image(tp+handles.user_data.colorspace_scaling_tp, 'AlphaData', double(tp)*.5, 'Parent', handles.axes1);
image(fn+handles.user_data.colorspace_scaling_fn, 'AlphaData', double(fn)*.5, 'Parent', handles.axes1);
image(fp+handles.user_data.colorspace_scaling_fp, 'AlphaData', double(fp)*.5, 'Parent', handles.axes1);

% incase there is a boundary image rearrange handles
if get(handles.boundary_chkbox, 'Value')
    c = get(handles.axes1, 'Children');
    set(handles.axes1, 'Children', [c(end-1); c([1:end-2 end])]);
end


function [ tp fn fp ] = getInfoFromGT(handles, threshold)

tmpC1 = handles.user_data.posterior >= threshold;

% compute the True/False Positive, True/False Negative
tp = tmpC1 & handles.user_data.gt;
fn = handles.user_data.gt;
fn(tp) = 0;
fp = tmpC1;
fp(tp) = 0;