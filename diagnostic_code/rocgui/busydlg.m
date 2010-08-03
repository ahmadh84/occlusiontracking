function h = busydlg(msg,title,varargin)
%BUSYDLG Display message box without any user control
%   H = BUSYBAR('message', property, value, property, value, ...) creates
%   and displays a dialog box displaying 'message'.  The handle to the
%   busydlg figure is returned in H. Optional arguments property and value
%   allow to set corresponding busydlg figure properties.
%
%   The dialog window is modal and cannot be closed with the close button.
%   Instead, it needs to be closed in the calling program by executing
%   delete(H). As an emergency alternative, the dialog can be forcibly
%   closed by pressing ctrl-c. To avoid such situation, the use of
%   TRY-CATCH block is recommended (as shown below).
%
%   Example:
%       h = busydlg('Please wait...','My Program');
%       try
%           % computation here %
%       catch
%          delete(h);
%       end
%       delete(h);

%   (c)2008 Takeshi Ikuma {tikuma@hotmail.remove.com}. All rights reserved.

error(nargchk(1,inf,nargin));
if nargin<2, title = ''; end

if ~((ischar(msg) || iscellstr(msg)) && (ischar(title) || iscellstr(title)))
    error('busybar:InvalidInputs', 'First two input arguments must be the message string to be displayed.')
end

try   h = dialog(varargin{:},'Name',title,'CloseRequestFcn','',...
        'KeypressFcn',@keypress);
catch ME
    error('busybar:InvalidInputs','Property and value pair input is not valid for figure object.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

width = 280;
msgwidth = width - 20; % 10-pixel side margins

bgcolor = get(h,'Color');

ui = uicontrol('Parent',h,'Style','text','Position',[10 10 msgwidth 100],...
    'BackgroundColor',bgcolor);

[msg,pos] = textwrap(ui,cellstr(msg));
set(ui,'String',msg,'Position',pos);
set(h,'Position',[0,0,width,pos(4)+20]);

movegui(h,'center');
drawnow;


function keypress(hObj,event)
if isempty(event.Key), return; end
if length(event.Key)==1 && event.Key=='c' && strcmp(event.Modifier,'control')
    closereq;
end
