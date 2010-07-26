clear all
test = 0; %1 if you dont have GT labels

noScenes = 18;
dir  = fullfile(pwd, '../data/');

%noScenes = 18;
%dir = 'D:/Oisin/GTFlowData/OpticalFlow/data/train/';

for sceneID = [4 5 9 10 11 12 13 14 17 18 19]
    sceneID
    load([dir num2str(sceneID) '/' num2str(sceneID)])
    clear classAng   resultAng  resultEpe   mask   dis   tuv
    
    if (size(im1,3) > 1)
        im1 = double(rgb2gray(im1));
        im2 = double(rgb2gray(im2));
    else
        im1 = double(im1);
        im2 = double(im2);
    end
    imx = size(im1,1);
    imy = size(im1,2);
    
    % gabour features
    %[ph1 gabMag1] = extractGaborFeatures(im1);
    %[ph2 gabMag2] = extractGaborFeatures(im2);
    
    % compute on pyramid
    scale = 0.8;
    noScales = 10;
    grad = zeros(imx, imy, noScales);
    dt = zeros(imx, imy, noScales);
    xMot = zeros(imx, imy, noScales);
    yMot = zeros(imx, imy, noScales);
    lap = zeros(imx, imy, noScales);
    dil = zeros(imx, imy, noScales);
    im1re = im1;
    
    xba = uvBA(:,:,1);    xtv = uvTV(:,:,1);    xhs = uvHS(:,:,1);    xfl = uvFL(:,:,1);
    yba = uvBA(:,:,2);    ytv = uvTV(:,:,2);    yhs = uvHS(:,:,2);    yfl = uvFL(:,:,2);
    
    for i = [1:noScales]
        % gradient magnitude
        [Dx,Dy] = gradient(im1re);
        grad(:,:,i) = imresize(sqrt(Dx.^2 + Dy.^2), [imx imy]);
        
        % distance transform
        dt(:,:,i) = imresize(bwdist(edge(im1re,'canny')), [imx imy]);
        
        % temporal gradient
        x = median([xba(:) xtv(:) xhs(:) xfl(:)], 2);
        x = reshape(x, size(xba,1), size(xba,2));
        %x = (xba + xtv + xhs + xfl)./4;
        [Dx,Dy] = gradient(x);
        xmag = sqrt(Dx.^2 + Dy.^2);
        xMot(:,:,i) = imresize(xmag, [imx imy]);
        y = median([yba(:) ytv(:) yhs(:) yfl(:)], 2);
        y = reshape(y, size(yba,1), size(yba,2));
        [Dx,Dy] = gradient(y);
        ymag = sqrt(Dx.^2 + Dy.^2);
        yMot(:,:,i) = imresize(ymag, [imx imy]);
        
        %dilate temporal gradient
        se = strel('ball',20, 20);
        dil(:,:,i) = imresize(imdilate(sqrt(xmag.^2 + ymag.^2), se), [imx imy]);
        
        %lapacian
        lapker = [-1 -1 -1; -1 8 -1; -1 -1 -1];
        lap(:,:,i) = imresize(conv2(im1,double(lapker)), [imx imy]);
        
        % downsample
        im1re = imresize(im1re, scale);
        xba  = imresize(xba, scale); xtv  = imresize(xtv, scale); xhs  = imresize(xhs, scale); xfl  = imresize(xfl, scale);
        yba  = imresize(yba, scale); ytv  = imresize(ytv, scale); yhs  = imresize(yhs, scale); yfl  = imresize(yfl, scale);
        
    end
    
    % reprojection error - change to use colour
    nanVal = 100;
    reBA = interp2(im2, repmat([1:imy], imx, 1) + uvBA(:,:,1), repmat([1:imx]',1,imy) + uvBA(:,:,2), 'cubic');
    reTV = interp2(im2, repmat([1:imy], imx, 1) + uvTV(:,:,1), repmat([1:imx]',1,imy) + uvTV(:,:,2), 'cubic');
    reHS = interp2(im2, repmat([1:imy], imx, 1) + uvHS(:,:,1), repmat([1:imx]',1,imy) + uvHS(:,:,2), 'cubic');
    reFL = interp2(im2, repmat([1:imy], imx, 1) + uvFL(:,:,1), repmat([1:imx]',1,imy) + uvFL(:,:,2), 'cubic');
    reBA = abs(im1 - reBA);reBA(isnan(reBA)) = nanVal;
    reTV = abs(im1 - reTV);reTV(isnan(reTV)) = nanVal;
    reHS = abs(im1 - reHS);reHS(isnan(reHS)) = nanVal;
    reFL = abs(im1 - reFL);reFL(isnan(reFL)) = nanVal;
    
    clear im1re xba xtv xhs xfl yba ytv yhs yfl Dx Dy ymag xmag x y
    reproDim = 4; %algs - change to include rgb values
    %dimOfFeature = size(grad, 3)+size(dt, 3)+size(xMot, 3)+size(yMot, 3) + size(lap, 3) + size(dil, 3) + reproDim
    dimOfFeature = size(grad, 3)+size(dt, 3)+size(xMot, 3)+size(yMot, 3) + reproDim;
    data = zeros(imx*imy, dimOfFeature);
    Y = zeros(size(data,1),1);
    
    %starting at top left entry and going across first row until gets to top
    %new row
%     count = 1;
%     for row=1:imx
%         for col=1:imy
%             
%             %data(count,1:dimOfFeature) = [squeeze(dt(row,col,:)); squeeze(grad(row,col,:)); squeeze(xMot(row,col,:)); squeeze(yMot(row,col,:)); squeeze(lap(row,col,:)); squeeze(dil(row,col,:)); reBA(row,col); reTV(row,col); reHS(row,col); reFL(row,col)];
%             data(count,1:dimOfFeature) = [squeeze(dt(row,col,:)); squeeze(grad(row,col,:)); squeeze(xMot(row,col,:)); squeeze(yMot(row,col,:)); reBA(row,col); reTV(row,col); reHS(row,col); reFL(row,col)];
%             
%             % picking EPE
%             if (test ==1)
%                 Y(count) = 1; % test case where up dont have GT
%             else
%                 Y(count) = classEpe(row, col);
%             end
%             count = count+1;
%             
%         end
%     end
    
    % collate the features collected into a single feature vector (row
    %   major order)
    data = cat(3, dt, grad, xMot, yMot, reBA, reTV, reHS, reFL);
    data = permute(data, [2 1 3]);
    data = reshape(data, [imx*imy dimOfFeature]);
    
    % picking EPE
    if (test ==1)
        Y(:,:) = 1; % test case where up dont have GT
    else
        temp = classEpe';
        Y = temp(:);
    end
    
    
    %delete([dir num2str(sceneID) '/' num2str(sceneID) 'fv.mat']);
    save([dir num2str(sceneID) '/' num2str(sceneID) 'fv'], 'data', 'Y')
    clear data Y
end