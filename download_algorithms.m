function download_algorithms
% Downloads different codes needed to train and test with classifier

clc

fprintf(2, '---------------------------------------------------------------------------\n                              Download Notice                              \n---------------------------------------------------------------------------\nBy running this script, you accept all licensing agreements accompanied\nwith the 3rd party softwares that will now be downloaded and used later in\nour scripts.\n\nPress ''y'' to accept (any other key to stop the script): ');
user_inp = input('','s');
if isempty(user_inp) || ~strncmpi(user_inp(1), 'y', 1)
    return;
end

% destination algorithms directory
curr_dir = fileparts(which(mfilename));
algos_dir = fullfile(curr_dir, 'main_code', 'algorithms');
dont_delete = {'CUDA_masked_NSSD', 'FlowLib', 'kolmogCompar', 'Template_Match', 'vlfeat-0.9.9', 'kmeansK.cpp', 'mexutils.h', 'prctile.m', 'randsample.m', 'TV_L1', 'README'};
if exist(algos_dir,'dir')
    % only delete the dir/files not in dont_delete
    d = dir(algos_dir);
    for idx = 1:length(d)
        if strcmp(d(idx).name,'.') || strcmp(d(idx).name,'..')
            continue;
        end
        if ~any(strcmp(d(idx).name, dont_delete))
            if d(idx).isdir
                rmdir(fullfile(algos_dir,d(idx).name), 's');
            else
                delete(fullfile(algos_dir,d(idx).name));
            end
        end
    end
else
    mkdir(algos_dir);
end

% create temp download directory
temp_dir = fullfile(curr_dir, sprintf('temp%d', randi(1e8)));
mkdir(temp_dir);

