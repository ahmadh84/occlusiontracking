function [ movedSEout scoreMaxsOut ncc ] = PolyPatchMatchesWhere( Iref, I, PtsYX, SearchPadding, numKeepers, WhatChannels )
% Usage:
%   [ movedSE scoreMaxs ] = PolyPatchMatchesWhere( Iref, I, PtsYX, SearchPadding, numKeepers, WhatChannels )
%
%   Grab the pixels inside the polygon (specified by PtsYX) from Iref.
%   Then see where they moved: correlation measured using
%   PatchDistPicker(), which can be switched among correlation metrics:
%       builtinNCC, builtinNCCsearchInside, plain_ncc, maskedNCC, plain_nssd, masked_nssd
%   The search checks for translation from the poly's starting location, in
%   a window of size SearchPadding. The result is a heightfield of scores,
%   where we return back just the numKeepers (n=3 seems good) best as a
%   pair of: offset (movedSE) and corresponding score (scoreMaxs). 
%
%IN:
%   Iref = I_Prev;      % Copy pixels from here
%   I    = I_Cur;       % Looking for them to match here.
%   PtsYX = Polys{iPoly,1};     % For Left-poly
%   SearchPadding =     [20 20 20 20];
%
%   numKeepers =  5;    % Keep how many peaks in the correlation heightfield?
%
%   WhatChannels = [1 3 5]  % Channels of the Images to consider: each one
%   requires another correlation loop. Currently, these results are added
%   together. Default = [2] ie Green channel.
%
%OUT:
%   movedSE =   how many pixels is each best-correlation suggesting?
%   scoreMaxs =     how good a score if we move the patch that far?
%


    Xs = PtsYX(:,2); 
    Ys = PtsYX(:,1);   % NOTE!! Poly's are stored as (row, col) SO (y, x)!!
        
    % Two equivalent ways to grab the sub-image:
    % Note: added max/min to protect img_Cel below from grabbing invalid pixels.
    minXs = max( floor( min(Xs) ),  1    ); 
    maxXs = min( ceil( max(Xs) ),  size(I,2) );
    minYs = max( floor( min(Ys) ),  1   ); 
    maxYs = min( ceil( max(Ys) ),   size(I,1) );
    img_Cel = Iref(minYs:maxYs,   minXs:maxXs, :);  % Need colRange, rowRange
    % OR
    % upper-left corner, width, height:
    % rect_Cel = [min(Xs)     min(Ys)     max(Xs)-min(Xs)    max(Ys)-min(Ys)];
    % img_Cel = imcrop( I, rect_Cel );  % NOTE: imcrop uses (x,y) NOT (col, row)

    
    [cropCoordsFullI availPadW availPadN] = ...
        IndexesToSearchInFullImg(size(I), size(img_Cel), [minYs minXs], SearchPadding);
    subI = I(cropCoordsFullI(1):cropCoordsFullI(2), cropCoordsFullI(3):cropCoordsFullI(4), :);

    imgMaskOfWholeImg = poly2mask(Xs, Ys, size(I,1), size(I,2));
    imgMaskCel = imgMaskOfWholeImg(minYs:maxYs, minXs:maxXs);

    DistFunName = 'masked_nssd';

    if (nargin < 6 )
        WhatChannels = [2]; % No channel-info specified, so must be old function-call version, where only color was used; must want green.
    end
    numChannels = numel(WhatChannels);

    % Original:            
    if( numChannels ==1 )
        iChannel = WhatChannels(1);
        % Just use green channel for now (ie :,:,2).
        [ncc movedSE scoreMaxs] = ...
            PatchDistPicker( img_Cel(:,:,iChannel), subI(:,:,iChannel), ...
                             [availPadW availPadN], ...
                             DistFunName, ...   % builtinNCC, builtinNCCsearchInside, plain_ncc, maskedNCC, plain_nssd, masked_nssd
                             imgMaskCel );
    else
        dimsOfDistanceMeasureMap = (size(subI) - size(img_Cel) + [1 1 0]);
        DistMeasureMapArr = zeros(dimsOfDistanceMeasureMap(1), dimsOfDistanceMeasureMap(2), numChannels);
        for( iChannel = 1:numChannels)
            DistMeasureMapArr(:,:,iChannel) = ...
                PatchDistPicker( img_Cel(:,:,iChannel), subI(:,:,iChannel), ...
                             [availPadW availPadN], ...
                             DistFunName, ...   % builtinNCC, builtinNCCsearchInside, plain_ncc, maskedNCC, plain_nssd, masked_nssd
                             imgMaskCel );
        end %Endfor over channels we were asked to measure
        C = sum(DistMeasureMapArr, 3);
        %availPadWN=[availPadW availPadN];
        if( max(max(C)) <= 0 )
            movedSE = [-1000 -1000];
            scoreMaxs = -1;   % As a signal that things went wrong here.
        else
            [movedSE scoreMaxs] = CompRelMotionVecsWoPadding( C, [availPadW availPadN] );
        end %Endif to check if PatchDistPicker gave us a valid DistMeasureMap (doesn't if too small/big)
    end
    
                     
%     figure, 
%     surf(ncc), shading flat
    
    %       Raster version of rendering best-finds
    %
    %     bound = GetCelBoundPixels( imgMaskOfWholeImg, 1, minXs, maxXs, minYs, maxYs );
    %     figure;Idirty = PaintMovedBoundsOnIm( bound, [minYs minXs], [0 0], [1], Iref, 1.0 );
    %     figure;Idirty = PaintMovedBoundsOnIm( bound, [minYs minXs], movedSE, [1:5], I, scoreMaxs ); 
    %
    %       Vector version of rendering best-finds
%     BoundPoly = [Ys - minYs  Xs - minXs];
%     figure;Idirty = PlotMovedPolyOnIm( BoundPoly, [minYs minXs], [0 0], [1], Iref, 1.0 );
%     figure;Idirty = PlotMovedPolyOnIm( BoundPoly, [minYs minXs], movedSE, [1:5], I, scoreMaxs ); 


    movedSEout( 1:numKeepers, : ) = NaN;
    scoreMaxsOut( 1:numKeepers, : ) = NaN;

    numPeaks = min(numKeepers, size(scoreMaxs,1) );
    movedSEout = movedSE( 1:numPeaks, : );
    scoreMaxsOut = scoreMaxs( 1:numPeaks, : );

end



