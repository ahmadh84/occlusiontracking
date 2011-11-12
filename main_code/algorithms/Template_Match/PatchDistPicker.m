function [C movedSE scoreMaxs] = PatchDistPicker(T, A, availPadWN, DistName, imgMaskCel)
% T = img_Cel(:,:,2); A = subI(:,:,2); availPadWN=[availPadW availPadN];
% imgMaskCel=imgMaskCel;
% Compute one of several distance measures (like NCC) between 
%   template T, and
%   search image A,
%   over a range of translations.
%
%       Note about padding and availPadWN:  
% The search area of A is an expanded space, around the last known location
% of T. We need to know how much extra space that is, so that when we find
% a peak, we can subtract off the padding. 
%
% For example: if T didn't move at all, then the pixel in C that sits under
% the lower-right corner of the template has a peak score. 
% That row ==  padN + T's height. Similar for col and padW.

if (nargout >= 3 )
    bFindPeaks = 1;
else
    bFindPeaks = 0;
end


switch (DistName)
    case {'builtinNCC'}
        C = normxcorr2(T, A);
        [C movedSE scoreMaxs] = CompRelMotionVecsMatlabWay( C, T, A, availPadWN );
        return
    case {'builtinNCCsearchInside'}
        C = normxcorr2(T, A);

        % Crop out the part of the result that has ncc's where the
        % WHOLE T was overlapping inside of A. If we wanted to ncc with pixels
        % outside A, we would have padded it ourselves (since there are probably
        % pixels there - A was cut from a larger image, after all).
        [C movedSE scoreMaxs] = CompRelMotionVecsAreaSafe( C, T, A, availPadWN );
        return

    
    case {'plain_ncc'}
        %
        %  Working (checked against normxcorr2) version of NCC that checks only
        %  correlation between all of T and the specified extent of A (ie no
        %  expanded search where the T sticks out beyond A).
        %
        meanT = sum(T(:)) / numel(T);
        Toffset = T - meanT;
        ToffsetSqrd = Toffset.^2;
        SumToffsetSqrd = sum( ToffsetSqrd(:) );     % Same as: sum(sum(Toffset.^2))

        sA = size(A);
        sT = size(T);
        [evalRowsCols] = sA-sT + [1 1];

        C = zeros(evalRowsCols);
        for iRow = 1:evalRowsCols(1)
            for iCol = 1:evalRowsCols(2)
                F= A( iRow : iRow + sT(1)-1, iCol : iCol + sT(2)-1 ); % Now size(F) == size(T)
        %         imshow(F);
        %         pause2(1/30);
                meanF = sum(F(:)) / numel(F);
                Foffset = F - meanF;
                FoffsetSqrd = Foffset.^2;
                SumFoffsetSqrd = sum( FoffsetSqrd(:) );
                numerator = sum(sum(F .* Toffset));
                denom = sqrt( SumFoffsetSqrd * SumToffsetSqrd );
                C(iRow, iCol) = numerator / denom;
            end
        end

        [movedSE scoreMaxs] = CompRelMotionVecsWoPadding( C, availPadWN );
        return
    case {'maskedNCC'}
        %
        % Trying to NCC only the pixels within the real shape of the T!
        %
        sA = size(A);
        sT = size(T);
        imgMaskCelONs = find(imgMaskCel);
        lilT = zeros(sT);
        lilT(imgMaskCelONs) = T(imgMaskCelONs);
        %
        %
        meanT = sum(lilT(:)) / numel(imgMaskCelONs);
        %Toffset = T - meanT;
        Toffset = zeros(sT);
        Toffset(imgMaskCelONs) = T(imgMaskCelONs) - meanT;

        ToffsetSqrd = Toffset.^2;
        SumToffsetSqrd = sum( ToffsetSqrd(:) );     % Same as: sum(sum(Toffset.^2))

        [evalRowsCols] = sA-sT + [1 1];

        C = zeros(evalRowsCols);
        for iRow = 1:evalRowsCols(1)
            for iCol = 1:evalRowsCols(2)
                F= A( iRow : iRow + sT(1)-1, iCol : iCol + sT(2)-1 ); % Now size(F) == size(T)
                lilF = zeros(sT);
                lilF(imgMaskCelONs) = F(imgMaskCelONs);
        %         imshow(F);
        %         pause2(1/30);
                meanF = sum(lilF(:)) / numel(imgMaskCelONs);
                Foffset = zeros(sT);
                Foffset(imgMaskCelONs) = F(imgMaskCelONs) - meanF;
                FoffsetSqrd = Foffset.^2;
                SumFoffsetSqrd = sum( FoffsetSqrd(:) );
                numerator = sum(sum(lilF .* Toffset));
                denom = sqrt( SumFoffsetSqrd * SumToffsetSqrd );
                C(iRow, iCol) = numerator / denom;
            end
        end

        if( bFindPeaks )
            [movedSE scoreMaxs] = CompRelMotionVecsWoPadding( C, availPadWN );
        end
        
        return
    case {'plain_nssd'}  % NOTE!! Negating since this gives _distance_ and we want _closeness_
        % See "Probabilistic fusion of stereo with color and contrast for bi-layer segmentation"
        % by Kolmogorov et al. PAMI06, eq's (11)-(12) and Appendix A
        % They say N0 = 0.3, and lambda = 10.5 +/- 1.5.
        N0 = 0.3;
        lambda = 10.5;
        
        meanT = sum(T(:)) / numel(T);
        Toffset = T - meanT;
        ToffsetSqrd = Toffset.^2;
        SumToffsetSqrd = sum( ToffsetSqrd(:) );     % Same as: sum(sum(Toffset.^2))

        sA = size(A);
        sT = size(T);
        [evalRowsCols] = sA-sT + [1 1];

        C = zeros(evalRowsCols);
        for iRow = 1:evalRowsCols(1)
            for iCol = 1:evalRowsCols(2)
                F= A( iRow : iRow + sT(1)-1, iCol : iCol + sT(2)-1 ); % Now size(F) == size(T)
        %         imshow(F);
        %         pause2(1/30);
                meanF = sum(F(:)) / numel(F);
                Foffset = F - meanF;
                FoffsetSqrd = Foffset.^2;
                SumFoffsetSqrd = sum( FoffsetSqrd(:) );
                
                denom = SumToffsetSqrd + SumFoffsetSqrd;
                difOffsets = Toffset - Foffset;
                difOffsetsSqrd = difOffsets.^2;
                numerator = 0.5 * sum( difOffsetsSqrd(:) );
                
                % N = num / denom;
                C(iRow, iCol) = -lambda * (   (numerator / denom)    - N0);  % NSSD = lambda * (N-N0)
            end
        end

        [movedSE scoreMaxs] = CompRelMotionVecsWoPadding( C, availPadWN );
        return
    case {'masked_nssd'}
        %
        % Trying to NSSD only the pixels within the real shape of the T!
        %
        N0 = 0.3;
        lambda = 10.5;

        sA = size(A);
        sT = size(T);
        imgMaskCelONs = find(imgMaskCel);
        lilT = zeros(sT);
        lilT(imgMaskCelONs) = T(imgMaskCelONs);
        %
        %
        meanT = sum(lilT(:)) / numel(imgMaskCelONs);
        %Toffset = T - meanT;
        Toffset = zeros(sT);
        Toffset(imgMaskCelONs) = T(imgMaskCelONs) - meanT;

        ToffsetSqrd = Toffset.^2;
        SumToffsetSqrd = sum( ToffsetSqrd(:) );     % Same as: sum(sum(Toffset.^2))

        [evalRowsCols] = sA-sT + [1 1];

        C = zeros(evalRowsCols);
        
        % HackToSmallTemplateInPatchDistPicker: failing to assign any real correlation-scores when the
        % template has too few pixels to match. For now: warn + eject when
        % that happens!
        if( size(imgMaskCelONs,1) < 4 )
            movedSE = [-1000 -1000];
            scoreMaxs = -1;   % As a signal that things went wrong here.
            display('HackTooSmallTemplateInPatchDistPicker');
            return
        end
        if( size(imgMaskCelONs,1) > 1600 )      % Should probably do this in scale-space: big poly's tracks ARE useful at top of pyramid.
            movedSE = [-1000 -1000];
            scoreMaxs = -1;   % As a signal that things went wrong here.
            display('HackTooBIGTemplateInPatchDistPicker');
            return
        end

        for iRow = 1:evalRowsCols(1)
            for iCol = 1:evalRowsCols(2)
                F= A( iRow : iRow + sT(1)-1, iCol : iCol + sT(2)-1 ); % Now size(F) == size(T)
                lilF = zeros(sT);
                lilF(imgMaskCelONs) = F(imgMaskCelONs);
        %         imshow(F);
        %         pause2(1/30);
                meanF = sum(lilF(:)) / numel(imgMaskCelONs);
                Foffset = zeros(sT);
                Foffset(imgMaskCelONs) = F(imgMaskCelONs) - meanF;
                FoffsetSqrd = Foffset.^2;
                SumFoffsetSqrd = sum( FoffsetSqrd(:) );
                
                denom = SumToffsetSqrd + SumFoffsetSqrd;
                difOffsets = Toffset - Foffset;
                difOffsetsSqrd = difOffsets.^2;
                numerator = 0.5 * sum( difOffsetsSqrd(:) );
                
                % N = num / denom;
                C(iRow, iCol) = -lambda * (   (numerator / denom)    - N0);  % NSSD = lambda * (N-N0)
            end
        end
        
        if( bFindPeaks )
            [movedSE scoreMaxs] = CompRelMotionVecsWoPadding( C, availPadWN );
        end
        
        return
        
