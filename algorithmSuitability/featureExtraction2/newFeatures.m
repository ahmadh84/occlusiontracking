function [ features ] = newFeatures( xfl, yfl )
%NEWFEATURES Summary of this function goes here
%   Detailed explanation goes here

    no_features = 4;
    features = zeros(numel(xfl), no_features);
    
    [c r] = meshgrid(-2:2, -2:2);
    nhood = cat(3, r(:), c(:));
    
    labels = 1:12;
    
    [c r] = meshgrid(1:size(xfl,2), 1:size(xfl,1));
    temp = repmat(nhood, [1 numel(r) 1]);
    temp2_r = repmat(r(:)', [size(nhood,1) 1]);
    temp2_c = repmat(c(:)', [size(nhood,1) 1]);
    temp2_r = temp(:,:,1) + temp2_r;
    temp2_c = temp(:,:,2) + temp2_c;
    
    idxs_outside = temp2_r <= 0 | temp2_c <= 0 | temp2_r > size(xfl,1) | temp2_c > size(xfl,2);
    
    sums_outside = sum(idxs_outside, 1);
    
    unique_sums = unique(sums_outside);
    for s = unique_sums
        curr_idxs = sums_outside==s;
        
        temp_u = temp2_r(:,curr_idxs);
        temp_v = temp2_c(:,curr_idxs);
        
        % throw indices which fall outside
        if s ~= 0
            temp_idxs_outside = idxs_outside(:,curr_idxs);
            [~, sorted_rs] = sort(temp_idxs_outside, 1);
            sorted_rs(end-s+1:end,:) = [];
            sorted_rs = sub2ind(size(temp_u), sorted_rs, repmat(1:size(temp_u,2), [size(sorted_rs,1) 1]));
            temp_u = temp_u(sorted_rs);
            temp_v = temp_v(sorted_rs);
        end
        temp_indxs = sub2ind(size(xfl), temp_u, temp_v);
        temp_u = xfl(temp_indxs);
        temp_v = yfl(temp_indxs);
        
        ang = atan(temp_v ./ temp_u);
        avg_ang = anglesUnwrappedMean( ang, 'rad', 1 );
        avg_ang = repmat(avg_ang, [size(ang,1) 1]);
        avg_ang = anglesUnwrappedDiff(ang, avg_ang);
        
        % angle variance
        avg_ang = mean(avg_ang.^2, 1);
        features(curr_idxs,1) = avg_ang;
        
        % length variance
        len = sqrt(temp_u.^2 + temp_v.^2);
        mean_len = repmat(mean(len, 1), [size(len,1) 1]);
        len_var = mean((len - mean_len).^2, 1);
        features(curr_idxs,2) = len_var;
    end
    
    
    [nhood_opp_1, nhood_opp_2, dist, labels] = getNhoodOpp(5);
    
    nhood_opp = nhood_opp_1 + nhood_opp_2;
    
    pxl_idx = 1;
    for c = 1:size(xfl, 2)
        c
        for r = 1:size(xfl, 1)
            temp_r = nhood(:,:,1) + r;
            temp_c = nhood(:,:,2) + c;
            
            idxs_outside = temp_r <= 0 | temp_c <= 0 | temp_r > size(xfl,1) | temp_c > size(xfl,2);
            
            labels_temp = labels;
            labels_temp(nhood_opp(idxs_outside)) = [];
            score = zeros(length(labels_temp),1);
            
%             [curr_r1 curr_c1] = find(ismember(nhood_opp_1, labels_temp));
%             [curr_r2 curr_c2] = find(ismember(nhood_opp_2, labels_temp));
%             curr_r2 = flipud(curr_r2);
%             curr_c2 = flipud(curr_c2);
%             
%             p1 = sub2ind(size(xfl), curr_r1, curr_c1);
%             p2 = sub2ind(size(xfl), curr_r2, curr_c2);
%             
%             p1 = [xfl(p1)'; yfl(p1)'];
%             p2 = [xfl(p2)'; yfl(p2)'];
            
            idx = 1;
            for lbl = labels_temp
                curr_r = temp_r(nhood_opp == lbl);
                curr_c = temp_c(nhood_opp == lbl);
                
                p1 = [ xfl(curr_r(1), curr_c(1)); yfl(curr_r(1), curr_c(1)) ];
                p2 = [ xfl(curr_r(2), curr_c(2)); yfl(curr_r(2), curr_c(2)) ];
                score(idx) = pinv(p1-p2) * dist(:,lbl);
                idx = idx + 1;
            end
            
%             score = score / length(labels_temp);
            features(pxl_idx, 3) = mean(score);
            features(pxl_idx, 4) = var(score);
            
            pxl_idx = pxl_idx + 1;
        end
    end
end

function [nhood_opp_1st, nhood_opp_2nd, dist, labels] = getNhoodOpp(sz)
    nhood_opp = reshape(1:sz^2, [sz sz]);
    nhood_opp_1st = nhood_opp;
    nhood_opp_2nd = nhood_opp;
    nhood_opp_1st(end-floor(sz^2/2):end) = 0;
    nhood_opp_2nd(1:ceil(sz^2/2)) = 0;
    nhood_opp_2nd(end:-1:1) = nhood_opp_1st(1:end);
    nhood_opp(ceil(sz/2),ceil(sz/2)) = NaN;
    
    dist = [2 2; 1 2; 0 2; -1 2; -2 2; 2 1; 1 1; 0 1; -1 1; -2 1; 2 0; 1 0]'*2;
    
    labels = 1:12;
end