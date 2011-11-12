function [ output_args ] = Untitled( input_args )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


I_Prev = im2double(imread( 'C:\Users\brostow\data\CambridgeTraffic\CambridgeTraffic_framesAll_small\HillsRdSkipFrames_0000131.png' ));
I_Cur = im2double(imread( 'C:\Users\brostow\data\CambridgeTraffic\CambridgeTraffic_framesAll_small\HillsRdSkipFrames_0000132.png' ));


I_Diff = I_Cur-I_Prev;
diff_3colors_Normed = (I_Diff + 1)/2;
figure( 'Name', 'Green'); surf( diff_3colors_Normed(:,:,2) )
% or
% figure( 'Name', 'Green'); surf( diff_3colors_Normed(200:360,1:300,2) )
I_BW = edge(diff_3colors_Normed(:,:,2),'canny');
%[I_MapConnectedComps, numCCs] = bwlabel(I_BW,8);
%figure; imagesc(I_MapConnectedComps);

addpath('C:\Users\brostow\code\in\PeterKovesi\LineSegments');
%% ===========================================
%
 Polys = PolysLeftRightFromEdgemap( I_BW );  % All but last 3 points in each poly are from the Edgemap.
%  
%=========

% Just plots left + right poly's, as green and red respectively.
% 
% figure
% imshow(I_Cur)
% hold on
% numPolys = size(Polys,1);
% for( iPoly = 1:numPolys )
%     ptsToLeft = Polys{iPoly,1};
%     plot( ptsToLeft(:,2), ptsToLeft(:,1), 'g.-' )
% 
%     ptsToRight = Polys{iPoly,2};
%     plot( ptsToRight(:,2), ptsToRight(:,1), 'r.-' )
% end
% hold off




SearchPadding = [20 20 20 20];
numKeepers = 5;     % How many best-correlated translations to keep.

WholeImgPolys_MovedSE = cell(size(Polys));
WholeImgPolys_ScoresMax = cell(size(Polys));
numPolys = size(Polys,1);
for( iPoly = 1:numPolys )
    % First look how the Left poly moved:
    display( iPoly );
    if( iPoly == 64 )
        keyboard();
    end;
    [ movedSE scoreMaxs ] = PolyPatchMatchesWhere(I_Prev, I_Cur, Polys{iPoly,1}, SearchPadding, numKeepers);
    WholeImgPolys_MovedSE{iPoly, 1} =   movedSE;
    WholeImgPolys_ScoresMax{iPoly, 1} = scoreMaxs;

    % Now check the Right poly's motion:
    [ movedSE scoreMaxs ] = PolyPatchMatchesWhere(I_Prev, I_Cur, Polys{iPoly,2}, SearchPadding, numKeepers);
    WholeImgPolys_MovedSE{iPoly, 2} =   movedSE;
    WholeImgPolys_ScoresMax{iPoly, 2} = scoreMaxs;
