function bound = GetCelBoundPixels( IndexMap, iId, minXs, maxXs, minYs, maxYs )
%    Usage:
%    bound = ..
%       GetCelBoundPixels( IndexMap, iId, minXs, maxXs, minYs, maxYs )
%
%  Get the list of boundary pixels that line the inside of this id's
%  indexMap. Note that order of entries is scan-line order.
%               
%
% Make a version of this Cel's local index map, padded with 1 row & col of zero's.
% This way we can paint the boundary-pixels of ID.
id_Cel_expanded = zeros( 3+maxYs - minYs, 3+maxXs-minXs );
id_Cel_expanded(2:end-1, 2:end-1 ) = (IndexMap(minYs:maxYs,   minXs:maxXs))==iId;
bound_Cel = id_Cel_expanded - imerode(id_Cel_expanded, [1 1 1;1 1 1;1 1 1]);
bound_Cel = logical(bound_Cel(2:end-1, 2:end-1));

[boundY boundX] = find(bound_Cel == true);
bound = [boundY boundX];
