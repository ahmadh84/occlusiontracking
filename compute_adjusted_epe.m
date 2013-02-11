function latex_tbl = compute_adjusted_epe(results_dir, main_out_dir, data_dir, conf_dir, confidence_epe_th)
%COMPUTE_ADJUSTED_EPE for reproducing TABLE 2 in Mac Aodha et al. PAMI 2012
% without the OursCombo column. 
%
% @args
%   results_dir: where testing_algosuitability writes its results - i.e.
%                this variable should be equal to [temp_out_dir] in 
%                testing_algosuitability.m
%
%   main_out_dir: output directory where the output bar chart and latex
%                table is written (in [main_out_dir]/images/ and
%                [main_out_dir]/latex/ respectively)
%
%   data_dir: the directory where all the sequences are stored - i.e. it
%                should be equivalent to [training_dir] in
%                testing_algosuitability.m
%
%   conf_dir: the directory where results for all the different confidence 
%                thresholds are stored in sub-directories - i.e. this
%                variable should be equal to [out_dir] in
%                testing_ofconfidence.m. If this variable is not defined
%                then the OursCombo values are not produced
%
%   confidence_epe_th: a vector of confidence values used for producing 
%                results in [conf_dir]. This is the set of values used in
%                testing_ofconfidence main for loop. If not defined it will
%                default to [0.1 0.25 0.5 2 10]

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
    
    close all;
    
    addpath('main_code');
    
    border = 10;
    
    calcflows_id = '1529';
    if exist('confidence_epe_th', 'var') == 0
        confidence_epe_th = [0.1 0.25 0.5 2 10];
    end
    l2norm_div = 1.0;
    
    if exist('conf_dir', 'var') == 0
        conf_dir = [];
    end
    
    % output directories
    out_im_dir = fullfile(main_out_dir, 'images');
    out_ltx_dir = fullfile(main_out_dir, 'latex');
    if ~exist(out_im_dir,'dir')
        mkdir(out_im_dir);
    end
    if ~exist(out_ltx_dir,'dir')
        mkdir(out_ltx_dir);
    end

    f = dir(fullfile(results_dir, 'result', '*_rffeatureimp.mat'));
    
    epe_table = [];
    
    gradmag_obj = GradientMagFeature;
    
    col_title = {};
    
    for idx = 1:length(f)
        curr_col = 1;
        
        % load classifier output
        load(fullfile(results_dir, 'result', f(idx).name));
        
        fprintf(1, 'Computing Avg EPE for sequence %d\n',classifier_output.scene_id);
        
        epe_table(idx,curr_col) = classifier_output.scene_id;
        col_title{curr_col} = 'Image Sequence';
        curr_col = curr_col + 1;
        
        scene_id = num2str(classifier_output.scene_id);
        frame_sz = size(classifier_output.classifier_out);
        
        % load calc flows file
        load(fullfile(data_dir, scene_id, sprintf('%s_%s_gt.mat', scene_id, calcflows_id)));
        
        border_mask = true(frame_sz);
        border_mask([1:border end-border+1:end],:) = false;
        border_mask(:,[1:border end-border+1:end]) = false;
        
        % calculate the EPE values
        valid_mask = flow_info.gt_mask & border_mask;
        [rx cx] = find(valid_mask);
        
        %%%%%%%%%%%%%%% ADJUST Calcflows %%%%%%%%%%%%%%%%%%
