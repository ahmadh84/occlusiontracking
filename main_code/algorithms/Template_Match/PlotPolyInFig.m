function [ output_args ] = PlotPolyInFig( polyYX, figNo, color, annotText )
%Usage:
%   PlotPolyInFig( polyYX, figNo, color, annotText );
% where the 
%   - polyYX is Nx2 list of pts of closed polygon,
%   - figNo is an existing figure handle, hopefully with    hold on
%   
%   
output_args = 1;

figure( figNo );
plot( polyYX(:,2), polyYX(:,1), '.-', 'Color', color );

%[longest, iLongest] = max(sum(abs(diff(polyYX)),2));     % Found the end-pt of the longest section of the polygon.
iLongest = size(polyYX,1) - 2;  % Hack/shortcut, just to make labels appear in the middle of the 1 edge between the ribs, opposite the real seg.

% Now go half way from the start-pt of that longest section:
midPt = polyYX(iLongest,:) + 0.5 * (polyYX(iLongest+1,:) - polyYX(iLongest,:));

text( 1+ midPt(2), 1+ midPt(1), annotText, 'FontSize',9, 'Color', color   );

end

