function separate_precompute()
    precompute_dir = 'H:\Precompute';
    move_dir = 'H:\Data';

    separate_dir(move_dir, precompute_dir)
end


function separate_dir(input_dir, dest_dir)
    precompute_files = dir(fullfile(input_dir, '*.mat'));
    
    % iterate over precomputed files
    for idx = 1:length(precompute_files)
        prec_filepath = fullfile(input_dir, precompute_files(idx).name);
        if ~isdir(dest_dir)
            mkdir(dest_dir)
        end
        copyfile(prec_filepath, dest_dir);
        delete(prec_filepath);
    end
    
    % iterate over directories
    dirpaths = dir(input_dir);
    for idx = 1:length(dirpaths)
        if dirpaths(idx).isdir && ~strcmp(dirpaths(idx).name, '..') && ~strcmp(dirpaths(idx).name, '.')
            separate_dir(fullfile(input_dir, dirpaths(idx).name), fullfile(dest_dir, dirpaths(idx).name));
        end
    end
end

