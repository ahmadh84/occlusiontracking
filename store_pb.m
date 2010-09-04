function [ output_args ] = store_pb( input_args )
%STORE_PB Summary of this function goes here
%   Detailed explanation goes here

    addpath('main_code\algorithms\segbench\lib\matlab');
    
    sequences = 1:25;
    main_dir = '../Data/oisin+middlebury';
    store_texture = 'pb.mat';
    
    for sequence_no = [[4 5 9 10 11 12 13 14 18 19] setdiff(6:25, [4 5 9 10 11 12 13 14 18 19])]
        fprintf(1, 'Computing textures for %d\n', sequence_no);
        i1 = imread(fullfile(main_dir, num2str(sequence_no), '1.png'));
        
        % compute the probability of boundary
        if size(i1,3) == 1
            [ pbedge ] = pbBGTG(im2double(i1));
        else
            [ pbedge ] = pbCGTG(im2double(i1));
        end
        
        save(fullfile(main_dir, num2str(sequence_no), store_texture), 'pbedge');
    end
end

