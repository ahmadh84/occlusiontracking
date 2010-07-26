function [ output_args ] = consistentseg( input_filepath, start_no, end_no )
%CONSISTENTSEG Summary of this function goes here
%   Detailed explanation goes here

    settings.thresh_var = 0.02;
    settings.min_segment_sz = [10 10];
    settings.max_segment_sz = [60 60];
    [c r] = meshgrid(-2:2, -2:2);
    settings.search_nhood = [r(:) c(:)];
    [c r] = meshgrid(-1:1, -1:1);
    settings.search_nhood_2 = [r(:) c(:)];
    settings.ofrefine_psb_segs_dilation = strel('disk', 20, 0);
    settings.sigma_s = 10;
    settings.sigma_c = 10;
    settings.sigma_x = 20;
    settings.sigma_ci = 10;     % is the estimated standard deviation of the diff in the average color of segment k and segment l in the im i under consideration
    settings.sigma_xi = 20;     % is the estimated standard deviation of the diff in the position of the centroids of segment k and segment l in the im i under consideration
    settings.is_color = size(imread((sprintf(input_filepath, start_no))), 3) == 3;
    
    settings.info_of_col = [1:2];
    settings.info_cntr_col = [3:4];
    settings.info_map_col = 5;
    settings.info_size_col = 6;
    settings.info_uclr_col = 7;
    if settings.is_color
        settings.info_uclr_col = [7 8 9];
    end
    
    i1 = imread(sprintf(input_filepath, start_no));
    i2 = imread(sprintf(input_filepath, start_no+1));
    iterations = 5;
    
    [s1_1, s1_2, alpha1, segment_infos_1] = initInfo(i1, i2, settings);
    [s2_1, s2_2, alpha2, segment_infos_2] = initInfo(i2, i1, settings);
    
    for iter = 1:iterations
        fprintf(1, '\nITERATION %d\n', iter);
        
        tic; [ segment_infos_1 ] = refineOpticalFlow( s1_1, s1_2, s2_1, segment_infos_1, segment_infos_2, i1, i2, settings ); toc
        tic; [ segment_infos_2 ] = refineOpticalFlow( s2_1, s2_2, s1_1, segment_infos_2, segment_infos_1, i2, i1, settings ); toc
        
        tic; [ s1_1, s1_2, alpha1, segment_infos_1 ] = refineSegmentation( s1_1, s1_2, s2_1, segment_infos_1, i1, settings ); toc
        tic; [ s2_1, s2_2, alpha2, segment_infos_2 ] = refineSegmentation( s2_1, s2_2, s1_1, segment_infos_2, i2, settings ); toc
        
        [ segment_infos_1 ] = findCentroidAndMeanColors( i1, s1_1, segment_infos_1, settings );
        [ segment_infos_2 ] = findCentroidAndMeanColors( i2, s2_1, segment_infos_2, settings );
        
        save(sprintf('iteration%d',iter), 's1_1', 's1_2', 'alpha1', 's2_1', 's2_2', 'alpha2', 'segment_infos_1', 'segment_infos_2');
    end

end


function [s1, s2, alpha, segment_infos] = initInfo(f1, f2, settings)
    s1 = quadtreeseg(f1, settings.thresh_var, 0, settings.min_segment_sz, settings.max_segment_sz);
    s2 = NaN(size(s1));
    alpha = ones(size(s1));
    no_segs = max(s1(:))+1;
    
    segment_infos = zeros(no_segs, settings.info_uclr_col(end));
    
    % OF (u,v)                                     
    %segment_infos(:,settings.info_of_col) = zeros(no_segs, 2);
    % centroid
    %segment_infos(:,settings.info_cntr_col) = 0.0;
    % segment mapping
    segment_infos(:,settings.info_map_col) = NaN;
    % mean color
    %segment_infos(:,settings.info_uclr_col) = 0.0;
    
    [ segment_infos ] = findCentroidAndMeanColors( f1, s1, segment_infos, settings );
    
    % compute segment sizes
    segment_infos(:,settings.info_size_col) = hist(s1(:), double(0:size(segment_infos,1)-1));
end
