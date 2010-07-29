function [ handles ] = setAxesAndUserData(handles, varargin)
% user init function for creating user data and misc. initialization

user_data.posterior = varargin{2};

% delete the axes images if any
c = get(handles.axes1, 'Children');
delete(c);

% display image and set colormap
imshow(uint8(user_data.im1*user_data.colorspace_scaling_tp));
colormap([linspace(0,1,user_data.colorspace_scaling_tp)'*[1 1 1]; user_data.ctp; user_data.cfn; user_data.cfp]);

threshold = get(handles.threshold_slider, 'Value');

% fit user data in handles
handles.user_data = user_data;

displayImage(handles, threshold);
