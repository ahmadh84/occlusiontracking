clear all
clc

noScenes = 19;
dir = 'C:/Projects/ensembleOF/Data/OpticalFlow/data/train/';
opdir = 'C:/Projects/ensembleOF/runs/OF/epe2/';
for sceneID = [1:noScenes]
    
    load([dir num2str(sceneID) '/' num2str(sceneID)])
    noPixels = sum(mask(:));
    
    imx = size(im1,1);
    imy = size(im1,2);
    
    [angBA epeBA] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvBA(:,:,1), uvBA(:,:,2));
    [angTV epeTV] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvTV(:,:,1), uvTV(:,:,2));
    [angHS epeHS] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvHS(:,:,1), uvHS(:,:,2));
    [angFL epeFL] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvFL(:,:,1), uvFL(:,:,2));

    ba = (epeBA.*mask)';
    dlmwrite([opdir num2str(sceneID) '_1.data'], ba(:));
    tv = (epeTV.*mask)';
    dlmwrite([opdir num2str(sceneID) '_2.data'], tv(:));
    hs = (epeHS.*mask)';
    dlmwrite([opdir num2str(sceneID) '_3.data'], hs(:));
    fl = (epeFL.*mask)';
    dlmwrite([opdir num2str(sceneID) '_4.data'], fl(:));
    
end