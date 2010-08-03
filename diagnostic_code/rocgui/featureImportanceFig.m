function featureImportanceFig( varargin )
% Plots graph and sets up a custom data tip update function
fig = figure;
a = -16; t = 0:60;
plot(t,sin(a*t))
dcm_obj = datacursormode(fig);
set(dcm_obj, 'Enable','on', 'UpdateFcn',@myupdatefcn)


function txt = myupdatefcn(empt,event_obj)
% Customizes text of data tips

pos = get(event_obj,'Position');
txt = {['Time: ',num2str(pos(1))], ['Amplitude: ',num2str(pos(2))]};
