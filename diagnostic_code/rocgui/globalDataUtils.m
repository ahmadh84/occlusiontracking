function [ varargout ] = globalDataUtils( varargin )
% evaluate function according to the number of inputs and outputs
if nargout(varargin{1}) > 0
    [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
else
    feval(varargin{:});
end



function [ handles ] = reInitImageData( handles )
% resets all the data for all the axes'

% get the current no. of axes
no_axes = length(findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re));

% store the axes image
user_image.im1 = [];
user_image.im2 = [];
user_image.flow = [];
user_image.flow_alternate = [];
user_image.gt = [];
user_image.gt_boundary_mask = [];
user_image.gt_boundary_im = [];
user_image.values = [];
handles.user_data.user_images = repmat(user_image, [no_axes 1]);



function [ handles ] = setBackgroundImageData( i1, i2, uv_gt, handles, axes_no )
assert(axes_no >= 1 && axes_no <= length(handles.user_data.user_images), 'Invalid axes number provided');

handles.user_data.user_images(axes_no).im1 = i1;
handles.user_data.user_images(axes_no).im2 = i2;
handles.user_data.user_images(axes_no).flow = uv_gt;
handles.user_data.user_images(axes_no).gt = (uv_gt(:,:,1)>200 | uv_gt(:,:,2)>200);
handles.user_data.user_images(axes_no).gt_boundary_mask = bwperim(handles.user_data.user_images(axes_no).gt);
handles.user_data.user_images(axes_no).gt_boundary_im = 0.999*repmat(bwperim(handles.user_data.user_images(axes_no).gt_boundary_mask), [1 1 3]);



function [ handles ] = resetOverlayImageData( handles, axes_no )
handles.user_data.user_images(axes_no).values = [];
handles.user_data.user_images(axes_no).flow_alternate = [];



function [ opp_color ] = getOppositeColor( curr_color )
% get opposite contrast color ... good for choosing foreground text color
% given a background

% convert to HSV space
opp_color = rgb2hsv(curr_color);

% turn hue by 180 degrees
opp_color(1) = mod(opp_color(1)+0.25, 1);
% push value by half-way
opp_color(3) = mod(opp_color(3)+0.25, 1);
% invert saturation
% opp_color(2) = 1 - opp_color(2);

% covert back to RGB
opp_color = hsv2rgb(opp_color);

