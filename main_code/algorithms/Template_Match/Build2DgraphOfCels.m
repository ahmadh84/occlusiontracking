function CM = Build2DgraphOfCels( ImgCelIndexes )
% Build a sparse bi-directed graph (ie connection matrix) with 'true' 
% in the matrix marking that cel i is a neighbor of cel j.

% DEBUG
%ImgCelIndexes = Sp2;
%Ids = unique( ImgCelIndexes(:) );  % Handy if the Indexes weren't [1,2,3...].



numCels = max(ImgCelIndexes(:));

rows = size(ImgCelIndexes,1);
cols = size(ImgCelIndexes,2);

South = sparse( ImgCelIndexes(1:rows-1, :), ImgCelIndexes(2:rows, :), 1, numCels, numCels );
% note: Used to have the last param, nzmax = 6 * numCels, but the creation
%       of a sparse matrix fails if that number is smaller than actual
%       non-zeros in the matrix. However, after creation, setting empty
%       points in the matrix to 'true' auto-increases nzmax by 10 - huh!

North = sparse( ImgCelIndexes(2:rows, :), ImgCelIndexes(1:rows-1, :), 1, numCels, numCels );
East = sparse( ImgCelIndexes(:, 1:cols-1), ImgCelIndexes(:, 2:cols), 1, numCels, numCels );
West = sparse( ImgCelIndexes(:, 2:cols), ImgCelIndexes(:, 1:cols-1), 1, numCels, numCels );
% Each of these says row i has a neighbor (eg to the North) with id j.




All = North + South + East + West; % Merge all the neighbor relationships. 
% So if id #5's row looks like this:
% 0 3 0 8 100 9 0 1
% then it means there are 0 #1 pixels next to us, 3x #2 pixels, etc,
% and the 100 is an inflated version of #5's surface area.

%All(  speye(size(All))==1  ) = 0; % Wipe out the self-edges.
% No -leave the self-edges in the graph for now.


% Optional - maybe useful in the future?
%Self = sparse( ImgCelIndexes(:, :), ImgCelIndexes(:, :), 1, numCels, numCels ); % Total number of each Index.
%All = All + Self; % Now the connection matrix has weights for neighbors,
%       and Area to describe each Cel.


% CM = spones(All)  % Changes all entries to 1, but CM is then a sparse
% matrix of doubles.
CM = logical(All);