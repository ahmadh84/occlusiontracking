function [avg_col] = drawAvgColor( seg_map, segment_infos )
%DRAWAVGCOLOR Summary of this function goes here
%   Detailed explanation goes here

    r = zeros(size(seg_map,1), size(seg_map,2));
    g = zeros(size(seg_map,1), size(seg_map,2));
    b = zeros(size(seg_map,1), size(seg_map,2));
    
    for idx = 1:size(segment_infos,1)
        r(seg_map == idx-1) = segment_infos(idx,7);
        g(seg_map == idx-1) = segment_infos(idx,8);
        b(seg_map == idx-1) = segment_infos(idx,9);
    end
    
    avg_col = uint8(cat(3, r, g, b));
end

