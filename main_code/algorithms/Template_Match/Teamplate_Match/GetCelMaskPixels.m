function mask = GetCelMaskPixels( IndexMap, iId, minXs, maxXs, minYs, maxYs )
%    Usage:
%    mask = ..
%       GetCelMaskPixels( IndexMap, iId, minXs, maxXs, minYs, maxYs )
%
%  ones: Where the IndexMap == iId
%  zeros: everywhere else
%
%  SIZE of result = 
%    size of specified sub-window (so probably search area within IndexMap)
%               
%
mask = zeros( 1+maxYs - minYs, 1+maxXs-minXs );
mask(    (IndexMap(minYs:maxYs,   minXs:maxXs))==iId          ) = 1;
