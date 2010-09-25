function [ output_args ] = movefiles( input_args )
%MOVEFILES Summary of this function goes here
%   Detailed explanation goes here

    addpath('main_code');
    
    start_folder_no = 1;
    out_dir = '../Data/evaluation_data/mit_human_2';
    filesearch_re = 'sample (\d+).jpg';
    dir_path = '../Data/MIT Human Assisted Motion Annotation/table/frames/';
    search_path = [dir_path 'sample *.jpg'];
    
    d = dir(search_path);
    files_found = {d.name};

    % sort
    tok = regexp(files_found, filesearch_re, 'tokens');
    file_nums = cellfun(@(x) str2num(x{1}{:}), tok);
    [temp idxs] = sort(file_nums);
    files_found = files_found(idxs);
    
    for idx = 1:length(files_found)-1
        out_fldr = fullfile(out_dir, num2str(start_folder_no));
        mkdir(out_fldr);
        
        i1 = imread(fullfile(dir_path, files_found{idx}));
        i2 = imread(fullfile(dir_path, files_found{idx+1}));
        imwrite(i1, fullfile(out_fldr, ComputeTrainTestData.IM1_PNG));
        imwrite(i2, fullfile(out_fldr, ComputeTrainTestData.IM2_PNG));
        
        start_folder_no = start_folder_no + 1;
    end
end

