function show_flow(u,v,c,I1,I2)
[M N] = size(u);
% find robust max flow for better visualization
magnitude = (u.^2 + v.^2).^0.5;  
max_flow = prctile(magnitude(:),95);

tmp = zeros(M,N,2);
tmp(:,:,1) = min(max(u,-max_flow),max_flow);
tmp(:,:,2) = min(max(v,-max_flow),max_flow);
if max(tmp(:)) ~= min(tmp(:))
  subplot(2,2,1), imshow(I1,[0 1]); 
  subplot(2,2,2), imshow(I2,[0 1]); 
  
  subplot(2,2,3), imshow(uint8(flowToColor(tmp)),[]);
  %subplot(2,2,3), imshow(sqrt(tmp(:,:,1).^2 + tmp(:,:,2).^2),[]);
  
  subplot(2,2,4), imshow(c,[-0.01 0.01]); drawnow;
  
end