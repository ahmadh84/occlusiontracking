function [ output_args ] = convertToPngs( input_args )
%CONVERTTOPNGS Summary of this function goes here
%   Detailed explanation goes here

    addpath('main_code');
    
    start_folder_no = 1;
    end_folder_no = 30;
    out_dir = '../Data/evaluation_data/stein';
    filesearch_re = 'img_(\d+).[(?:jpg)(?:png)(?:bmp)(?:tif)]';

    for fldr = start_folder_no:end_folder_no
        dir_path = fullfile(out_dir, num2str(fldr));
        files = dir(dir_path);
        files_found = {files.name};
        tok = regexpi(files_found, filesearch_re, 'tokens');
        tok_valid = ~cellfun(@isempty, tok);
        
        file_nums = cellfun(@(x) str2num(x{1}{:}), tok(tok_valid));
        assert(length(file_nums) == 2, 'dsafda');
        
        files_found = files_found(tok_valid);
        [temp idxs] = sort(files_found);
        files_found = files_found(idxs);
        
        i1 = imread(fullfile(dir_path, files_found{1}));
        i2 = imread(fullfile(dir_path, files_found{2}));
        imwrite(i1, fullfile(dir_path, ComputeTrainTestData.IM1_PNG));
        imwrite(i2, fullfile(dir_path, ComputeTrainTestData.IM2_PNG));
        delete(fullfile(dir_path, files_found{1}));
        delete(fullfile(dir_path, files_found{2}));
        
        
        dir_path = fullfile(out_dir, num2str(fldr), 'stabilized');
        files = dir(dir_path);
        files_found = {files.name};
        tok = regexpi(files_found, filesearch_re, 'tokens');
        tok_valid = ~cellfun(@isempty, tok);
        
        file_nums = cellfun(@(x) str2num(x{1}{:}), tok(tok_valid));
        assert(length(file_nums) == 2, 'dsafda');
        
        files_found = files_found(tok_valid);
        [temp idxs] = sort(files_found);
        files_found = files_found(idxs);
        
        i1 = imread(fullfile(dir_path, files_found{1}));
        i2 = imread(fullfile(dir_path, files_found{2}));
        imwrite(i1, fullfile(dir_path, ComputeTrainTestData.IM1_PNG));
        imwrite(i2, fullfile(dir_path, ComputeTrainTestData.IM2_PNG));
        delete(fullfile(dir_path, files_found{1}));
        delete(fullfile(dir_path, files_found{2}));
    end
end

