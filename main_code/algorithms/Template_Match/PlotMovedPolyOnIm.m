function Idirty = PlotMovedPolyOnIm ( boundPoly, boundOrigin, moved, whichBs, I, scoreMaxs )

Idirty = I;

minXs = boundOrigin(2);
minYs = boundOrigin(1);
numBoundPts = size(boundPoly,1);

% Technically - this will make each color unique.
% paintColors = flipud(  jet( size(whichBs,2 ))   );
paintColors = flipud(  jet( 12 )   );
numExtraPaints = size(whichBs,2 ) - size(paintColors, 1);

if numExtraPaints > 0
    paintColors(end:end+numExtraPaints,:) = repmat( [0 0 0.5], numExtraPaints+1,1 );    % Some extra entries, so that lots of local minima have a fixe blue'ish color.
end
    
PutTextAt = zeros(  size(whichBs(:),1), 2);


    %figure
    imshow(Idirty)
    hold on


for iMoved = whichBs
    % List of 2D pts; iMoved's relative offset of the boundary points:
    bound_moved = [moved(iMoved,1) + boundPoly(:,1)  moved(iMoved,2) + boundPoly(:,2)];
    bound_movedTo = [bound_moved(:,1) + minYs-1,   bound_moved(:,2) + minXs-1];  % iMoved's absolute offset. 


     sizeI = [size(Idirty,1) size(Idirty,2)];
%     tmpOnes = repmat( 1, numBoundPts,1 );
%     boundPtsIndexesInsideI = find( ...
%         bound_movedTo(:,1) <= sizeI(1) * tmpOnes    & ...
%         bound_movedTo(:,2) <= sizeI(2) * tmpOnes    & ...
%         bound_movedTo(:,1) > 0 * tmpOnes            & ...
%         bound_movedTo(:,2) > 0 * tmpOnes            );
%     

    Xs = boundPoly(:,2);
    Ys = boundPoly(:,1);
    PtsInsideI = find(Xs > 0 & Xs < sizeI(2) & Ys > 0 & Ys < sizeI(1));
    if size(PtsInsideI,1) == 0
        continue
    end    

    %plot( bound_movedTo(:,2), bound_movedTo(:,1), 'g.-' );
    plot( bound_movedTo(:,2), bound_movedTo(:,1), '.-', 'Color', paintColors(iMoved, 1:3) );



%     
%     % Red - set 1x boundOnes to 1
%     IndsToPaint = sub2ind(size(Idirty), bound_movedTo(:,1), bound_movedTo(:,2), boundOnes);
%     %Idirty(IndsToPaint) = boundOnes;
%     Idirty(IndsToPaint) = paintColors(iMoved, 1);
% 
%     % Green - set 2x boundOnes to 0
%     IndsToPaint = sub2ind(size(Idirty), bound_movedTo(:,1), bound_movedTo(:,2), 2*boundOnes);
%     %Idirty(IndsToPaint) = 0*boundOnes;
%     Idirty(IndsToPaint) = paintColors(iMoved, 2);
% 
%     % Blue - set 3x boundOnes to 0
%     IndsToPaint = sub2ind(size(Idirty), bound_movedTo(:,1), bound_movedTo(:,2), 3*boundOnes);
%     %Idirty(IndsToPaint) = 0*boundOnes;
%     Idirty(IndsToPaint) = paintColors(iMoved, 3);
% 


        PutTextAt(iMoved, 1:2) = [2+bound_movedTo(1,2), 2+bound_movedTo(1,1)];

        
% %     myText = sprintf('%d %f', iMoved, scoreMaxs(iMoved) );
% %     %text( 2+bound_movedTo(1,1), 2+bound_movedTo(1,2), 'Hello', 'FontSize',10, 'Color', paintColors(iMoved, 1:3)   );
% %     text( 2+bound_movedTo(1,2), 2+bound_movedTo(1,1), 'Hello', 'FontSize',10, 'Color', paintColors(iMoved, 1:3)   );
end

    hold off

%figure, 
%%imshow(Idirty);
hold on;


if size(PtsInsideI,1) == 0
    myText = sprintf('Cel moved out of bounds of image.');
	text(size(Idirty,2) /2, size(Idirty,1) /2, myText, 'FontSize',8, 'Color', paintColors(iMoved, 1:3)  );
	%return;
end


for iMoved = whichBs
    myText = sprintf('#%d   %.2f', iMoved, scoreMaxs(iMoved) );
    %text( 2+bound_movedTo(1,1), 2+bound_movedTo(1,2), 'Hello', 'FontSize',10, 'Color', paintColors(iMoved, 1:3)   );
    if sum(PutTextAt(iMoved) ) > 0  % Only if the text location was really defined.
        text( PutTextAt(iMoved,1), PutTextAt(iMoved,2), myText, 'FontSize',8, 'Color', paintColors(iMoved, 1:3)   );
    end
end


hold off;


