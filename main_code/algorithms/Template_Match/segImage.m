% segImage by Mori: 
% I_s = segImage(I,S)
%
% I is the color image, each of 3 channels stored as [0,1].
% S = colormap, where each index (ie color) is a unique region or cel
% 
% Output: replace the border pixel of each cel with red [1 0 0].

function I_s = segImage(I,S)
[cx,cy] = gradient(S);
ccc = (abs(cx)+abs(cy))~=0;
I_s = I;
I_s(:,:,1) = max(I_s(:,:,1),ccc);
I_s(:,:,2) = min(I_s(:,:,2),~ccc);
I_s(:,:,3) = min(I_s(:,:,3),~ccc);
