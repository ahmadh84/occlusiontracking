function [ segment_infos ] = findCentroidAndMeanColors( frame, seg_map, segment_infos, settings )
%FINDCENTROIDANDMEANCOLORS Summary of this function goes here
%   Detailed explanation goes here

    % find segment color means
    for seg_idx = 0:size(segment_infos,1)-1
        [r c] = find(seg_map == seg_idx);
        centroid = [mean(r) mean(c)];
        r = sub2ind([size(frame,1) size(frame,2)], r, c);
        rep_idxs = repmat([1:size(frame,3)-1] * size(frame,1) * size(frame,2), [length(r) 1]);
        im_sec = [r repmat(r, [1 size(frame,3)-1])+rep_idxs];
        im_sec = mean(frame(im_sec), 1);
        
        segment_infos(seg_idx+1, settings.info_cntr_col) = centroid;
        segment_infos(seg_idx+1, settings.info_uclr_col) = im_sec;
    end
end