end %switch over DistName





% if nargout < 3
%     return;
% end
%   =====================================================================
%   To get here, must want the distance's heightfield processed for peaks!
%   ======================================================================

end %of Function



%%
%-------------------------------
% Function to handle basic Matlab normxcorr2 which finds ncc even when T
% overlaps A by only one corner pixel.
%
function [C movedSE scoreMaxs] = CompRelMotionVecsMatlabWay( C, T, A, availPadWN )
% Find 1 single biggest peak:
[max_c, imax] = max(abs(C(:)));
[ypeak, xpeak] = ind2sub(size(C),imax(1));
% or
% Find all local maxima:
[scoreMaxs,indMaxs,scoreMins,indMins] = extrema2(C);
[ypeak, xpeak] =ind2sub(size(C), indMaxs ); % returns (row, col) of each of the peaks. For NCC, the top one is 1.0 if perfect.

moved_E = xpeak - size(T,2) - availPadWN(1);   %Peak_col - Templ_width - padW
moved_S = ypeak - size(T,1) - availPadWN(2);   %Peak_row - Templ_height - padN
movedSE = [moved_S moved_E];
end



%-------------------------------
% Improved function to handle Matlab normxcorr2 which finds ncc 
% even when T overlaps A by only one corner pixel. 
%       BUT!!! Now cut out those parts, leaving only full-overlap.
%
function [C movedSE scoreMaxs] = CompRelMotionVecsAreaSafe( C, T, A, availPadWN )
[heightT widthT ] = size(T);
[heightA widthA ] = size(A);
C = C( heightT:heightA, widthT:widthA );

[movedSE scoreMaxs] = CompRelMotionVecsWoPadding( C, availPadWN );

end


% Moved out to its own function file!
% %-------------------------------
% % 	Search region around the T's last know location
% %   must be compensated-for when computing where the peaks happened wrt to
% %   how much the T really moved.
% %
% function [movedSE scoreMaxs] = CompRelMotionVecsWoPadding( C, availPadWN )
% [scoreMaxs,indMaxs,scoreMins,indMins] = extrema2(C);
% [ypeak, xpeak] =ind2sub(size(C), indMaxs );
% 
% moved_E = xpeak - 1 - availPadWN(1);   %Peak_col -Matlab's zero - padW
% moved_S = ypeak - 1 - availPadWN(2);   %Peak_row -Matlab's zero - padN
% movedSE = [moved_S moved_E];
% end