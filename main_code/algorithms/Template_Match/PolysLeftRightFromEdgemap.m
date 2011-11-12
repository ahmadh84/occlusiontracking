function [ Polys ] = PolysLeftRightFromEdgemap( I_BW )
% Polys = PolysLeftRightFromEdgemap( I_BW )
%   Convert the binary image of edges into discrete chains, then 
%   - fit straight-lines to the edges, forming segments to approximate the chains
%       (tol = 1.5 seems nice)
%   - walking along each edge, build a Poly to the left and right, with
%       width = 3 pixels at the least, normally 1/3 of segment-length
%   - Store Polys so each row is a separate section of some chain, and
%       columns 1 & 2 = [LeftPoly & RightPoly]

    addpath('C:/Users/brostow/code/MatlabMisc/graphCels/');

    
    [edgelist, labelededgeim] = edgelink(I_BW, 10);
    % 2nd argument is minlength.
    
    % Display the edgelists with random colours for each distinct edge 
    % in figure 2
    %     figure(2)
    %     drawedgelist(edgelist, size(I_BW), 1, 'rand', 2); axis off  

    
    % Fit line segments to the edgelists
    %tol = 2.5;
    tol = 1.5;         % Line segments are fitted with maximum deviation from
                     % original edge of 2 pixels.
    %seglist = lineseg(edgelist, tol);  % Was tol == 2
    [ seglist breaklist ] = myLineseg(edgelist, tol);  % Was tol == 2
    % NOTE: probably more useful with tol == 0.5

    % Draw the fitted line segments stored in seglist in figure window 3 with
    % a linewidth of 1 and random colours
    %     figure(3)
    %     drawedgelist(seglist, size(I_BW), 1, 'rand', 3); axis off
    

    polyWidthDef = 7;               % Number of pixels to travel along normal, from contour points.
    %multByLengthForRibScale = 1/3;  % Longer segs should have fatter poly's. No smaller than polyWidthDef.
    multByLengthForRibScale = 0.0001;
    
    RibsToLeftPerSeg = cell( seglist );   % For storing 1 side of the normals that will protrude from our segs.
    %%AnglesToNextNormal = cell( seglist ); 
    numSegs = size(seglist,2);
    for( iSeg = 1:numSegs )
        segs = seglist{iSeg};                           % Actually, segs = all pts of this Segment
        normalsToLeft = normalsToLeftOfPtChain( segs );  % Are unit length.

        %RibsToLeftPerSeg{1, iSeg} = normalsToLeft * polyWidthDef;
        segLengths = diff(breaklist{iSeg});  % How many pixels are being approximated by each segment?
        ribScales = segLengths' * multByLengthForRibScale;
        ribScales = max(polyWidthDef, ribScales); % Don't want search-areas less than 3 pixels wide, and want long segs to be fatter still.
        
        RibLengths = repmat( ribScales, 1, 2);

        numNormals = size(normalsToLeft,1);
        RibsToLeftPerSeg{iSeg} = zeros( 2*(numNormals-1), 2); % 5 normals == 4x2 ribs.
        RibsToRightPerSeg{iSeg} = zeros( 2*(numNormals-1), 2); % 5 normals == 4x2 ribs.

        % Pairs of ribs have lengths and normals. Each length is used twice
        % in row, but normals are used at start or end of seg, as even/odd
        % pattern. Need special treatment for the 1st and last normal? Seems not. 
        %    For example:
        %   (n=normal, l=length): l1[n1,n2], l2[n2,n3], l3[n3,n4], l4[n4,n5]
        
        %         RibsToLeftPerSeg{iSeg}(1:2:end-1,:) = normalsToLeft(1:end-1,:) .* RibLengths(1:end,:);      % l3[n3,n4] - 3rd, 5th, 7th...
        %         RibsToLeftPerSeg{iSeg}(2:2:end,:) = normalsToLeft(2:end,:) .* RibLengths(1:end,:);    % l2[n2,n3] - 2nd, 4th, 6th...

        % Now with segs() +/- pt,
        % so that each odd+even pair is the actual coordinate of the Rib-point.
        RibsToLeftPerSeg{iSeg}(1:2:end-1,:) = segs(1:end-1,:) - normalsToLeft(1:end-1,:) .* RibLengths(1:end,:);    % l3[n3,n4] - 3rd, 5th, 7th...
        RibsToLeftPerSeg{iSeg}(2:2:end,:) = segs(2:end,:) - normalsToLeft(2:end,:) .* RibLengths(1:end,:);          % l2[n2,n3] - 2nd, 4th, 6th...

        RibsToRightPerSeg{iSeg}(1:2:end-1,:) = segs(1:end-1,:) + normalsToLeft(1:end-1,:) .* RibLengths(1:end,:);   % l3[n3,n4] - 3rd, 5th, 7th...
        RibsToRightPerSeg{iSeg}(2:2:end,:) = segs(2:end,:) + normalsToLeft(2:end,:) .* RibLengths(1:end,:);         % l2[n2,n3] - 2nd, 4th, 6th...
    end
    




    % No longer care about # of contiguous segs or edges. We want to move
    % them into a list-of-polygons (actually, polygon pairs: R and L).    
    %First, find out how many we expect:
    numLeftPolys =0; for( iSeg = 1:numSegs ) numLeftPolys = numLeftPolys + size(seglist{iSeg},1)-1; end
    Polys = cell(numLeftPolys, 2);
    iPoly = 0;
    for( iSeg = 1:numSegs )
        eds = edgelist{iSeg};
        breaks = breaklist{iSeg};
        numBreaks = size(breaks,2) - 1;
        ribsL = RibsToLeftPerSeg{iSeg};
        ribsR = RibsToRightPerSeg{iSeg};
        for( iBreak = 1:numBreaks )
            iPoly = iPoly+1;
            ed = eds(breaks(iBreak) : breaks(iBreak+1),: );
            ribPairL = ribsL( 2*iBreak-1 : 2*iBreak,  : );
            ribPairR = ribsR( 2*iBreak-1 : 2*iBreak,  : );
             
            % $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
            PolyOfSegment = [ed; flipud(ribPairL); ed(1,:)];
            area = polyarea( PolyOfSegment(:,2), PolyOfSegment(:,1) );
            if( area < 2 )
                sprintf( 'Applying flip-ribs HACK for Left Poly #%d', iPoly) % Because ribs are probably criss-crossing, making a too-small poly.
                PolyOfSegment = [ed; ribPairL; ed(1,:)];
                %area = polyarea( PolyOfSegment(:,2), PolyOfSegment(:,1) )
            end
            Polys{iPoly, 1} = PolyOfSegment; 
            
            PolyOfSegment = [ed; flipud(ribPairR); ed(1,:)];
            area = polyarea( PolyOfSegment(:,2), PolyOfSegment(:,1) );
            if( area < 2 )
                sprintf( 'Applying flip-ribs HACK for Right Poly #%d', iPoly)
                PolyOfSegment = [ed; ribPairR; ed(1,:)];
                %area = polyarea( PolyOfSegment(:,2), PolyOfSegment(:,1) )
            end
            Polys{iPoly, 2} = PolyOfSegment;
            % $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        end % endof loop over edges between breaks.
        
    end % Endfor over segs -> Poly conversion

end % Endfor function

