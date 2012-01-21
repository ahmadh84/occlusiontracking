function [ latex_txt features tbl_auc tbl_f1 ] = makeRCGTGraphsToTable( input_args )
%MAKERCGTGRAPHSTOTABLE Summary of this function goes here
%   Detailed explanation goes here
    
    addpath('main_code');
    main_d = '/home/ahumayun/algosuitability/Results/VideoSegTest/RCGT_VS';

    d = dir(fullfile(main_d, '*-RCGT'));
    seq = [9 10 17 18 19 22 26 29 30 49]
    tbl_f1 = zeros(length(d), length(seq));
    tbl_auc = zeros(length(d), length(seq));
    
    dir_names = cell(size(d));
    
    for idx = 1:length(d)
        for seq_idx = 1:length(seq)
            % search for output file
            f = dir(fullfile(main_d, d(idx).name, 'result', sprintf('%d_*rffeatureimp.mat',seq(seq_idx))));
            load(fullfile(main_d, d(idx).name, 'result', f(1).name));
            tbl_f1(idx, seq_idx) = classifier_output.max_f1_score_pr;
            tbl_auc(idx, seq_idx) = classifier_output.area_under_roc;
        end
        
        dir_names{idx} = d(idx).name;
    end
    
    [temp ordering] = sort(cellfun(@length,dir_names));
    dir_names = dir_names(ordering);
    tbl_auc = tbl_auc(ordering,:);
    tbl_f1 = tbl_f1(ordering,:);
    
    features = regexp(dir_names, '_([a-zA-Z])+', 'tokens');
    features = cellfun(@(x) cellfun(@(y) y{1}, x, 'UniformOutput',false), features, 'UniformOutput',false);
    for idx = 1:length(d)
        txt = cell2mat(cellfun(@(x) sprintf('+\\textrm{%s}',upper(x)), features{idx}, 'UniformOutput',false));
        features{idx} = txt(2:end);
    end
%     if length(features) == 5
%         features{end} = 'All Features';
%     else
%         features{end-1} = 'All Features';
%         features{end} = 'All Features + 4 flows';
%     end
    
    [max_val max_idx] = max(tbl_f1, [], 1);
    latex_txt = '';
    for idx = 1:length(d)
        latex_txt = [latex_txt sprintf('\n \\tiny %s & ', features{idx})];
        for idx2 = 1:length(seq)
            if idx == max_idx(idx2)
                latex_txt = [latex_txt sprintf('\\maintblfnt \\textbf{%.3f} & ', tbl_f1(idx,idx2))];
            else
                latex_txt = [latex_txt sprintf('\\maintblfnt %.3f & ', tbl_f1(idx,idx2))];
            end
        end
        latex_txt = [latex_txt(1:end-2) '\\ \hline'];
    end
end
