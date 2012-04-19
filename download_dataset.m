function download_dataset
% Downloads Mac Aodha et al. (CVPR 2010) dataset for training (or testing)
% the classifier

training_dirname = 'AlgoSuitabilityDataset';
download_dirname = 'UCLgtOFv1.1';
clc

fprintf(2, '---------------------------------------------------------------------------\n                              Download Notice                              \n---------------------------------------------------------------------------\nBy running this script, you accept all licensing agreements accompanied\nwith the dataset that will now be downloaded and used later for training\nor testing.\n\nPress ''y'' to accept (any other key to stop the script): ');
user_inp = input('','s');
if isempty(user_inp) || ~strncmpi(user_inp(1), 'y', 1)
    return;
end

download_dir = '';
while exist(download_dir, 'dir') ~= 7
    download_dir = input('\nSpecify directory to download dataset at (leave empty for current dir): ','s');
    if isempty(download_dir)
        download_dir = pwd;
    end
    
    if exist(download_dir, 'dir') ~= 7
        fprintf(2, 'Invalid directory (the directory should already exist)\n');
    else
        if exist(fullfile(download_dir, training_dirname), 'dir') == 7
            fprintf(2, '%s already exists. This is where the downloaded dataset will be extracted.\n', ...
                    fullfile(download_dir, training_dirname));
            return;
        end
    end
end

try
    fprintf(1, 'Downloading Mac Aodha et al. (CVPR''10) GT dataset ...\n');
    if exist(fullfile(download_dir, 'UCLgtOFv1.1.zip'), 'file') == 2
       delete(fullfile(download_dir, 'UCLgtOFv1.1.zip'))
    end
    urlwrite('http://cms.cs.ucl.ac.uk/fileadmin/visual/pubsFiles/algorithmSuitabilityFiles/UCLgtOFv1.1.zip', ...
           fullfile(download_dir, 'UCLgtOFv1.1.zip'));
    fprintf(1, 'Done downloading\n');

    mkdir(fullfile(download_dir, training_dirname));
    if exist(fullfile(download_dir, download_dirname), 'dir') == 7
        rmdir(fullfile(download_dir, download_dirname), 's');
    end
    unzip(fullfile(download_dir, 'UCLgtOFv1.1.zip'), fullfile(download_dir));

    %training_seq = [17 26 49 50];
    training_seq = [9 21 22 20 10 24 25 23 30:39 27 29 18 19 17 49 50 43 46 40 ...
                    44 47 41 45 48 42];
    offsets = [0 0 0 0 0 0 0 0 0:9 0 0 0 0 0 0 0 zeros(1,9)];
    filepattern = {'crates/1/%d.png', 'crates/1/%da.png', 'crates/1/%db.png', ...
                   'crates/1/%dc.png', 'crates/2/%d.png', 'crates/2/%da.png', ...
                   'crates/2/%db.png', 'crates/2/%dc.png'};
    filepattern = horzcat(filepattern, repmat({'mayan/%d.png'}, 1, 10));
    filepattern = [filepattern, 'polys/1/%d.png', 'polys/2/%d.png', ...
                   'sponza/1/%d.png', 'sponza/2/%d.png', 'robot/%d.png', ...
                   'text/1/%d.png', 'text/2/%d.png', 'cratesangle/1deg/%da.png', ...
                   'cratesangle/1deg/%db.png', 'cratesangle/1deg/%dc.png', ...
                   'cratesangle/4deg/%da.png', 'cratesangle/4deg/%db.png', ...
                   'cratesangle/4deg/%dc.png', 'cratesangle/7deg/%da.png', ...
                   'cratesangle/7deg/%db.png', 'cratesangle/7deg/%dc.png'];

    % iterate over all sequences and move them to separate folders
    for idx = 1:length(training_seq)
        transferFiles(fullfile(download_dir, download_dirname, filepattern{idx}), ...
            offsets(idx), fullfile(download_dir, training_dirname), training_seq(idx));
    end

    % create the flow color images for all sequences
    gtflow_images(fullfile(download_dir, training_dirname));
    
    % delete the zip file and the extracted folder
    rmdir(fullfile(download_dir, download_dirname), 's');
    delete(fullfile(download_dir, 'UCLgtOFv1.1.zip'));

catch exception
    rethrow(exception)
end

end


function transferFiles(filepattern, offset, training_dir, seq)
    % make sequence directory
    mkdir(fullfile(training_dir, num2str(seq)));
    % copy im1
    copyfile(sprintf(strrep(filepattern,'\','/'), offset+1), fullfile(training_dir, ...
             num2str(seq), '1.png'));     
    % copy im2
    copyfile(sprintf(strrep(filepattern,'\','/'), offset+2), fullfile(training_dir, ...
             num2str(seq), '2.png'));
    % copy GT
    copyfile(fullfile(fileparts(filepattern), sprintf('%d_%d.flo', offset+1, offset+2)), ...
             fullfile(training_dir, num2str(seq), '1_2.flo'));
end