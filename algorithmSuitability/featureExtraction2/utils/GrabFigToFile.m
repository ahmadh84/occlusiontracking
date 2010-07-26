function GrabFigToFile( fileName, sizeString )
%
% Usage: GrabFigToFile( fileName, sizeString )
% 
% '-r80'      % Gives 640x480 (small) figure
% '-r130'     % 806 x 636 usable
% '-r140'     % 870 x 686
% '-r142'     % 882 x 695
% '-r145'     % 900 x 709 blocky!
% '-r147'     % 911 x 719        <-- good for making videos
% '-r150'     % 931 x 733
% '-r152'     % 942 x 745
% '-r155'     % 961 x 758       <-- default
% '-r156'     % 967 x 763

if nargin < 2
    sizeString = '-r155';
end


fig=gcf;    

% set BG to white
set(fig, 'color', [1 1 1])
set(fig,'InvertHardcopy','off')

units=get(fig,'units');
set(fig,'units','normalized','outerposition',[0 0 1 1]);
set(fig,'units',units);

%print( gcf, '-dpng', '-r155', pngFileName );
print( gcf, '-dpng', sizeString, fileName ); % 961 x 758
