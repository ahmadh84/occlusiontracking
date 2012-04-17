function [ M ] = imGrowBoundaries( M, s )
%IMGROWBOUNDARIES This function grows images from the boundaries
%   The M returned is of the same class and depth as M passed in the
%   argument. The s can be either scalar or of a vector of size 2. In case
%   of a scalar with a positive value, the boundaries will be replicated s
%   times. In case of a vector the right and left boundaries will be
%   replicated s(1) times and the top and bottom boundaries will be
%   replicated s(2) times.

    if numel(M) > 0
        if numel(s) == 1 && s > 0
            top_section = [ repmat(M(1,1,:), [s s 1]), repmat(M(1,1:end,:), [s 1 1]), repmat(M(1,end,:), [s s 1]) ];
            mid_section = [ repmat(M(1:end,1,:), [1 s 1]), M, repmat(M(1:end,end,:), [1 s 1]) ];
            bot_section = [ repmat(M(end,1,:), [s s 1]), repmat(M(end,1:end,:), [s 1 1]), repmat(M(end,end,:), [s s 1]) ];
            M = vertcat(top_section, mid_section, bot_section);
        elseif numel(s) == 2 && any(s > 0)
            top_section = [ repmat(M(1,1,:), [s(1) s(2) 1]), repmat(M(1,1:end,:), [s(1) 1 1]), repmat(M(1,end,:), [s(1) s(2) 1]) ];
            mid_section = [ repmat(M(1:end,1,:), [1 s(2) 1]), M, repmat(M(1:end,end,:), [1 s(2) 1]) ];
            bot_section = [ repmat(M(end,1,:), [s(1) s(2) 1]), repmat(M(end,1:end,:), [s(1) 1 1]), repmat(M(end,end,:), [s(1) s(2) 1]) ];
            M = vertcat(top_section, mid_section, bot_section);
        end
    end
end
