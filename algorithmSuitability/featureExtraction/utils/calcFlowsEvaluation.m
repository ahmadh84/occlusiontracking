clear all

opdir = 'D:/Oisin/GTFlowData/OpticalFlow/data/eval/FlowLib_Baseline/'
ipdir = 'D:/Oisin/GTFlowData/OpticalFlow/data/test/';
for sceneID = [1:12];

seq = {'Yosemite', 'Wooden', 'Urban', 'Teddy', 'Schefflera', 'Mequon', 'Grove', 'Evergreen', 'Dumptruck', 'Basketball', 'Army', 'Backyard'};
im1 = imread([ipdir seq{sceneID} '/frame10.png']);
im2 = imread([ipdir seq{sceneID} '/frame11.png']);


% %%
% 'Black & Anandan 3' 
% cd('Black & Anandan 3')
% uvBA = estimate_flow_ba(im1, im2);
% cd('..');
% 
% 
% 
% %%
% 'TV_L1'
% cd('TV_L1')
% uvTV = tvl1of(im1, im2);
% cd('..');
% 
% 
% 
% %%
% 'Horn & Schunck'
% cd('Horn & Schunck')
% uvHS = estimate_flow_hs(im1, im2,'lambda', 200);
% cd('..');



%%
'FlowLib'
cd('FlowLib')
system(['flow_win_demo -v --flo flow.flo --texture_rescale -l 40 --diffusion --str_tex ' ipdir seq{sceneID} '/frame10.pgm '  ipdir seq{sceneID} '/frame11.pgm'])
uvFL = readFlowFile('flow.flo');
cd('..');

writeFlowFile(uvFL, [opdir seq{sceneID} '/flow10.flo']);
%save([dir 'of/' seq{sceneID}], 'im1', 'im2', 'uvBA', 'uvTV', 'uvHS', 'uvFL');
end




