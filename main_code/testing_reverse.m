function [ output_args ] = testing_reverse( input_args )
%TESTING_REVERSE Summary of this function goes here
%   Detailed explanation goes here

    dir_path = 'D:/ahumayun/Data/oisin+middlebury_reverse';
    for seq_no = [4 5 9 10 11 12 13 14 17 18 19]
        reverseSequenceDir(dir_path, seq_no);
    end
    
    dir_path = 'D:/ahumayun/Data/evaluation_data_reverse';
    for seq_no = [1 2 13 14]
        reverseSequenceDir(dir_path, seq_no);
    end
    
    dir_path = 'D:/ahumayun/Data/evaluation_data_reverse/stein';
    for seq_no = [1 2 10 15 21 26]
        reverseSequenceDir(dir_path, seq_no);
    end
end


function reverseSequenceDir(dir_path, sequence_no)
    seqpath = fullfile(dir_path, num2str(sequence_no));
    fprintf(1, [regexprep(seqpath, '\', '/') '\n']);
    
    % swap 1 and 2.PNG
    movefile(fullfile(seqpath, ComputeTrainTestData.IM1_PNG), fullfile(seqpath, '3.png'));
    movefile(fullfile(seqpath, ComputeTrainTestData.IM2_PNG), fullfile(seqpath, ComputeTrainTestData.IM1_PNG));
    movefile(fullfile(seqpath, '3.png'), fullfile(seqpath, ComputeTrainTestData.IM2_PNG));
    
    % delete 1_2.flo
    if exist(fullfile(seqpath, '1_2.flo'), 'file') == 2
        delete(fullfile(seqpath, '1_2.flo'));
    end
    
    % delete flow[SEQNO].PNG
    if exist(fullfile(seqpath, ['flow' num2str(sequence_no) '.png']), 'file') == 2
        delete(fullfile(seqpath, ['flow' num2str(sequence_no) '.png']));
    end
    
    % delete [SEQNO_4518_[(gt)(nogt)].mat]
    if exist(fullfile(seqpath, [num2str(sequence_no) '_4518_gt.mat']), 'file') == 2
        delete(fullfile(seqpath, [num2str(sequence_no) '_4518_gt.mat']));
    end
    if exist(fullfile(seqpath, [num2str(sequence_no) '_4518_nogt.mat']), 'file') == 2
        delete(fullfile(seqpath, [num2str(sequence_no) '_4518_nogt.mat']));
    end
    
    % delete unsure_mask.png
    if exist(fullfile(seqpath, 'unsure_mask.png'), 'file') == 2
        delete(fullfile(seqpath, 'unsure_mask.png'));
    end
    
    % swap uv_fl and uv_fl_r in huberl1.mat
    load(fullfile(seqpath, 'huberl1.mat'));
    temp = uv_fl;
    uv_fl = uv_fl_r;
    uv_fl_r = temp;
    save(fullfile(seqpath, 'huberl1.mat'), 'uv_fl', 'uv_fl_r');
    
    % swap uv_ld and uv_ld_r in largedispof.mat
    load(fullfile(seqpath, 'largedispof.mat'));
    temp = uv_ld;
    uv_ld = uv_ld_r;
    uv_ld_r = temp;
    save(fullfile(seqpath, 'largedispof.mat'), 'uv_ld', 'uv_ld_r');
    
    % swap T1 and T2 sparsetextures.mat
    load(fullfile(seqpath, 'sparsetextures.mat'));
    temp = T1;
    T1 = T2;
    T2 = temp;
    save(fullfile(seqpath, 'sparsetextures.mat'), 'T1', 'T2');
end