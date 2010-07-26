function [ segment_infos_1 ] = refineOpticalFlow( prv_seg_map_prim, prv_seg_map_sec, other_prv_seg_map_prim, segment_infos_1, segment_infos_2, f1, f2, settings )
%REFINEOPTICALFLOW Summary of this function goes here
%   Detailed explanation goes here

    avg_color_diffs = zeros(size(segment_infos_1,1), 1);

    fprintf(1, '\tComputing advected average color difference for each of the %d segments\n', size(segment_infos_1,1));
    
    for idx = 1:size(segment_infos_1,1)
        curr_seg_id = idx-1;
        seg_mask_1 = prv_seg_map_prim == curr_seg_id;
        of = segment_infos_1(idx, settings.info_of_col);
        
        avg_color_diffs(idx) = selectSegmentMinAdvect(seg_mask_1, of, f1, f2, settings);
    end
    
    fprintf(1, '\tComputing %d segment mappings\n\t\t', size(segment_infos_1,1));
    
    winning_scores = zeros(size(segment_infos_1,1), 1);
    
    for idx = 1:size(segment_infos_1,1)
        curr_seg_id = idx-1;
        seg_mask_1 = prv_seg_map_prim == curr_seg_id;
        [ seg_2_ids ] = getNeighboringSegments( seg_mask_1, other_prv_seg_map_prim, settings );
        
        scores = zeros(length(seg_2_ids), 3);
        
        for idx2 = 1:length(seg_2_ids)
            other_seg_id = seg_2_ids(idx2);
            
            scores(idx2,1) = computeColorSimilarityScore(segment_infos_1(curr_seg_id+1,:), segment_infos_2(other_seg_id+1,:), settings);
            scores(idx2,2) = computeSizeSimilarityScore(segment_infos_1(curr_seg_id+1,:), segment_infos_2(other_seg_id+1,:), settings);
            scores(idx2,3) = computeRegularizationScore(segment_infos_1(curr_seg_id+1,:), segment_infos_1, segment_infos_2, other_seg_id, settings);
        end
        
        % compute the total product scrore
        scores = scores(:,1) .* scores(:,2) .* scores(:,3);
        [winning_scores(idx), mtu_k] = max(scores);
        mtu_k = seg_2_ids(mtu_k);
        
        segment_infos_1(idx, settings.info_map_col) = mtu_k;
        segment_infos_1(idx, settings.info_of_col) = segment_infos_2(mtu_k+1, settings.info_cntr_col) - segment_infos_1(idx, settings.info_cntr_col);
        
        if mod(idx,100) == 0
            fprintf(1, '%d\t', idx);
        end
    end
    
    fprintf(1, '\n\tRegularizing OF for %d segments\n', size(segment_infos_1,1));
    
    for idx = 1:size(segment_infos_1,1)
        curr_seg_id = idx-1;
        seg_mask_1 = prv_seg_map_prim == curr_seg_id;
        
        [ seg_ids ] = getAdjacentSegments( seg_mask_1, prv_seg_map_prim, settings );
        
        seg_ids = [seg_ids; curr_seg_id] + 1;
        [min_diff, k] = min(avg_color_diffs(seg_ids));
        k = seg_ids(k);
        
        segment_infos_1(idx, settings.info_of_col) = segment_infos_1(k, settings.info_of_col);
    end
    
    fprintf(1, '\t... Done refining OF\n');
end


function [ seg_2_ids ] = getNeighboringSegments( seg_mask, other_im_seg_map, settings )
    search_mask = imdilate(seg_mask, settings.ofrefine_psb_segs_dilation);
    seg_2_ids = other_im_seg_map(search_mask);
    seg_2_ids = unique(seg_2_ids);
end



function [ score ] = computeColorSimilarityScore(seg_info_1, seg_info_2, settings)
    clr_diff_sq = seg_info_1(:,settings.info_uclr_col) - seg_info_2(:,settings.info_uclr_col);
    % (\Delta C)^2
    clr_diff_sq = sum(clr_diff_sq.^2);
    
    % e^{-(\Delta C)^2/\sigma_c^2}
    score = exp(-clr_diff_sq / (settings.sigma_c^2));
end


