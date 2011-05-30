function h = flowshow_prctl(uv)
%  FLOWSHOW_PRCTL visualizes the flowfield with color coding 
%
%    FLOWSHOW_PRCTL(UV)
	
	u = uv(:,:,1); v = uv(:,:,2);
		
	magnitude = (u.^2 + v.^2).^0.5;  
	max_flow = prctile(magnitude(:),82);

	tmp = zeros(size(uv));
	tmp(:,:,1) = min(max(u,-max_flow),max_flow);
	tmp(:,:,2) = min(max(v,-max_flow),max_flow);

	h = imshow(flowToColor(tmp));

end %  function

