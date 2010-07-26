function showFlowQuivers( uv )
%SHOWFLOWQUIVERS Summary of this function goes here
%   Detailed explanation goes here

    img = flowToColor(uv);

    [c r] = meshgrid(1:size(uv,2), 1:size(uv,1));
    
    imshow(img);
    hold on;
    
    u = uv(:,:,1);
    v = uv(:,:,2);
    
    quiver(c, r, u, v);
end