%         for algo_idx = 1:length(flow_info.algo_ids)
%            %[ flow_info.uv_ang_err(:,:,algo_idx) flow_info.uv_epe(:,:,algo_idx) ] = flowAngErrMe(flow_info.uv_gt(:,:,1), flow_info.uv_gt(:,:,2), ...
%             %                                                                                   flow_info.uv_flows(:,:,1,algo_idx), flow_info.uv_gt(:,:,2));
%            [ flow_info.uv_ang_err(:,:,algo_idx) flow_info.uv_epe(:,:,algo_idx) ] = flowAngErrMe(flow_info.uv_gt(:,:,1), flow_info.uv_gt(:,:,2), ...
%                                                                                                flow_info.uv_gt(:,:,1), flow_info.uv_flows(:,:,2,algo_idx));
%         end
        %%%%%%%%%%%%%%% ADJUST Calcflows fin %%%%%%%%%%%%%%%%%%
        
        % calculate avg epe for each algo
        for flow_idx = 1:length(flow_info.algo_ids)
            flow_indcs = sub2ind(size(flow_info.uv_epe), rx, cx, repmat(flow_idx,size(cx)));
            flow_epe = mean(flow_info.uv_epe(flow_indcs));
            
            epe_table(idx, curr_col) = flow_epe;
            col_title{curr_col} = flow_info.algo_ids{flow_idx};
            curr_col = curr_col + 1;
        end
        
        % compute TrivComb
        calc_feature_vec.im1 = imread(fullfile(data_dir, scene_id, '1.png'));
        if size(calc_feature_vec.im1,3) > 1
            calc_feature_vec.im1_gray = im2double(rgb2gray(calc_feature_vec.im1));
        else
            calc_feature_vec.im1_gray = im2double(calc_feature_vec.im1);
        end
        grad = gradmag_obj.calcFeatures(calc_feature_vec);