end






    
    MovedFigID = randi(100000);
    h = figure(MovedFigID);%, 'Name', 'Polygon-pair Motion');
    set(h, 'Name', 'Polygon-pair Motion', 'NumberTitle','off');
    %imagesc((I_Diff+2)/3);
    imshow(I_Cur)
    hold on    
    %for( iPoly = 192)
    for( iPoly = 1:numPolys )
        %display( iPoly );

        movedLby = WholeImgPolys_MovedSE{iPoly, 1}; %         movedLby = WholeImgPolys_MovedSE{iPoly, 1}(1,:);
        movedRby = WholeImgPolys_MovedSE{iPoly, 2};
        scoresL = WholeImgPolys_ScoresMax{iPoly, 1};
        scoresR = WholeImgPolys_ScoresMax{iPoly, 2};
        
        [ similarityOfBest, AsortedScoreLossIndexes, BsortedScoreLossIndexes, bLeftHasAZeroMot ] = HowSimilarAre2ScoredTvecs( movedLby, [0 0], scoresL, 1.0, ...
                                            1.00001, 0.10 );
        [ similarityOfBest, AsortedScoreLossIndexes, BsortedScoreLossIndexes, bRightHasAZeroMot ] = HowSimilarAre2ScoredTvecs( movedRby, [0 0], scoresR, 1.0, ...
                                            1.00001, 0.10 );                                        
        [ similarityOfBest, AsortedScoreLossIndexes, BsortedScoreLossIndexes, ...
                        bBothHaveMatchingMot ] = HowSimilarAre2ScoredTvecs( movedLby, movedRby, scoresL, scoresR, ...
                                            0.00001, 0.10 );
        [ similarityOfBest, AsortedScoreLossIndexes, BsortedScoreLossIndexes, ...
                        bBothHaveSimilarMot ] = HowSimilarAre2ScoredTvecs( movedLby, movedRby, scoresL, scoresR, ...
                                            1.00001, 0.20 );

        % It only qualifies as zero-motion if it was actually a good match there.
        threshMinScoreToBeStatic = 2.5;
        if(scoresL(1) > threshMinScoreToBeStatic)               matchQualL =  scoresL(1) - threshMinScoreToBeStatic;
        else            matchQualL = 0;                         end
        if(scoresR(1) > threshMinScoreToBeStatic)               matchQualR =  scoresR(1) - threshMinScoreToBeStatic;
        else            matchQualR = 0;                         end

        bLeftHasAZeroMot = bLeftHasAZeroMot && matchQualL;
        bRightHasAZeroMot = bRightHasAZeroMot && matchQualR;

        %worstScoreOf2 = minWholeImgPolys_ScoresMax{iPoly, iLeftRight}(1);
        matchQualBoth = [matchQualL matchQualR]
        for( iLeftRight = 1:2 )     % Loop over left and right polys:
            movedBy = WholeImgPolys_MovedSE{iPoly, iLeftRight}(1,:);
            scored = WholeImgPolys_ScoresMax{iPoly, iLeftRight}(1);
            if( size(WholeImgPolys_ScoresMax{iPoly, iLeftRight},1) >=2 )     % Only if there really is a 2nd best peak.
                scored2 = WholeImgPolys_ScoresMax{iPoly, iLeftRight}(2);
            else
                scored2 = -999.0;
            end
            
            matchQual = matchQualBoth(iLeftRight);
            if( ~matchQual )                continue;            end
            
            color = [ 0 0 0 ];
            if( bLeftHasAZeroMot + bRightHasAZeroMot == 1 )     %   Only one or the other is stationary
                color(1) = 1;   continue;
            elseif( bLeftHasAZeroMot + bRightHasAZeroMot == 2 ) %   Both are stationary.
                color(1) = 0.5;     continue;
            
            elseif( bBothHaveMatchingMot )   
                color(2) = 1;
            elseif( bBothHaveSimilarMot )
                color(2) = 0.5;
            elseif( matchQualBoth(iLeftRight) < (3.0-threshMinScoreToBeStatic) )
                continue;
            else
                color(3) = 0.9;
            end
%             if( scored > 3.0 )  color(3) = max(0, WholeImgPolys_ScoresMax{iPoly, iLeftRight}(2) / scored);  end % max() bec could go negative!
%            if( movingL + movingR == 0 )                color(3) = 1;            end
    
            poly = Polys{iPoly, iLeftRight};     % Left = Polys{iPoly,1}
            PlotPolyInFig( poly, MovedFigID, ...
                color, ... % '');
                sprintf('#%d (%d %d) = %.2f\n                        %.2f', iPoly, movedBy(2), movedBy(1), scored, scored2)   );   % ( polyYX, figNo, color, annotText )
        end %Endfor over Left and Right

    end % End forloop over all Polys
    hold off
    
    
iPoly = 
[WholeImgPolys_MovedSE{iPoly, 1} WholeImgPolys_ScoresMax{iPoly, 1};
NaN NaN NaN;
WholeImgPolys_MovedSE{iPoly, 2} WholeImgPolys_ScoresMax{iPoly, 2}]
    


end

