function [ similarityOfBest, ...
            AsortedScoreLossIndexes, BsortedScoreLossIndexes, ...
            bBothHaveMatchingMot ] = ...
                HowSimilarAre2ScoredTvecs( AmovedBy, BmovedBy, Ascore, Bscore, ...
                                            distThresh, scoreLossThresh )
% Usage:
% [ similarityOfBest, [[AsortedScoreLossIndexes, BsortedScoreLossIndexes]], [[bBothHaveMatchingMot]] ] = ...
%                 HowSimilarAre2ScoredTvecs( AmovedBy, BmovedBy, Ascore, Bscore, [[distThresh, scoreLossThresh]] )
%
%
%Given 2 vectors, each holding a sorted vec of possible x,y offsets, are 
% these the same motions? They are scored, from most-to-least likely.
%
% Ideally, A's most likely (x,y) offset is the same as B's.
% But maybe B's 2nd-best is identical to A's 1st-best? Or v.v.?
%
% Compare all the As against the best B, and v.v. 
% Is the closest one, close-enough?
% Do the closest ones still have decent scores? Within some %? 
%
% Outputs:
%   - similarityOfBest: Euclidean distance of 1st-ranked vs. 1st-ranked
%   - (complete intermediate similiarity info)
%   - bBothHaveMatchingMot = boolean: does each have a match for the other?
%

difBest = AmovedBy(1,:) - BmovedBy(1,:);
similarityOfBest = norm( difBest, 2 );

if nargout == 1
    return;
end


numAs = size(AmovedBy,1);
numBs = size(BmovedBy,1);

distAtoBestB = zeros(numAs,1);
distBtoBestA = zeros(numBs,1);
lossOfScoreA = (Ascore(1)-Ascore) / Ascore(1);
lossOfScoreB = (Bscore(1)-Bscore) / Bscore(1);

difAtoBestB = AmovedBy - repmat(BmovedBy(1,:), numAs, 1);
for(i = 1:numAs)
    distAtoBestB(i) = norm(difAtoBestB(i,:), 2);    % dist = Euclidean distance
end
[A_sorted_scoreLoss, Aindexes] = sortrows([distAtoBestB lossOfScoreA],1);
% Result: Amovedby and Ascore now re-oredered by similiarity to B's best.
% For example: if Aindexes is [3 1 4...] then A's favorite is 2nd-closest
% to B's best, and A's 3rd-favorite is most like B's best.

difBtoBestA = BmovedBy - repmat(AmovedBy(1,:), numBs, 1);
for(i = 1:numBs)
    distBtoBestA(i) = norm(difBtoBestA(i,:), 2);    % dist = Euclidean distance
end
[B_sorted_scoreLoss, Bindexes] = sortrows([distBtoBestA lossOfScoreB],1);   

AsortedScoreLossIndexes = [A_sorted_scoreLoss, Aindexes];
BsortedScoreLossIndexes = [B_sorted_scoreLoss, Bindexes];

if nargout <= 3
    return;
end


if nargin < 6               % Thresh's weren't specified, so default:
    scoreLossThresh = .10;
    distThresh      = 0.00001;
end
% Now check: is the most similar move VERY similar? Did the score go down
% only a small amount?
AhasMatchForB = A_sorted_scoreLoss(1,1) <= distThresh & ...     % expecting identical motions, to call this a "match"
                A_sorted_scoreLoss(1,2) < scoreLossThresh;      % 10% loss of score is ok?

BhasMatchForA = B_sorted_scoreLoss(1,1) <= distThresh & ...     % expecting identical motions, to call this a "match"
                B_sorted_scoreLoss(1,2) < scoreLossThresh;      % 10% loss of score is ok?

bBothHaveMatchingMot = AhasMatchForB & BhasMatchForA;
            
end

