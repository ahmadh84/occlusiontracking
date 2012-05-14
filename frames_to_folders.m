function frames_to_folders( main_folder, relative_to_first, reverse_ordering, skip_frames )
%FRAMES_TO_FOLDERS This function shifts a sequence of images into folders
% of frame pairs (in a format that it can be used by the classifier). For
% instance if you input a folder which has 3 images: image000.png, 
% image001.png, image002.png, it will create 2 sub-folders, 1 containing
% image000.png and image001.png and the other one containing image001.png
% and image002.png. All images in the folders created are renamed to 1.png
% and 2.png. framestofolders_readme.txt is written in the input folder 
% (main_folder) telling what files were copied in what folders.
%
% @args:
%   main_folder: is the folder where the sequence of images are. The output
%     folders will also be placed in this folder
%   relative_to_first: set to 1 if the first image for all image pairs
%     should always be taken as the first image in the whole input sequence
%   reverse_ordering: set to 1 if you want to reverse the sequence
%   skip_frames: if greater than zero, it will skip n frames from each 
%     frame. This has the effect of speeding up the sequence

    addpath('main_code');
    
    if ~exist('relative_to_first', 'var')
        relative_to_first = 0;
    end

    if ~exist('reverse_ordering', 'var')
        reverse_ordering = 0;
    end

    if ~exist('skip_frames', 'var')
        skip_frames = 0;
    end
    
    
    % get all image files
    supported_ext = '(?:bmp)$|(?:gif)$|(?:jpg)$|(?:pgm)$|(?:png)$|(?:ppm)$|(?:tif)$';
    d = dir( main_folder );
    im_files = vertcat({d.name}');
    im_files = im_files(~cellfun(@isempty, regexpi(im_files, supported_ext)));

    im_groups = cell(0,2);
    
    toks = regexpi(im_files, '(\d+)', 'tokenExtents');
    for idx = 1:length(toks)
        match_g = -1;
        for idx_g = 1:size(im_groups,1)
            if ~isempty(regexpi(im_files{idx}, im_groups{idx_g,1}))
                im_groups{idx_g,2} = [im_groups{idx_g,2} idx];
                match_g = idx_g;
            end
        end
        
        % if match not found, add to the groups
        if match_g == -1
            % iterate over the remaining frames and decide on a better re
            found = 0;
            for idx2 = idx+1:length(toks)
                [ common_re uncommon_regions ] = findCommonRE(im_files{idx}, toks{idx}, im_files{idx2}, toks{idx2});
                if uncommon_regions == 1
                    im_groups{end+1,1} = common_re;
                    im_groups{end,2} = idx;
                    found = 1;
                    break;
                end
            end
            
            if found == 0
                warning('frames_to_folders:NoMatchingFrames', sprintf('No matching frames for ''%s''\n', im_files{idx}));
            end
        end
    end
    
    % sort each group
    for idx = 1:size(im_groups,1)
        nums = [];
        for idx2 = 1:length(im_groups{idx,2})
            tok = regexpi(im_files(im_groups{idx,2}(idx2)), im_groups{idx,1}, 'tokens');
            nums = [nums str2num(tok{1}{1}{1})];
        end
        
        if reverse_ordering
            [v s_idxs] = sort(nums, 'descend');
        else
            [v s_idxs] = sort(nums, 'ascend');
        end 
        im_groups{idx,2} = im_groups{idx,2}(s_idxs);
    end
    
    folder_no = 1;
    
    fd = fopen(fullfile(main_folder, 'framestofolders_readme.txt'), 'w+');
    
    % make each group's folders
    for idx = 1:size(im_groups,1)
        idxs_to_use = 1:skip_frames+1:length(im_groups{idx,2});
        for idx2 = 2:length(idxs_to_use)
            if relative_to_first
                i1_idx = im_groups{idx,2}(idxs_to_use(1));
            else
                i1_idx = im_groups{idx,2}(idxs_to_use(idx2-1));
            end
            i2_idx = im_groups{idx,2}(idxs_to_use(idx2));
            
            i1 = imread(fullfile(main_folder, im_files{i1_idx}));
            i2 = imread(fullfile(main_folder, im_files{i2_idx}));
            
            dir_out = fullfile(main_folder, num2str(folder_no));
            if exist(dir_out, 'dir');
                rmdir(dir_out,'s')
            end
            mkdir(dir_out);
            
            imwrite(i1, fullfile(dir_out, ComputeTrainTestData.IM1_PNG));
            imwrite(i2, fullfile(dir_out, ComputeTrainTestData.IM2_PNG));
            
            fprintf(1, '%d -> %s, %s\n', folder_no, im_files{i1_idx}, im_files{i2_idx});
            fprintf(fd, '%d -> %s, %s\r\n', folder_no, im_files{i1_idx}, im_files{i2_idx});
            
            folder_no = folder_no + 1;
        end
    end
    
    fclose(fd);
end


function [ common_re uncommon_regions ] = findCommonRE(filename1, tok1, filename2, tok2)
    if length(tok1) ~= length(tok2)
        common_re = '.';
        uncommon_regions = -1;
        return;
    end
    
    % check starting text
    uncommon_regions = 0;
    common_re = '';
    curr_idx_1 = 1;
    curr_idx_2 = 1;
    for idx_t = 1:length(tok1)
        % check previous text
        if strcmp(filename1(curr_idx_1:tok1{idx_t}(1)-1), filename2(curr_idx_2:tok2{idx_t}(1)-1))
            common_re = [common_re filename1(curr_idx_1:tok1{idx_t}(1)-1)];
        else
            common_re = [common_re '\D+'];
            uncommon_regions = uncommon_regions + 1;
        end
        
        % check numbers for matches
        if strcmp(filename1(tok1{idx_t}(1):tok1{idx_t}(2)), filename2(tok2{idx_t}(1):tok2{idx_t}(2)))
            common_re = [common_re filename1(tok1{idx_t}(1):tok1{idx_t}(2))];
        else
            common_re = [common_re '(\d+)'];
            uncommon_regions = uncommon_regions + 1;
        end
        
        % progress pointers
        curr_idx_1 = tok1{idx_t}(2)+1;
        curr_idx_2 = tok2{idx_t}(2)+1;
    end
    
    % check end text
    if strcmp(filename1(curr_idx_1:end), filename2(curr_idx_2:end))
        common_re = [common_re filename1(curr_idx_1:end)];
    else
        common_re = [common_re '\D+'];
        uncommon_regions = uncommon_regions + 1;
    end
end