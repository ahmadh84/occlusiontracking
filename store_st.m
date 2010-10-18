function [ output_args ] = store_st( input_args )
%STORE_ST Summary of this function goes here
%   Detailed explanation goes here

    addpath('main_code\algorithms\Sparse Set Texture Features');
    
    sequences = [12  13  16  23  24  27  28  29  3  30  7  8];
    main_dir = 'H:/evaluation_data/walking_legs/';
    store_texture = 'sparsetextures.mat';
    
    for sequence_no = sequences
        fprintf(1, 'Computing textures for %d\n', sequence_no)
        i1 = imread(fullfile(main_dir, num2str(sequence_no), '1.png'));
        i2 = imread(fullfile(main_dir, num2str(sequence_no), '2.png'));
        
        T1 = computeSparseSetTexture( i1 );
        T2 = computeSparseSetTexture( i2 );
        
        save(fullfile(main_dir, num2str(sequence_no), store_texture), 'T1', 'T2');
    end
end


function sparsesettext = computeSparseSetTexture( im )
    if size(im,3) == 3
        F = discriminative_texture_feature(double(im),6,[],1);
    else
        F = discriminative_texture_feature(double(im),6,[],0);
    end

    sparsesettext = reshape(F', [size(im,1),size(im,2),size(F,1)]);
end