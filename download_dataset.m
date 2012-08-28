function download_dataset
% Downloads Mac Aodha et al. (PAMI 2012 + CVPR 2012) dataset for training 
% (or testing) the classifier

training_dirname = 'AlgoSuit+Middlebury_Dataset';
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
    %------------------------ Algo Suitability ------------------------%
    download_dirname = 'uclOpticalFlow_v1.2';
    download_filename = 'uclOpticalFlow_v1.2.zip';
    
    fprintf(1, 'Downloading Mac Aodha et al. (PAMI''12 + CVPR''10) GT dataset ...\n');
    if exist(fullfile(download_dir, download_filename), 'file') == 2
       delete(fullfile(download_dir, download_filename))
    end
    urlwrite(['http://visual.cs.ucl.ac.uk/ext/flowConfidence/supp/' download_filename], ...
           fullfile(download_dir, download_filename));
    fprintf(1, 'Done downloading\n');

    mkdir(fullfile(download_dir, training_dirname));
    if exist(fullfile(download_dir, download_dirname), 'dir') == 7
        rmdir(fullfile(download_dir, download_dirname), 's');
    end
    unzip(fullfile(download_dir, download_filename), fullfile(download_dir));

    %training_seq = [17 26 49 50];
    training_seq = [9 10 13 14 15 16 17 18 19 22 24 26 29 30 39 49 50 51 ...
                    88 89 106 107 124 125];
    offsets = [zeros(1,24)];
    filepattern = {'scenes/009_Crates1/%d.png', ...
                   'scenes/010_Crates2/%d.png', ...
                   'scenes/013_Mayan1/%d.png', ...
                   'scenes/014_Mayan2/%d.png', ...
                   'scenes/015_YoesmiteSun/%d.png', ...
                   'scenes/016_GroveSun/%d.png', ...
                   'scenes/017_Robot/%d.png', ...
                   'scenes/018_Sponza1/%d.png', ...
                   'scenes/019_Sponza2/%d.png', ...
                   'scenes/022_Crates1Htxtr2/%d.png', ...
                   'scenes/024_Crates2Htxtr1/%d.png', ...
                   'scenes/026_Brickbox1t1/%d.png', ...
                   'scenes/029_Brickbox2t2/%d.png', ...
                   'scenes/030_GrassSky0/%d.png', ...
                   'scenes/039_GrassSky9/%d.png', ...
                   'scenes/049_TxtRMovement/%d.png', ...
                   'scenes/050_TxtLMovement/%d.png', ...
                   'scenes/051_blow1Txtr1/%d.png', ...
                   'scenes/088_blow19Txtr2/%d.png', ...
                   'scenes/089_drop1Txtr1/%d.png', ...
                   'scenes/106_drop9Txtr2/%d.png', ...
                   'scenes/107_roll1Txtr1/%d.png', ...
                   'scenes/124_roll9Txtr2/%d.png', ...
                   'scenes/125_street1Txtr1/%d.png'};

    % iterate over all sequences and move them to separate folders
    for idx = 1:length(training_seq)
        transferFiles(fullfile(download_dir, download_dirname, filepattern{idx}), ...
            offsets(idx), fullfile(download_dir, training_dirname), training_seq(idx), true);
    end

    % create the flow color images for all sequences
    gtflow_images(fullfile(download_dir, training_dirname));
    
    % delete the zip file and the extracted folder
    rmdir(fullfile(download_dir, download_dirname), 's');
    delete(fullfile(download_dir, download_filename));

    
    %------------------------ Middlebury ------------------------%
    download_dirname = 'other-data';
    
    fprintf(1, 'Downloading Baker et al. (IJCV 2011) GT dataset ...\n');
    if exist(fullfile(download_dir, 'other-color-twoframes.zip'), 'file') == 2
        delete(fullfile(download_dir, 'other-color-twoframes.zip'))
    end
    urlwrite('http://vision.middlebury.edu/flow/data/comp/zip/other-color-twoframes.zip', ...
           fullfile(download_dir, 'other-color-twoframes.zip'));
    fprintf(1, 'Done downloading\n');

    if exist(fullfile(download_dir, download_dirname), 'dir') == 7
        rmdir(fullfile(download_dir, download_dirname), 's');
    end
    unzip(fullfile(download_dir, 'other-color-twoframes.zip'), fullfile(download_dir));
    
    training_seq = [1 2 3 4 5 6 7 8];
    offsets = repmat(-1, size(training_seq));
    filepattern = {'Venus/frame1%d.png', 'Urban3/frame1%d.png', ...
                   'Urban2/frame1%d.png', 'RubberWhale/frame1%d.png', ...
                   'Hydrangea/frame1%d.png', 'Grove3/frame1%d.png', ...
                   'Grove2/frame1%d.png', 'Dimetrodon/frame1%d.png'};
    
    for idx = 1:length(training_seq)
        transferFiles(fullfile(download_dir, download_dirname, filepattern{idx}), ...
            offsets(idx), fullfile(download_dir, training_dirname), training_seq(idx), false);
    end
    
    rmdir(fullfile(download_dir, download_dirname), 's');
    delete(fullfile(download_dir, 'other-color-twoframes.zip'));

catch exception
    rethrow(exception)
end

end


function transferFiles(filepattern, offset, training_dir, seq, copy_gt)
    % make sequence directory
    mkdir(fullfile(training_dir, num2str(seq)));
    % copy im1
    copyfile(sprintf(strrep(filepattern,'\','/'), offset+1), fullfile(training_dir, ...
             num2str(seq), '1.png'));     
    % copy im2
    copyfile(sprintf(strrep(filepattern,'\','/'), offset+2), fullfile(training_dir, ...
             num2str(seq), '2.png'));
    
    % copy GT
    if copy_gt
        copyfile(fullfile(fileparts(filepattern), sprintf('%d_%d.flo', offset+1, offset+2)), ...
                 fullfile(training_dir, num2str(seq), '1_2.flo'));
    end
end