function [ seg_map_prim, seg_map_sec, matting_alpha, segment_infos ] = refineSegmentation( prv_seg_map_prim, prv_seg_map_sec, other_prv_seg_map_prim, segment_infos, i1, settings )
%REFINESEGMENTATION Summary of this function goes here
%   Detailed explanation goes here

    seg_map_prim = prv_seg_map_prim;
    seg_map_sec = prv_seg_map_sec;
    matting_alpha = ones(size(prv_seg_map_prim));
    
    fprintf(1, '\tComputing segmentation maps for %d pixels\n\t\t', numel(prv_seg_map_prim));
    
    for c = 1:size(prv_seg_map_prim, 2)
        for r = 1:size(prv_seg_map_prim, 1)
            % decrement size of old segment
            prv_seg_id = seg_map_prim(r,c)+1;
            segment_infos(prv_seg_id, settings.info_size_col) = segment_infos(prv_seg_id, settings.info_size_col) - 1;
            
            % find all candidate segments from the neighborhood
            search_window = settings.search_nhood + repmat([r c], [size(settings.search_nhood,1) 1]);
            search_window(search_window(:,1) <= 0 | search_window(:,1) > size(prv_seg_map_prim, 1), :) = [];
            search_window(search_window(:,2) <= 0 | search_window(:,2) > size(prv_seg_map_prim, 2), :) = [];
            search_window = sub2ind(size(prv_seg_map_prim), search_window(:,1), search_window(:,2));
            
            candidate_segs_all = prv_seg_map_prim(search_window);
            candidate_segs = unique(candidate_segs_all);
            
            if length(candidate_segs) == 1
                seg_map_prim(r,c) = candidate_segs;
                seg_map_sec(r,c) = NaN;
                matting_alpha(r,c) = 1;
                
                % increment size of new segment
                segment_infos(seg_map_prim(r,c)+1, settings.info_size_col) = segment_infos(seg_map_prim(r,c)+1, settings.info_size_col) + 1;
            else
                possible_options = nchoosek(candidate_segs, 2);
                
                scores = zeros(size(possible_options,1), 3);
                seg_assgn = zeros(size(possible_options,1), 3);
                
                pixel_color = double(reshape(i1(r,c,:), [size(i1,3) 1]));
                
                for idx = 1:size(possible_options,1)
                    curr_pair = possible_options(idx,:);
                    
                    scores(idx,1) = computeScore1(curr_pair, candidate_segs_all);
                    scores(idx,2) = computeScore2(prv_seg_id, curr_pair, [r c], other_prv_seg_map_prim, segment_infos, settings);
                    [ scores(idx,3) seg_assgn(idx,:) ] = computeAlphaSimilarityScor(curr_pair, segment_infos, pixel_color, settings);
                end
                
                % compute the total product scrore
                scores = scores(:,1) .* scores(:,2) .* scores(:,3);
                [winning_score, pair_idx] = max(scores);
                
                seg_map_prim(r,c) = seg_assgn(pair_idx,1);
                seg_map_sec(r,c) = seg_assgn(pair_idx,2);
                matting_alpha(r,c) = seg_assgn(pair_idx,3);
                
                % increment size of new segment
                segment_infos(seg_assgn(pair_idx,1)+1, settings.info_size_col) = segment_infos(seg_assgn(pair_idx,1)+1, settings.info_size_col) + 1;
            end
            
            no_pixels_done = c*size(prv_seg_map_prim,1)+r;
            if mod(no_pixels_done, 20000) == 0
                fprintf(1, '%d\t', no_pixels_done);
            end
        end
    end
    
    fprintf(1, '\n\t... Done refining Segmentation\n');
end



function [ score ] = computeScore1(candidate_pair, candidate_segs_all)
    score = nnz(candidate_segs_all == candidate_pair(1));
    score = score + nnz(candidate_segs_all == candidate_pair(2));
end


function [ score ] = computeScore2(prv_seg_id, candidate_pair, curr_pos, s2_prim, segment_infos, settings)
    mappings = segment_infos(candidate_pair+1, settings.info_map_col);
    
    curr_pos = curr_pos + round(segment_infos(prv_seg_id, settings.info_of_col));
    
    % find all candidate segments from the neighborhood
    search_window = settings.search_nhood_2 + repmat(curr_pos, [size(settings.search_nhood_2,1) 1]);
    search_window(search_window(:,1) <= 0 | search_window(:,1) > size(s2_prim, 1), :) = [];
    search_window(search_window(:,2) <= 0 | search_window(:,2) > size(s2_prim, 2), :) = [];
    search_window = sub2ind(size(s2_prim), search_window(:,1), search_window(:,2));
    
    candidate_segs_all_2 = s2_prim(search_window);
    
    score = nnz(candidate_segs_all_2 == mappings(1));
    score = score + nnz(candidate_segs_all_2 == mappings(2));
end

function [ score seg_assgnm ] = computeAlphaSimilarityScor(candidate_pair, segment_infos, curr_color, settings)
    mean_clrs = segment_infos(candidate_pair+1, settings.info_uclr_col)';
    p1_p2 = mean_clrs(:,1) - mean_clrs(:,2);
    p_p2 = double(curr_color) - mean_clrs(:,2);
    alpha = pinv(p1_p2) * p_p2;
    
    closest_p = mean_clrs(:,2) + alpha*p1_p2;
    
    seg_assgnm = zeros(1,3);
    
    if alpha <= 0.5
        % p2 is the main segment
        seg_assgnm([1 2]) = candidate_pair([2 1]);
        alpha = 1 - alpha;
        seg_assgnm(3) = alpha;
    else
        % p1 is the main segment
        seg_assgnm([1 2]) = candidate_pair([1 2]);
        seg_assgnm(3) = alpha;
    end
    
    if alpha <= 0
        % p2 is the main and only segment - no alpha matting required
        seg_assgnm(2) = NaN;
        seg_assgnm(3) = 1;
        
        residual_sq = sum((mean_clrs(:,2) - curr_color).^2);
    elseif alpha >= 1
        % p1 is the main and only segment - no alpha matting required
        seg_assgnm(2) = NaN;
        seg_assgnm(3) = 1;
        
        residual_sq = sum((mean_clrs(:,1) - curr_color).^2);
    else
        residual_sq = sum((closest_p - curr_color).^2);
    end
    
    score = exp(-residual_sq / settings.sigma_s^2);
end