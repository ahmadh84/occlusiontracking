function [coords availPadW availPadN] = IndexesToSearchInFullImg(Isize, TmplSize, TmplOrigin, SearchPadding)
%
%  coords = IndexesToSearchInFullImg(Isize, TmplSize, TmplOrigin, SearchPadding)
%  
% We want to search for this template inside a search window of the Image.
% Padding around the template tells us where to look, but crop to I's image
% boundaries (for now).
%    DEV: 
% Isize = size(I)
% TmplSize = size(img_Cel);   % Could be color, that's fine, the 3 is last.
% TmplOrigin = [347 82 ]; % y,x of the Template's "home" pixel
% SearchPadding = [20 20 20 20]   % To the  West, East, North, South

mostW = max(1, TmplOrigin(2) - SearchPadding(1) );
mostE = min(Isize(2), TmplOrigin(2) + TmplSize(2) + SearchPadding(2) );
mostN = max(1, TmplOrigin(1) - SearchPadding(3) );
mostS = min(Isize(1), TmplOrigin(1) + TmplSize(1) + SearchPadding(4) );

coords = [ mostN mostS  mostW mostE ];

if nargout == 3
    availPadW = TmplOrigin(2) - mostW;
    availPadN = TmplOrigin(1) - mostN;
end