function [ score ] = computeSizeSimilarityScore(seg_info_1, seg_info_2, settings)
    sz_1 = seg_info_1(:,settings.info_size_col);
    sz_2 = seg_info_2(:,settings.info_size_col);
    
    % T(S_{k}^t,S_{l}^u)
    if sz_1 > sz_2
        score = sz_2 / sz_1;
    else
        score = sz_1 / sz_2;
    end
end

function [ score ] = computeRegularizationScore(seg_info_1, seg_infos_1, seg_infos_2, other_seg_id, settings)
    pos_diff = seg_info_1(:,settings.info_cntr_col) - seg_infos_2(other_seg_id+1,settings.info_cntr_col);
    
    % Compute the weighted average flow
    % (\Delta C)^2
    temp_c = seg_infos_1(:,settings.info_uclr_col) - repmat(seg_info_1(:,settings.info_uclr_col), [size(seg_infos_1,1) 1]);
    % (\Delta C)^2
    temp_x = seg_infos_1(:,settings.info_cntr_col) - repmat(seg_info_1(:,settings.info_cntr_col), [size(seg_infos_1,1) 1]);
    % e^{-(\Delta C)^2/\sigma_{c_t}^2} e^{-(\Delta x)^2/\sigma_{x_t}^2}
    w = exp(-sum(temp_c.^2, 2) ./ settings.sigma_ci^2) .* exp(-sum(temp_x.^2, 2) ./ settings.sigma_xi^2);
    % \bar{v}(S_k^t)
    v = sum(seg_infos_1(:,settings.info_of_col) .* [w w], 1) ./ sum(w);
    
    % (\Delta x-\bar{v}(S_k^t))^2
    centr_diff_sq = sum((pos_diff - v).^2);
    % e^{-(\Delta x-\bar{v}(S_k^t))^2/\sigma_x^2}
    score = exp(-centr_diff_sq / (settings.sigma_x^2));
end

function [ seg_ids ] = getAdjacentSegments( seg_mask, im_seg_map, settings )
    search_mask = imdilate(seg_mask, true(3,3));
    search_mask(seg_mask) = 0;
    seg_ids = unique(im_seg_map(search_mask));
end

function [ avg_color_diff ] = selectSegmentMinAdvect(mask, of, f1, f2, settings)
    of = round(of);
    if of(1) > 0
        mask = [false(of(1), size(mask,2)); mask(1:end-of(1),:)];
        f1 = [zeros(of(1), size(f1,2), size(f1,3)); f1(1:end-of(1),:,:)];
    else
        mask = [mask(-of(1)+1:end,:); false(-of(1), size(mask,2))];
        f1 = [f1(-of(1)+1:end,:,:); zeros(-of(1), size(f1,2), size(f1,3)); ];
    end
    
    if of(2) > 0
        mask = [false(size(mask,1), of(2)) mask(:,1:end-of(2))];
        f1 = [zeros(size(f1,1), of(2), size(f1,3)) f1(:,1:end-of(2),:)];
    else
        mask = [mask(:,-of(2)+1:end) false(size(mask,1), -of(2))];
        f1 = [f1(:,-of(2)+1:end,:) zeros(size(f1,1), -of(2), size(f1,3))];
    end
    
    if settings.is_color
        no_mask_pixels = nnz(mask);
        mask = repmat(mask, [1 1 3]);
        
        vals1 = reshape(f1(mask), [no_mask_pixels 3]);
        vals2 = reshape(f2(mask), [no_mask_pixels 3]);
    else
        vals1 = f1(mask);
        vals2 = f2(mask);
    end
    
    avg_color_diff = mean(sqrt(sum((double(vals1)-double(vals2)).^2, 2)));
end

function drawSegmentShift(seg_infos_1, seg_infos_2, f1, f2, settings)
    figure, subplot(1, 2, 2);
    imshow(f2);
    subplot(1, 2, 1);
    imshow(f1);
    
    cntr = seg_infos_1(:, settings.info_cntr_col);
    of = seg_infos_1(:, settings.info_of_col);
    hold on;
    quiver(cntr(:,2), cntr(:,1), of(:,2), of(:,1), 0, 'MaxHeadSize', 0.5, 'Color', [0 0 0])
end