function h = flowshow(uv)
%  FLOWSHOW visualizes the flowfield with color coding 
%
%    FLOWSHOW(UV)
	
	h = imshow(flowToColor(uv));

end %  function