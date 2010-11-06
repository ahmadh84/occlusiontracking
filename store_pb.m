function store_pb()
%STORE_PB Summary of this function goes here
%   Detailed explanation goes here

    addpath('main_code\algorithms\segbench\lib\matlab');
    
    
    sequences = 1:24;
    main_dir = '../Data/evaluation_data';
    pbedgeStore(main_dir, sequences);
    
    sequences = 1:36;
    main_dir = '../Data/evaluation_data/mit_human_1';
    pbedgeStore(main_dir, sequences);
    
    sequences = 1:12;
    main_dir = '../Data/evaluation_data/mit_human_2';
    pbedgeStore(main_dir, sequences);
end


function pbedgeStore(main_dir, sequences)
    store_texture = 'pb.mat';
    
    for sequence_no = sequences
        fprintf(1, 'Computing textures for %d\n', sequence_no);
        i1 = imread(fullfile(main_dir, num2str(sequence_no), '1.png'));
        
        tic;
        % compute the probability of boundary
        if size(i1,3) == 1
            [ pbedge, pbtheta ] = pbBGTG(im2double(i1));
        else
            [ pbedge, pbtheta ] = pbCGTG(im2double(i1));
        end
        pbedge_compute_time = toc;
        
        save(fullfile(main_dir, num2str(sequence_no), store_texture), 'pbedge', 'pbtheta', 'pbedge_compute_time');
    end
end

