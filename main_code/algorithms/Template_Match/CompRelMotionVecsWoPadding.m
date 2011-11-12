function [movedSE scoreMaxs] = CompRelMotionVecsWoPadding( C, availPadWN )
%-------------------------------
% Usage: [movedSE scoreMaxs] = CompRelMotionVecsWoPadding( C, availPadWN )
%
% 	Search region around the T's last know location
%   must be compensated-for when computing where the peaks happened wrt to
%   how much the T really moved.
%

[scoreMaxs,indMaxs,scoreMins,indMins] = extrema2(C);
[ypeak, xpeak] =ind2sub(size(C), indMaxs );

moved_E = xpeak - 1 - availPadWN(1);   %Peak_col -Matlab's zero - padW
moved_S = ypeak - 1 - availPadWN(2);   %Peak_row -Matlab's zero - padN
movedSE = [moved_S moved_E];
end

