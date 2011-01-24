% Sample code for Olga to see that PatchDistPicker() works in Matlab

clear
close all;

ImageDir = '.\Input\';
MATdir = sprintf( '%s*.mat', ImageDir );
MATFiles = dir( MATdir );
PNGdir = sprintf( '%s*.png', ImageDir );
PNGFiles = dir( PNGdir );

for( iFrame = 1:length(MATFiles)-1 )
    %%
    fNameM = sprintf( '%s%s', ImageDir, MATFiles(iFrame).name );
    fNameI = sprintf( '%s%s', ImageDir, PNGFiles(iFrame).name );


    fprintf( '%s\n', fNameI );

    I = im2double(imread( fNameI ));

    iFrameNext = iFrame+1;
    fNameInext = sprintf( '%s%s', ImageDir, PNGFiles(iFrameNext).name );
    Inext = im2double(imread( fNameInext ));

    load( fNameM );     % Loads up a tmp variable Sp2

    Ids = unique( Sp2(:) );  % Handy if the Indexes weren't [1,2,3...].
    numIds = size(Ids,1);

    % ====================================================================
    % Activate the code below to see how the image was split up into tiles.
    % Use the pt-inspection tool in Matlab's figure to find the index of an
    % interesting cel, and enter that index as iId lower down in this code.
    %
    % ====================================================================
        MidPts = zeros( numIds, 2 );
        [m n]  = size(I);

        CM = Build2DgraphOfCels( Sp2 ); % Make the sparse Connection Matrix:
        % CM is 'true' when cel i  is N, S, E, or W of  cel j
    
        %spy(CM); % View the connection matrix.
        for( iId = 1:numIds )
            [Ys Xs] = find(Sp2 == Ids(iId));  % Returns [ (Which rows down)    (Which cols) ]
            MidPts(iId, 1:2) = [sum(Ys) sum(Xs)] / size(Xs,1);
        end
    
        I_sp2 = segImage(I,Sp2);
        % Graph: Overlay the Connection Matrix
        CMlowTri = tril(CM); % Don't need upper triangle (above diag), bec it just repeats edges.


        imshow( I_sp2 );
        hold on;
    
        %numEdges = nnz(CM);
        for( iId = 1:numIds )
            MyNeighbs = find(CMlowTri(iId,:));
            numNeighbs = size(MyNeighbs, 2);
            from = MidPts(iId,:);
            for( iNeighb = 1:numNeighbs )
                to = MidPts(MyNeighbs(iNeighb),:);
                line([from(2) to(2)], [from(1) to(1)]); % Note that line() plots (row, col) ie (y, x).
            end
        end
        hold off;
    
        CelsInGray = Sp2;
        WhereEdges = find( I_sp2(:,:,1) == 1 );
        CelsInGray(WhereEdges) = 0;
        figure, imagesc(CelsInGray);
    % ====================================================================
    % ====================================================================

    %%find the endpoints of the bounding box of each cell
    tic
    c = struct2cell(regionprops(Sp2,'BoundingBox'));
    m = round(cell2mat(c'));
    boundsX = [m(:,1) m(:,1)+m(:,3)-ones(numIds,1)];
    boundsY = [m(:,2) m(:,2)+m(:,4)-ones(numIds,1)];
    toc

    noHits = 5;
    I1 = I(:,:,2);
    I2 = Inext(:,:,2);
    
    tic
    [maxScore movedS movedE] = NSSD(I1, I2, boundsX, boundsY, Sp2, Ids, noHits);
    toc
    
    disp('Displaying Results for 20 Random Cells: ');    
    randIds = ceil(numIds*rand(20,1));
    for( iId = 1:20 )
        bound = GetCelBoundPixels( Sp2, randIds(iId), boundsX(randIds(iId),1), boundsX(randIds(iId),2), boundsY(randIds(iId),1), boundsY(randIds(iId),2) );
        figure(1)
        %   Show where the cel came from:
        Idirty = PaintMovedBoundsOnIm( bound, [boundsY(randIds(iId),1) boundsX(randIds(iId),1)], [0 0], [1], I, 1.0 );
        figure(2)
        Idirty = PaintMovedBoundsOnIm( bound, [boundsY(randIds(iId),1) boundsX(randIds(iId),1)], [movedS(:,randIds(iId)) movedE(:,randIds(iId)) ], [1:4], Inext, maxScore(:,randIds(iId)) );
        disp('Press any key to continue');
        pause;
    end

    disp('Done')

end
clear SearchPadding cropCoordsFullI
clear img_Cel subI
clear scoreMaxs indMaxs scoreMins indMins;
clear moved_E moved_S moved
clear minXs maxXs minYs maxYs;


%%





