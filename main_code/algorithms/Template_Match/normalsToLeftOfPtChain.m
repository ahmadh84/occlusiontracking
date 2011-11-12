function normalsToLeft = normalsToLeftOfPtChain( segs )
% function normalsToLeft = normalsToLeftOfPtChain( segs )
%
% Use edgelink, and maybe approximate those edges with poly-lines (within some tolerance)
% to make a segs that looks like this:
%     segs: [ r1 c1;  
%             r2 c2; 
%             ...     ]
%
%   then, this function returns the _normalized_ offset from each
%   point in the chain to that pt's normal vector. The normal vector
%   is the average of how a pt's next- and previous- edges are oriented.
%
%   If segs is a loop (ie last point and first are identical), this is
%   trivial. When the chain of segs doesn't form a loop, then the normal
%   comes from assuming that the ends of the chain are just linearly
%   extrapolated.
%
%   Output: to get pts that are length 1 away from our chain to the left,
%   just (segs + normalsToLeft). Normals to the right: subtract instead.
%
%   GJB

    bLoop = sum(abs(segs(1,:) - segs(end,:))) < 0.000001; % Check if the last point closes a loop.
    %plot( segs(:,1),segs(:,2), 'x-' )
    
    % PaddedSegs adds 2pts, 1 on each end of the array,
    % so that the Normal is always computed based on 3pts at a time:
    PaddedSegs = [0 0; segs; 0 0];
    if( bLoop )
        PaddedSegs(1,:) = segs(end-1,:);    % segs' 1st is same as end, so 0th keeps going backward to -1
        PaddedSegs(end,:) = segs(2,:);      % similar: seg's end == 1st, so next comes segs' 2nd.
    else
        PaddedSegs(1,:) = segs(1,:) - (segs(2,:) - segs(1,:));
        PaddedSegs(end,:) = segs(end,:) + (segs(end,:) - segs(end-1,:));
    end
    % Note: first and last are just linear extrapolations if not a loop.

    % PaddedVecs contains the offset vec to step along the path of pts.
    PaddedVecs = zeros(size(PaddedSegs));
    PaddedVecs(1:end-1, :) = PaddedSegs(2:end,:) - PaddedSegs(1:end-1,:);
    PaddedVecs(end,:) = PaddedVecs(end-1,:);    % Again, linear extrap.

    % PaddedNormals will have each pt's normal when considering only that
    % pt's next neighbor. Ex. for 3 pts A,B,C, the normal at B is just -90 deg
    % rotation of the vector from B to C. (Note AveNormals below where the
    % normal at B will also be 50% based on A's influence)
    % To get -90 deg rotation, could apply [cos -sin; sin cos] which gives:
    % x' = y, and y' = -x:
    PaddedNormals = [PaddedVecs(:,2), -PaddedVecs(:,1)];
    PaddedNormals = normaliz(PaddedNormals);
    AveNormals = normaliz((PaddedNormals(2:end-1, :) + PaddedNormals(1:end-2, :)) * 0.5);   % Interpolate pairs if normals, 
                                                        % re-normalize because A/2 + B/2 lies on half-way, not on unit circle.
    normalsToLeft = AveNormals;

    debug = 0;
    
    % Debug code: 
    if( debug )
        PtsPlusNormals = PaddedSegs(2:end-1,:) + AveNormals;
        OppositePtsPlusNormals = PaddedSegs(2:end-1,:) - AveNormals;

        figure
        axis ij % So that the y-axis is top-left, and pts stored as (row, col) are NOT flipped around by plot(x,y) 
        hold on
        plot( PaddedSegs(:,2),PaddedSegs(:,1), 'bx-' )  % pts stored as (row, col), so this is actually plot(x,y)
        plot( PtsPlusNormals(:,2), PtsPlusNormals(:,1), 'r.' )
        plot( OppositePtsPlusNormals(:,2), OppositePtsPlusNormals(:,1), 'g.' )
        hold off
    end