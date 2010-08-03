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
user_image.gt = [];
user_image.gt_boundary_mask = [];
user_image.gt_boundary_im = [];
user_image.values = [];
handles.user_data.user_images = repmat(user_image, [no_axes 1]);



function [ handles ] = setBackgroundImageData( i1, i2, mask, handles, axes_no )
assert(axes_no >= 1 && axes_no <= length(handles.user_data.user_images), 'Invalid axes number provided');

handles.user_data.user_images(axes_no).im1 = i1;
handles.user_data.user_images(axes_no).im2 = i2;
handles.user_data.user_images(axes_no).gt = mask;
handles.user_data.user_images(axes_no).gt_boundary_mask = bwperim(handles.user_data.user_images(axes_no).gt);
handles.user_data.user_images(axes_no).gt_boundary_im = 0.999*repmat(bwperim(handles.user_data.user_images(axes_no).gt_boundary_mask), [1 1 3]);
handles.user_data.user_images(axes_no).values = [];