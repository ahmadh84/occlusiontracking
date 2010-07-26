dir = 'C:/Documents and Settings/oisinm/My Documents/Programs/OFImplementations/data/';

im1 = double(imread([dir 'frame10.png']));
im2 = double(imread([dir 'frame11.png']));

tuv = readFlowFile([dir 'flow10.flo']);

uv = estimate_flow_ba(im1, im2);

[ae epe] = flowAngErr(tuv(:,:,1), tuv(:,:,2), uv(:,:,1), uv(:,:,2), 0);
ae = reshape(ae, size(im1, 1), size(im1, 2));
epe = reshape(epe, size(im1, 1), size(im1, 2));

imagesc(ae)
figure
imagesc(epe)