%         nnz(grad>10)
        epe_table(idx, curr_col) = NaN;
        col_title{curr_col} = 'TrivComb';
        curr_col = curr_col + 1;
        
        % compute the resulting EPE from the classifier (OursKWay)
        valid_clsfr_out = classifier_output.classifier_out(valid_mask);
        valid_epe_ind = sub2ind(size(flow_info.uv_epe), rx, cx, valid_clsfr_out);
        classifier_epe = mean(flow_info.uv_epe(valid_epe_ind));
        epe_table(idx, curr_col) = classifier_epe;
        col_title{curr_col} = 'OursKWay';
        curr_col = curr_col + 1;
        
        % choose the algorithm having most votes in the scene (OursScene)
        h = hist(classifier_output.classifier_out(:), 1:length(flow_info.algo_ids));
        [no_votes max_votes_algo] = max(h);
        max_votes_epe = flow_info.uv_epe(:,:,max_votes_algo);
        max_votes_epe = mean(max_votes_epe(valid_mask));
        epe_table(idx, curr_col) = max_votes_epe;
        col_title{curr_col} = 'OursScene';
        curr_col = curr_col + 1;
        
        if ~isempty(conf_dir)
            sz = size(flow_info.uv_epe);

            % EPE using the most confident algo (OursCombo)
            [ conf_epe ] = epe_max_overall_confidence(sz, confidence_epe_th, flow_info, valid_mask, conf_dir, classifier_output);
            epe_table(idx, curr_col) = conf_epe;
            col_title{curr_col} = 'OursCombo';
            curr_col = curr_col + 1;

            % EPE using the closest matched confidence classifier according to median flow length
            [ conf_epe ] = epe_max_confidence_len(sz, confidence_epe_th, flow_info, valid_mask, conf_dir, classifier_output, l2norm_div);
            epe_table(idx, curr_col) = conf_epe;
            col_title{curr_col} = 'OursComboFlowLen';
            curr_col = curr_col + 1;
        end
        
        % choose an algorithm randomly at each pixel (RandCombo)
        sz = size(flow_info.uv_epe);
        temp = randi(sz(3), sz([1 2]));
        [c r] = meshgrid(1:sz(2), 1:sz(1));
        temp = flow_info.uv_epe(sub2ind(sz, r,c,temp));
        rand_epe = mean(temp(valid_mask));
        epe_table(idx, curr_col) = rand_epe;
        col_title{curr_col} = 'RandCombo';
        curr_col = curr_col + 1;
        
        % choose the algo which has the least EPE at each pixel (OptCombo)
        opt_epe = min(flow_info.uv_epe, [], 3);
        opt_epe = mean(opt_epe(valid_mask));
        epe_table(idx, curr_col) = opt_epe;
        col_title{curr_col} = 'OptCombo';
        curr_col = curr_col + 1;
    end

    % throw away TrivComb column
    epe_table(:,strcmp(col_title, 'TrivComb')) = [];
    col_title(strcmp(col_title, 'TrivComb')) = [];
    
    % sort the table according to sequence numbers
    [temp sorted_idxs] = sort(epe_table(:,1));
    epe_table = epe_table(sorted_idxs,:);
    
    % write the header for the latex table
    latex_tbl = sprintf('{\\tblfnt %s} & ', col_title{:});
    latex_tbl = sprintf('\n%s \\\\ \\hline', latex_tbl(1:end-3));
    
    % write the rest of the latex table
    for idx = 1:size(epe_table,1)
        latex_tbl = [latex_tbl sprintf('\n\\textbf{%d \\hfill %s}', ...
                     epe_table(idx,1), seq_names{epe_table(idx,1)})];
        
        [temp min_epe_idx] = min(epe_table(idx,[2:end-2]));
        min_epe_idx = min_epe_idx + 1;
        
        for idx2 = 2:size(epe_table,2)
            if min_epe_idx == idx2
                latex_tbl = [latex_tbl sprintf(' & \\textbf{%.3f}', ...
                                               epe_table(idx,idx2))];
            else
                latex_tbl = [latex_tbl sprintf(' & {\\tblfnt %.3f}', ...
                                               epe_table(idx,idx2))];
            end
        end
        
        latex_tbl = [latex_tbl ' \\ \hline'];
    end
    [temp fldr] = fileparts(results_dir);
    fd = fopen(fullfile(out_ltx_dir, fldr), 'w+');
    fprintf(fd, strrep(latex_tbl, '\', '\\'));
    fclose(fd);
    
    % draw the avg EPE bar chart
    vals = epe_table(:,2:end);
%     vals(:,end-3) = [];
    mean_epe = mean(vals);
    h = barh(mean_epe, 'w');
    set(gcf, 'Position', [10 10 300 (55*length(mean_epe))+70]);
    set(gca, 'YTickLabel',col_title(2:end), 'FontSize',14);
    line(get(gca,'XLim'), ...
        repmat(length(classifier_output.settings.label_obj.label_names)+2.5, ...
        [1 2]), 'LineStyle','--', 'Color','k');
    xlabel('Avg. EPE');
    
    for idx = 1:length(mean_epe)
        text(mean_epe(idx), idx, sprintf('%.3f  ',mean_epe(idx)), ...
            'horizontalAlignment','right');
    end
    set(gcf,'PaperPositionMode','auto');
    print('-depsc', '-r0', fullfile(out_im_dir, fldr));
end


function [ conf_epe ] = epe_max_overall_confidence(sz, confidence_epe_th, flow_info, valid_mask, conf_dir, classifier_output)
% iterates over all flow confidence tests (number of confidence threshold x
% number of flow algorithms) and chooses the most confident flow algorithm 
% for each pixel .. and returns the average EPE over the whole frame

    max_conf = -inf(sz(1),sz(2));
    conf_algo = nan(sz(1),sz(2));
    for conf_idx = 1:length(confidence_epe_th)
        conf_mat = zeros(sz);

        for flow_idx = 1:length(flow_info.algo_ids)
            temp_out_dir = fullfile(conf_dir, sprintf('FC_%0.2f-gm_ed_pb_pb_tg_pc-%s', confidence_epe_th(conf_idx), flow_info.algo_ids{flow_idx}));

            temp = dir(fullfile(temp_out_dir, sprintf('%d_*_%s_prediction.data', classifier_output.scene_id, flow_info.algo_ids{flow_idx})));
            classifier_out = textread(fullfile(temp_out_dir, temp.name), '%f');

            conf_mat(:,:,flow_idx) = reshape(classifier_out, sz(2), sz(1))';
        end
        [curr_max_conf curr_conf_algo] = max(conf_mat, [], 3);
%         disp(nnz(curr_max_conf > max_conf));
        conf_algo(curr_max_conf > max_conf) = curr_conf_algo(curr_max_conf > max_conf);
        max_conf(curr_max_conf > max_conf) = curr_max_conf(curr_max_conf > max_conf);
    end
    [c r] = meshgrid(1:sz(2), 1:sz(1));
    temp = flow_info.uv_epe(sub2ind(sz, r,c,conf_algo));
    conf_epe = mean(temp(valid_mask));
end


function [ conf_epe ] = epe_max_confidence_len(sz, confidence_epe_th, flow_info, valid_mask, conf_dir, classifier_output, l2norm_div)
    l2norm = hypot(flow_info.uv_flows(:,:,1,:),flow_info.uv_flows(:,:,2,:));
    l2norm = squeeze(l2norm);
    l2norm = median(l2norm, 3) .* l2norm_div;
    
    conf_th_choice = ones(sz([1 2]));
    
    for conf_idx = 1:length(confidence_epe_th)-1
        conf_th_choice(l2norm > confidence_epe_th(conf_idx)) = conf_idx+1;
    end
    
    [c r] = meshgrid(1:sz(2), 1:sz(1));
    epe_mat = zeros(sz([1 2]));
    conf_idxs = unique(conf_th_choice);
    for conf_idx = conf_idxs'
        conf_mat = zeros(sz);

        for flow_idx = 1:length(flow_info.algo_ids)
            temp_out_dir = fullfile(conf_dir, sprintf('FC_%0.2f-gm_ed_pb_pb_tg_pc-%s', confidence_epe_th(conf_idx), flow_info.algo_ids{flow_idx}));

            temp = dir(fullfile(temp_out_dir, sprintf('%d_*_%s_prediction.data', classifier_output.scene_id, flow_info.algo_ids{flow_idx})));
            classifier_out = textread(fullfile(temp_out_dir, temp.name), '%f');

            conf_mat(:,:,flow_idx) = reshape(classifier_out, sz(2), sz(1))';
        end
        [curr_max_conf curr_conf_algo] = max(conf_mat, [], 3);
        temp = flow_info.uv_epe(sub2ind(sz, r,c,curr_conf_algo));
        epe_mat(conf_th_choice == conf_idx) = temp(conf_th_choice == conf_idx);
    end
    
    conf_epe = mean(epe_mat(valid_mask));
end


function graph_of_removal(epe_table, settings, filepath)
    [temp pull_order] = sort(min(epe_table(:,2:end-2), [], 2));
    
    removal_epes = zeros(size(epe_table));
    
    no_to_pull = 0;
    while no_to_pull < size(epe_table,1)
        curr_epe_table = epe_table;
        curr_epe_table(pull_order(end-no_to_pull+1:end),:) = [];
        
        mean_epe = mean(curr_epe_table(:,2:end),1);
        if no_to_pull > 0
            removal_epes(no_to_pull+1,1) = epe_table(pull_order(end-no_to_pull+1),1);
        end
        removal_epes(no_to_pull+1,2:end) = mean_epe;
        
        no_to_pull = no_to_pull + 1;
    end
    
    figure
    hs = plot(removal_epes(:,2:end));
    set(hs(end-2), 'LineStyle', '--', 'Marker','o', 'MarkerSize',5);
    set(hs(end-3), 'LineStyle', '--', 'Marker','*', 'MarkerSize',5);
    
    set(hs(end), 'LineStyle', ':', 'Color',[0 0 0]);
    set(hs(end-1), 'LineStyle', ':', 'Color',[0.6 0.6 0.6]);
    
    legend([settings.label_obj.label_names 'Ours' 'Ours Confd' 'RandCombo' 'OptCombo']);

    ax = axis; % Current axis limits
    axis(axis); % Set the axis limit modes (e.g. XLimMode) to manual
    Yl = ax(3:4); % Y-axis limits
    
    set(gca, 'XTickLabel','', 'XTick',1:no_to_pull);
    t = text([2:no_to_pull], Yl(1)*ones(1,no_to_pull-1), arrayfun(@(x) sprintf('%d ',x), removal_epes(2:end,1), 'UniformOutput',false), 'FontSize',8);
    set(t,'HorizontalAlignment','right','VerticalAlignment','top', 'Rotation',90, 'VerticalAlignment','middle');
    
    ylabel('Avg. EPE');
%     xlabel('Removed Sequence ID');
    
    set(gcf, 'Position', [10 10 1200 400]);
    print('-depsc', '-r0', filepath);
end

