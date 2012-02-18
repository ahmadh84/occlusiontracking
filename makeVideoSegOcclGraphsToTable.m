function [ latex_txt features tbl_auc tbl_f1 ] = makeRCGTGraphsToTable( input_args )
%MAKERCGTGRAPHSTOTABLE Summary of this function goes here
%   Detailed explanation goes here
    
    seq_names = {'Venus', 'Urban3', 'Urban2', 'RubberWhale', 'Hydrangea', 'Grove3', 'Grove2', 'Dimetrodon', ...
        'Crates1*', 'Crates2*', 'Brickbox1*', 'Brickbox2*', 'Mayan1*', 'Mayan2*', 'YosemiteSun', 'GroveSun', ...
        'Robot*', 'Sponza1*', 'Sponza2*', 'Crates1Ltxtr*', 'Crates1Htxtr1*', 'Crates1Htxtr2*', 'Crates2Ltxtr*', ...
        'Crates2Htxtr1*', 'Crates2Htxtr2*', 'Brickbox1t1*', 'Brickbox1t2*', 'Brickbox2t1*', 'Brickbox2t2*', ...
        'GrassSky0*', 'GrassSky1*', 'GrassSky2*', 'GrassSky3*', 'GrassSky4*', 'GrassSky5*', 'GrassSky6*', 'GrassSky7*', ...
        'GrassSky8*', 'GrassSky9*', 'Crates1deg1LTxtr*', 'Crates1deg4LTxtr*', 'Crates1deg7LTxtr*', 'Crates1deg1HTxtr1*', ...
        'Crates1deg3HTxtr1*', 'Crates1deg7HTxtr1*', 'Crates1deg1HTxtr2*', 'Crates1deg4HTxtr2*', 'Crates1deg7HTxtr2*', ...
        'TxtRMovement*', 'TextLMovement*'};
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('blow%dTxtr1*',x), 1:19, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('blow%dTxtr2*',x), 1:19, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('drop%dTxtr1*',x), 1:9, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('drop%dTxtr2*',x), 1:9, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('roll%dTxtr1*',x), 1:9, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('roll%dTxtr2*',x), 1:9, 'UniformOutput',false));
    seq_names = horzcat(seq_names, arrayfun(@(x) sprintf('street%dTxtr1*',x), 1:4, 'UniformOutput',false));
    
    addpath('main_code');
    main_d = '/home/ahumayun/algosuitability/Results/VideoSegTest/TestsImproveClassifier';

    d = dir(fullfile(main_d, '*TVV*'));
    seq = [4 5 9 10 11 12 13 14 17 18 19 22 24 26 27 28 29 30 39 40 41 42 43 44 45 46 47 48 49 50];
    tbl_f1 = zeros(length(d), length(seq));
    tbl_auc = zeros(length(d), length(seq));
    
    dir_names = cell(size(d));
    features = {'Baseline', ...
                '+LD', ...
                '+LD, noise 3e-4', ...
                '+LD, noise 5e-4', ...
                'New PC, +LD, noise 3e-4', ...
                'New PC, +LD, scale 6, noise 3e-4', ...
                'New PC, +LD, scale 4, noise 3e-4', ...
                'New PC, scale 4, noise 3e-4', ...
                'New training, New PC,LV,CS,RC, scale 6, noise 3e-4'};
    
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
    
%     [temp ordering] = sort(cellfun(@length,dir_names));
%     dir_names = dir_names(ordering);
%     tbl_auc = tbl_auc(ordering,:);
%     tbl_f1 = tbl_f1(ordering,:);
%     
%     features = regexp(dir_names, '_([a-zA-Z])+', 'tokens');
%     features = cellfun(@(x) cellfun(@(y) y{1}, x, 'UniformOutput',false), features, 'UniformOutput',false);
%     for idx = 1:length(d)
%         txt = cell2mat(cellfun(@(x) sprintf('+\\textrm{%s}',upper(x)), features{idx}, 'UniformOutput',false));
%         features{idx} = txt(2:end);
%     end
%     if length(features) == 5
%         features{end} = 'All Features';
%     else
%         features{end-1} = 'All Features';
%         features{end} = 'All Features + 4 flows';
%     end
    
    [max_val max_idx] = max(tbl_f1, [], 1);
    latex_txt = '';
    for idx = 1:length(seq)
        latex_txt = [latex_txt sprintf('\n \\tiny %s & ', seq_names{seq(idx)})];
        for idx2 = 1:length(features)
            if idx2 == max_idx(idx)
                latex_txt = [latex_txt sprintf('\\maintblfnt \\textbf{%.3f} & ', tbl_f1(idx2,idx))];
            else
                latex_txt = [latex_txt sprintf('\\maintblfnt %.3f & ', tbl_f1(idx2,idx))];
            end
        end
        latex_txt = [latex_txt(1:end-2) '\\ \hline'];
    end
end