try
    % download Deqing Sun's BA code
    fprintf(1, 'Downloading Deqing Sun''s BA flow code ...\n');
    urlwrite('http://www.cs.brown.edu/~dqsun/code/ba.zip', fullfile(temp_dir, 'ba.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'Black & Anandan 3'));
    unzip(fullfile(temp_dir, 'ba.zip'), fullfile(algos_dir, 'Black & Anandan 3'));
    movefile(fullfile(algos_dir, 'Black & Anandan 3', 'ba', '*'), fullfile(algos_dir, 'Black & Anandan 3'));
    rmdir(fullfile(algos_dir, 'Black & Anandan 3', 'ba'), 's');
    rmdir(fullfile(algos_dir, 'Black & Anandan 3', 'data'), 's');
    replaceInTextFile(fullfile(algos_dir, 'Black & Anandan 3', 'estimate_flow_ba.m'), 'addpath\(genpath\(''utils''\)\);', '% addpath(genpath(''utils''));');
    replaceInTextFile(fullfile(algos_dir, 'Black & Anandan 3', 'estimate_flow_ba.m'), '% ope.display   = false;', 'ope.display   = false;');
    adjustAttributes(fullfile(algos_dir, 'Black & Anandan 3'));
    
    
    % download Deqing Sun's HS code
    fprintf(1, 'Downloading Deqing Sun''s HS flow code ...\n');
    urlwrite('http://www.cs.brown.edu/~dqsun/code/hs.zip', fullfile(temp_dir, 'hs.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'Horn & Schunck'));
    unzip(fullfile(temp_dir, 'hs.zip'), fullfile(algos_dir, 'Horn & Schunck'));
    movefile(fullfile(algos_dir, 'Horn & Schunck', 'hs', '*'), fullfile(algos_dir, 'Horn & Schunck'));
    rmdir(fullfile(algos_dir, 'Horn & Schunck', 'hs'), 's');
    rmdir(fullfile(algos_dir, 'Horn & Schunck', 'data'), 's');
    replaceInTextFile(fullfile(algos_dir, 'Horn & Schunck', 'estimate_flow_hs.m'), 'addpath\(genpath\(''utils''\)\);', '% addpath(genpath(''utils''));');
    replaceInTextFile(fullfile(algos_dir, 'Horn & Schunck', 'estimate_flow_hs.m'), '% ope.display   = false;', 'ope.display   = false;');
    adjustAttributes(fullfile(algos_dir, 'Horn & Schunck'));
    
    
    % download Deqing Sun's Classic+NL code
    fprintf(1, 'Downloading Deqing Sun''s ClassicNL flow code ...\n');
    urlwrite('http://www.cs.brown.edu/~dqsun/code/flow_code.zip', fullfile(temp_dir, 'flow_code.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'Classic NL'));
    unzip(fullfile(temp_dir, 'flow_code.zip'), fullfile(algos_dir, 'Classic NL'));
    movefile(fullfile(algos_dir, 'Classic NL', 'flow_code', '*'), fullfile(algos_dir, 'Classic NL'));
    rmdir(fullfile(algos_dir, 'Classic NL', 'flow_code'), 's');
    rmdir(fullfile(algos_dir, 'Classic NL', 'data'), 's');
    rmdir(fullfile(algos_dir, 'Classic NL', '@alt_ba_optical_flow'), 's');
    rmdir(fullfile(algos_dir, 'Classic NL', '@ba_optical_flow'), 's');
    rmdir(fullfile(algos_dir, 'Classic NL', '@hs_optical_flow'), 's');
    replaceInTextFile(fullfile(algos_dir, 'Classic NL', 'estimate_flow_interface.m'), 'if \(~isdeployed\)\n\s*addpath\(genpath\(''utils''\)\);\nend', '% if \(~isdeployed\)\n%     addpath\(genpath\(''utils''\)\);\n% end');
    adjustAttributes(fullfile(algos_dir, 'Classic NL'));
    
    
    % download GLCM code
%     fprintf(1, 'Downloading Avinash Uppuluri''s GLCM code from Mathworks ...\n');
%     urlwrite('http://www.mathworks.com/matlabcentral/fx_files/22354/5/GLCM_Features4.zip', fullfile(temp_dir, 'GLCM_Features4.zip'));
%     fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'GLCM'));
    unzip(fullfile(temp_dir, 'GLCM_Features4.zip'), fullfile(temp_dir, 'GLCM'));
    movefile(fullfile(temp_dir, 'GLCM', 'GLCM_Features4.m'), fullfile(algos_dir, 'GLCM'));
    movefile(fullfile(temp_dir, 'GLCM', 'license.txt'), fullfile(algos_dir, 'GLCM'));
    adjustAttributes(fullfile(algos_dir, 'GLCM'));
    
    
    % download Thomas Brox LDOF code
    fprintf(1, 'Downloading Thomas Brox''s LDOF code ...\n');
    urlwrite('http://lmb.informatik.uni-freiburg.de/people/brox/resources/pami2010Matlab.zip', fullfile(temp_dir, 'pami2010Matlab.zip'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'Large Disp OF'));
    unzip(fullfile(temp_dir, 'pami2010Matlab.zip'), fullfile(algos_dir, 'Large Disp OF'));
    delete(fullfile(algos_dir, 'Large Disp OF', '*.ppm'));
    adjustAttributes(fullfile(algos_dir, 'Large Disp OF'));
    
    
    % download Greg Mori SP code
    fprintf(1, 'Downloading Greg Mori''s Superpixel code ...\n');
    urlwrite('http://www.cs.sfu.ca/~mori/research/superpixels/superpixels64.tar.gz', fullfile(temp_dir, 'superpixels64.tar.gz'));
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
    replaceInTextFile(fullfile(algos_dir, 'PbNcutSuperpixels', 'pbWrapper.m'), 'function \[max_pb,phase\] = pbWrapper\(I,varargin\)', 'function [max_pb,phase] = pbWrapper(I, max_pb, theta, varargin)\naddpath(fullfile(fileparts(mfilename(''fullpath'')), ''yu_imncut''));\n');
    replaceInTextFile(fullfile(algos_dir, 'PbNcutSuperpixels', 'pbWrapper.m'), 'if pb_timing, st=clock; end\s+\[max\_pb,theta\] = pbCGTG\(I\);\s+if pb\_timing, fprintf\(''pb took %.2f minutes\\n'',etime\(clock,st\)/60); end', '% if pb_timing, st=clock; end\n% [max_pb,theta] = pbCGTG(I);\n% if pb_timing, fprintf(''pb took %.2f minutes\\n'',etime(clock,st)/60); end');
    adjustAttributes(fullfile(algos_dir, 'PbNcutSuperpixels'));

    
    % download Berkeley Segmentation code
    fprintf(1, 'Downloading Berkeley Segmentation code ...\n');
    urlwrite('http://www.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/segbench/code/segbench.tar.gz', fullfile(temp_dir, 'segbench.tar.gz'));
    fprintf(1, 'Done downloading\n');
    
    mkdir(fullfile(algos_dir, 'segbench', 'lib', 'matlab'));
    untar(fullfile(temp_dir, 'segbench.tar.gz'), temp_dir);
    d = dir(fullfile(temp_dir, 'segbench'));
    for idx = 1:length(d)
        if strcmp(d(idx).name(1), '.')~=1 && d(idx).isdir == 1 && exist(fullfile(temp_dir, 'segbench', d(idx).name, 'GNUmakefile'), 'file')==2
            transferMatlabFromGNU(fullfile(temp_dir, 'segbench', d(idx).name, 'GNUmakefile'), fullfile(algos_dir, 'segbench', 'lib', 'matlab'));
        end
    end
    % isrgb no longer exists
    replaceInTextFile(fullfile(algos_dir, 'segbench', 'lib', 'matlab', 'detBGTG.m'), 'if isrgb\(im\), im=rgb2gray\(im\); end', 'if size(im,3)==3, im=rgb2gray(im); end');
    movefile(fullfile(temp_dir, 'segbench', 'README'), fullfile(algos_dir, 'segbench'));
    adjustAttributes(fullfile(algos_dir, 'segbench'));

    
    % download sparse occlusion detection code
    fprintf(1, 'Downloading UCLA Occlusion Detection code ...\n');
    urlwrite('http://vision.ucla.edu/~ayvaci/sparse-occlusion-detection-matlab.zip', fullfile(temp_dir, 'sparse-occlusion-detection-matlab.zip'));
    fprintf(1, 'Done downloading\n');
   
    mkdir(fullfile(algos_dir, 'sparse-occlusion-detection'));
    unzip(fullfile(temp_dir, 'sparse-occlusion-detection-matlab.zip'), algos_dir);
    rmdir(fullfile(algos_dir, '__MACOSX'), 's');
    adjustAttributes(fullfile(algos_dir, 'sparse-occlusion-detection'));
    
    
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
    replaceInTextFile(fullfile(algos_dir, 'Sparse Set Texture Features', 'thomas_mex.cpp'), 'void mexFunction\(int nlhs, mxArray\* plhs \[\],int nrhs, mxArray\* prhs\[\]){', 'void mexFunction(int nlhs, mxArray* plhs [],int nrhs, const mxArray* prhs[]){');
    cd(fullfile(algos_dir, 'Sparse Set Texture Features'));
    mex -largeArrayDims thomas_mex.cpp
    fprintf(1, 'Done mex''ing\n');
    cd(curr_dir);
    adjustAttributes(fullfile(algos_dir, 'Sparse Set Texture Features'));
    
    
    % download TV-L1 code
%     fprintf(1, 'Downloading TU-Graz TV-L1 code ...\n');
%     urlwrite('http://gpu4vision.icg.tugraz.at/binaries/tvl1_motion.tgz', fullfile(temp_dir, 'tvl1_motion.tgz'));
%     fprintf(1, 'Done downloading\n');
%     
%     mkdir(fullfile(algos_dir, 'TV_L1'));
%     untar(fullfile(temp_dir, 'tvl1_motion.tgz'), fullfile(algos_dir, 'TV_L1'));
%     movefile(fullfile(algos_dir, 'TV_L1', 'tvl1_motion', '*'), fullfile(algos_dir, 'TV_L1'));
%     rmdir(fullfile(algos_dir, 'TV_L1', 'tvl1_motion'), 's');
%     delete(fullfile(algos_dir, 'TV_L1', '*.png'));
%     delete(fullfile(algos_dir, 'TV_L1', 'flowToColor.m'));
%     delete(fullfile(algos_dir, 'TV_L1', 'writeFlowFile.m'));
%     % add silencing variable
%     replaceInTextFile(fullfile(algos_dir, 'TV_L1', 'coarse_to_fine.m'), 'pyramid_levels, pyramid_factor\);', 'pyramid_levels, pyramid_factor, silent_mode);');
%     replaceInTextFile(fullfile(algos_dir, 'TV_L1', 'coarse_to_fine.m'), '  fprintf(''\*\*\* level = %d\\n'', level\);', '  if exist(''silent_mode'',''var'')==0\n    silent_mode=0;\n  end\n\n  if silent_mode < 2\n    fprintf(''*** level = %d\\n'', level);\n  end');
%     replaceInTextFile(fullfile(algos_dir, 'TV_L1', 'coarse_to_fine.m'), '\(I1, I2, u, v, w, p, lambda, warps, maxits, scale\);', '(I1, I2, u, v, w, p, lambda, warps, maxits, scale, silent_mode);');
%     replaceInTextFile(fullfile(algos_dir, 'TV_L1', 'tv_l1_motion_primal_dual.m'), 'warps, maxits, scale\)', 'warps, maxits, scale, silent_mode)');
%     replaceInTextFile(fullfile(algos_dir, 'TV_L1', 'tv_l1_motion_primal_dual.m'), '  fprintf\(''tv-l1-of-pd: warp = %d\\n'', j\);', '  if silent_mode < 1\n    fprintf(''tv-l1-of-pd: warp = %d\\n'', j);\n  end');
%     replaceInTextFile(fullfile(algos_dir, 'TV_L1', 'tv_l1_motion_primal_dual.m'), '      show_flow\(u,v,gamma\*w,I1,I\_2\_warped \+ \(u-u0\)\.\*I\_x \+ \(v-v0\)\.\*I\_y \+ gamma\*w\);\s      fprintf\(''tv-l1-motion-primal-dual: it = %d\\n'', k\)', '      if silent_mode < 1\n        show_flow(u,v,gamma*w,I1,I_2_warped + (u-u0).*I_x + (v-v0).*I_y + gamma*w);\n        fprintf(''tv-l1-motion-primal-dual: it = %d\\n'', k)\n      end');
%     adjustAttributes(fullfile(algos_dir, 'TV_L1'));
    
    % download KZ occlusions code
    fprintf(1, 'Downloading Kolmogorov and Zabih Occlusions code ...\n');
    urlwrite('http://pub.ist.ac.at/~vnk/software/match-v3.4.src.tar.gz', fullfile(temp_dir, 'match-v3.4.src.tar.gz'));
    fprintf(1, 'Done downloading\n');
    untar(fullfile(temp_dir, 'match-v3.4.src.tar.gz'), temp_dir);
    movefile(fullfile(temp_dir, 'match-v3.4.src', '*'), fullfile(algos_dir, 'kolmogCompar'));
    
    % delete temp directory
    rmdir(temp_dir, 's');
    
catch exception
    % remove temp dir
%     rmdir(temp_dir, 's');
    rethrow(exception)
end

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
end


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
end


function adjustAttributes(folder_path)
% dont need to change file permissions on windows
if ispc == 1
    return;
end

d = dir(folder_path);
for idx = 1:length(d)
    if strcmp(d(idx).name,'.') || strcmp(d(idx).name,'..')
        continue;
    end
    
    curr_path = fullfile(folder_path,d(idx).name);
    if d(idx).isdir == 1
        adjustAttributes(curr_path);
    else
        unix(['chmod 0644 "' curr_path '"']);
    end
end
end