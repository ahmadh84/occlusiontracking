addpath([pwd '/utils/']);
imgpath = [pwd '/data/Venus/'];
I0 = imread([imgpath 'frame10.png']); I1 = imread([imgpath 'frame11.png']);

%% estimates the motion minimizing the model 
%% L2+(reweighted-L1)+(weighted-TV)
[uv e] = estimate_flow_L2_rwL1_wTV_nesterov(I0, I1);
