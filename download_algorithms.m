function download_algorithms
clc
% destination algorithms directory
curr_dir = fileparts(which(mfilename));
algos_dir = fullfile(curr_dir, 'main_code', 'algorithms');
if exist(algos_dir,'dir')
    rmdir(algos_dir, 's');
end
mkdir(algos_dir);

% create temp download directory
% temp_dir = fullfile(curr_dir, sprintf('temp%d', randi(1e8)));
% mkdir(temp_dir);
temp_dir = fullfile(curr_dir, 'temp48537565');
% mkdir(temp_dir);

try
    % download Deqing Sun's BA code
    fprintf(1, 'Downloading Deqing Sun''s BA flow code ...\n');
%     urlwrite('http://www.cs.brown.edu/~dqsun/code/ba.zip', fullfile(temp_dir, 'ba.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'Black & Anandan 3'));
    unzip(fullfile(temp_dir, 'ba.zip'), fullfile(algos_dir, 'Black & Anandan 3'));
    movefile(fullfile(algos_dir, 'Black & Anandan 3', 'ba', '*'), fullfile(algos_dir, 'Black & Anandan 3'));
    rmdir(fullfile(algos_dir, 'Black & Anandan 3', 'ba'), 's');
    rmdir(fullfile(algos_dir, 'Black & Anandan 3', 'data'), 's');
    replaceInTextFile(fullfile(algos_dir, 'Black & Anandan 3', 'estimate_flow_ba.m'), 'addpath\(genpath\(''utils''\)\);', '% addpath(genpath(''utils''));');
    replaceInTextFile(fullfile(algos_dir, 'Black & Anandan 3', 'estimate_flow_ba.m'), '% ope.display   = false;', 'ope.display   = false;');
    
    % download Deqing Sun's HS code
    fprintf(1, 'Downloading Deqing Sun''s HS flow code ...\n');
%     urlwrite('http://www.cs.brown.edu/~dqsun/code/hs.zip', fullfile(temp_dir, 'hs.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'Horn & Schunck'));
    unzip(fullfile(temp_dir, 'hs.zip'), fullfile(algos_dir, 'Horn & Schunck'));
    movefile(fullfile(algos_dir, 'Horn & Schunck', 'hs', '*'), fullfile(algos_dir, 'Horn & Schunck'));
    rmdir(fullfile(algos_dir, 'Horn & Schunck', 'hs'), 's');
    rmdir(fullfile(algos_dir, 'Horn & Schunck', 'data'), 's');
    replaceInTextFile(fullfile(algos_dir, 'Horn & Schunck', 'estimate_flow_hs.m'), 'addpath\(genpath\(''utils''\)\);', '% addpath(genpath(''utils''));');
    replaceInTextFile(fullfile(algos_dir, 'Horn & Schunck', 'estimate_flow_hs.m'), '% ope.display   = false;', 'ope.display   = false;');
    
    % download Deqing Sun's HS code
    fprintf(1, 'Downloading Deqing Sun''s ClassicNL flow code ...\n');
%     urlwrite('http://www.cs.brown.edu/~dqsun/code/flow_code.zip', fullfile(temp_dir, 'flow_code.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'Classic NL'));
    unzip(fullfile(temp_dir, 'flow_code.zip'), fullfile(algos_dir, 'Classic NL'));
    movefile(fullfile(algos_dir, 'Classic NL', 'flow_code', '*'), fullfile(algos_dir, 'Classic NL'));
    rmdir(fullfile(algos_dir, 'Classic NL', 'flow_code'), 's');
    rmdir(fullfile(algos_dir, 'Classic NL', 'data'), 's');
    rmdir(fullfile(algos_dir, 'Classic NL', '@alt_ba_optical_flow'), 's');
    rmdir(fullfile(algos_dir, 'Classic NL', '@ba_optical_flow'), 's');
    rmdir(fullfile(algos_dir, 'Classic NL', '@hs_optical_flow'), 's');
    delete(fullfile(algos_dir, 'Classic NL', 'readme.pdf'));
    replaceInTextFile(fullfile(algos_dir, 'Classic NL', 'estimate_flow_interface.m'), 'if \(~isdeployed\)\n\s*addpath\(genpath\(''utils''\)\);\nend', '% if \(~isdeployed\)\n%     addpath\(genpath\(''utils''\)\);\n% end');

    % download GLCM code
    fprintf(1, 'Downloading Avinash Uppuluri''s GLCM code from Mathworks ...\n');
%     urlwrite('http://www.mathworks.com/matlabcentral/fx_files/22354/5/GLCM_Features4.zip', fullfile(temp_dir, 'GLCM_Features4.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'GLCM'));
    unzip(fullfile(temp_dir, 'GLCM_Features4.zip'), fullfile(temp_dir, 'GLCM'));
    movefile(fullfile(temp_dir, 'GLCM', 'GLCM_Features4.m'), fullfile(algos_dir, 'GLCM'));
    movefile(fullfile(temp_dir, 'GLCM', 'license.txt'), fullfile(algos_dir, 'GLCM'));
    
    % download Thomas Brox LDOF code
    fprintf(1, 'Downloading Thomas Brox''s LDOF code ...\n');
%     urlwrite('http://lmb.informatik.uni-freiburg.de/people/brox/resources/pami2010Matlab.zip', fullfile(temp_dir, 'pami2010Matlab.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'Large Disp OF'));
    unzip(fullfile(temp_dir, 'pami2010Matlab.zip'), fullfile(algos_dir, 'Large Disp OF'));
    delete(fullfile(algos_dir, 'Large Disp OF', '*.ppm'));
    
    % download Greg Mori SP code
    fprintf(1, 'Downloading Greg Mori''s Superpixel code ...\n');
%     urlwrite('http://www.cs.sfu.ca/~mori/research/superpixels/superpixels64.tar.gz', fullfile(temp_dir, 'superpixels64.tar.gz'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'PbNcutSuperpixels'));
    untar(fullfile(temp_dir, 'superpixels64.tar.gz'), fullfile(algos_dir, 'PbNcutSuperpixels'));
    movefile(fullfile(algos_dir, 'PbNcutSuperpixels', 'superpixels64', '*'), fullfile(algos_dir, 'PbNcutSuperpixels'));
    rmdir(fullfile(algos_dir, 'PbNcutSuperpixels', 'superpixels64'), 's');
    delete(fullfile(algos_dir, 'PbNcutSuperpixels', '*.jpg'));
    fprintf(1, 'Producing mex files for Greg Mori''s Superpixel code ...\n');
    cd(fullfile(algos_dir, 'PbNcutSuperpixels', 'yu_imncut'));
    mex -largeArrayDims csparse.c
    mex -largeArrayDims spmd1.c
    mex -largeArrayDims ic.c
    mex -largeArrayDims imnb.c
    mex -largeArrayDims parmatV.c
    fprintf(1, 'Done mex''ing\n');
    cd(curr_dir);

    % download Berkeley Segmentation code
    fprintf(1, 'Downloading Berkeley Segmentation code ...\n');
%     urlwrite('http://www.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/segbench/code/segbench.tar.gz', fullfile(temp_dir, 'segbench.tar.gz'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'segbench', 'lib', 'matlab'));
    untar(fullfile(temp_dir, 'segbench.tar.gz'), temp_dir);
    d = dir(fullfile(temp_dir, 'segbench'));
    for idx = 1:length(d)
        if strcmp(d(idx).name(1), '.')~=1 && d(idx).isdir == 1 && exist(fullfile(temp_dir, 'segbench', d(idx).name, 'GNUmakefile'), 'file')==2
            transferMatlabFromGNU(fullfile(temp_dir, 'segbench', d(idx).name, 'GNUmakefile'), fullfile(algos_dir, 'segbench', 'lib', 'matlab'));
        end
    end
    
    % download Texture Features code
    fprintf(1, 'Downloading Thomas Brox''s Sparse Texture Features code (written by Omid Aghazadeh) ...\n');
    urlwrite('http://www.mathworks.com/matlabcentral/fx_files/27618/2/discriminative_texture_feature_v1.1.zip', fullfile(temp_dir, 'discriminative_texture_feature_v1.1.zip'));
    urlwrite('http://www.mathworks.com/matlabcentral/fx_files/27604/3/Nonlinear_Diffusion_v1.2.zip', fullfile(temp_dir, 'Nonlinear_Diffusion_v1.2.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'Sparse Set Texture Features'));
    unzip(fullfile(temp_dir, 'discriminative_texture_feature_v1.1.zip'), fullfile(algos_dir, 'Sparse Set Texture Features'));
    unzip(fullfile(temp_dir, 'Nonlinear_Diffusion_v1.2.zip'), fullfile(algos_dir, 'Sparse Set Texture Features'));
    delete(fullfile(algos_dir, 'Sparse Set Texture Features', '*.bmp'));
    fprintf(1, 'Producing mex files for Sparse Texture Features code ...\n');
    cd(fullfile(algos_dir, 'Sparse Set Texture Features'));
    mex -largeArrayDims thomas_mex.cpp
    fprintf(1, 'Done mex''ing\n');
    cd(curr_dir);
    
%     rmdir(temp_dir, 's');
    
catch exception
    % remove temp dir
%     rmdir(temp_dir, 's');
    rethrow(exception)
end



function replaceInTextFile(filepath, re_file, replace_txt)
fd = fopen(filepath, 'r');
str = fread(fd);
str = char(str');
% str = str{1};
% str = cellfun(@(x) sprintf('%s\n', x), str, 'UniformOutput',false);
% str = horzcat(str{:});
fclose(fd);

str = regexprep(str, re_file, replace_txt);
fd = fopen(filepath, 'w');
fprintf(fd, '%s', str);
fclose(fd);



function transferMatlabFromGNU(makefilepath, dest_dir)
fd = fopen(makefilepath, 'r');
str = fread(fd);
str = char(str');
fclose(fd);

files = {};
re_matches = regexp(str, '(?:matlab)\s+:=\s+(\S+.(?:(mat)|m)(?:\s*\\?\s*((\$\(wildcard)|(\)))?\s+))*', 'tokens');
for idx = 1:length(re_matches)
    f = regexp(re_matches{idx}{1}, '(\S+.(?:(mat)|m))', 'tokens');
    files = [files cellfun(@(x)x, f)];
end
for idx = 1:length(files)
    movefile(fullfile(fileparts(makefilepath), files{idx}), dest_dir);
end
