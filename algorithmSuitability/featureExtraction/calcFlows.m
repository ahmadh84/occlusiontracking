clear all

test = 0; % if 1 no GT
dir  = fullfile(pwd, '../data/');
sceneID = 18;

im1 = imread([dir num2str(sceneID) '/1.png']);
im2 = imread([dir num2str(sceneID) '/2.png']);

addpath('utils/flow-code-matlab/');
addpath('algorithms/Black & Anandan 3/');
addpath('algorithms/Black & Anandan 3/utils/');
addpath('algorithms/TV_L1/');
addpath('algorithms/Horn & Schunck/');

%% calc flow
% uvBA = estimate_flow_ba(im1, im2);
% uvTV = tvl1of(im1, im2);
% uvHS = estimate_flow_hs(im1, im2,'lambda', 200);
imwrite(im1, [dir num2str(sceneID) '/1.pgm']);
imwrite(im2, [dir num2str(sceneID) '/2.pgm']);
% system(['convert ' dir num2str(sceneID) '/1.png ' dir num2str(sceneID) '/1.pgm']);
% system(['convert ' dir num2str(sceneID) '/2.png ' dir num2str(sceneID) '/2.pgm']);
cd('algorithms/FlowLib')
system(['flow_win_demo -v --flo flow.flo --texture_rescale -l 40 --diffusion --str_tex "' dir num2str(sceneID) '/1.pgm" "'  dir num2str(sceneID) '/2.pgm"'])
uvFL = readFlowFile('flow.flo');
delete('flow.flo');
cd('../..')
delete([dir num2str(sceneID) '/1.pgm']);
delete([dir num2str(sceneID) '/2.pgm']);


%%
if (test == 0)
    % compute GT error
    tuv = readFlowFile([dir num2str(sceneID) '/1_2.flo']);
    [angBA epeBA] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvBA(:,:,1), uvBA(:,:,2));
    [angTV epeTV] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvTV(:,:,1), uvTV(:,:,2));
    [angHS epeHS] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvHS(:,:,1), uvHS(:,:,2));
    [angFL epeFL] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvFL(:,:,1), uvFL(:,:,2));
    
    % get the best class label for each point - Ang
    noClasses = 4;
    imgMat = zeros(size(im1,1)*size(im1,2),noClasses);
    imgMat(:,1) = angBA(:);
    imgMat(:,2) = angTV(:);
    imgMat(:,3) = angHS(:);
    imgMat(:,4) = angFL(:);
    
    [resultAng classAng] = min(imgMat,[],2);
    classAng = reshape(classAng, size(im1,1), size(im1,2));
    resultAng = reshape(resultAng, size(im1,1), size(im1,2));
    
    % get the best class label for each point - End point
    imgMat(:,1) = epeBA(:);
    imgMat(:,2) = epeTV(:);
    imgMat(:,3) = epeHS(:);
    imgMat(:,4) = epeFL(:);
    
    [resultEpe classEpe] = min(imgMat,[],2);
    classEpe = reshape(classEpe, size(im1,1), size(im1,2));
    resultEpe = reshape(resultEpe, size(im1,1), size(im1,2));
    
    % find the distance between first and second best score
    [vals ind] = sort(imgMat, 2);
    dis = vals(:,2) - vals(:,1);
    dis = reshape(dis, size(im1,1), size(im1,2));
    
    %GT mask
    mask = loadGTMask( tuv, 10 );
    
    %Average Epe
    pts = sum(sum(mask));
    ba = sum(epeBA(mask))/pts
    tv = sum(epeTV(mask))/pts
    hs = sum(epeHS(mask))/pts
    fl = sum(epeFL(mask))/pts
    opt = sum(resultEpe(mask))/pts
    
    save([dir num2str(sceneID) '/' num2str(sceneID)], 'uvBA', 'uvTV', 'uvHS', 'uvFL', 'classAng', 'resultAng', 'classEpe', 'resultEpe', 'mask', 'dis', 'im1', 'im2', 'tuv');
else
    save([dir num2str(sceneID) '/' num2str(sceneID)], 'uvBA', 'uvTV', 'uvHS', 'uvFL', 'im1', 'im2');
end
clear  uvBA   uvTV   uvHS   uvFL   classAng   resultAng   classEpe   resultEpe   mask   dis   im1   im2 tuv
