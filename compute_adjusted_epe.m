function latex_tbl = compute_adjusted_epe(results_dir, main_out_dir, data_dir)
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
    
    for idx = 1:length(f)
        % load classifier output
        load(fullfile(results_dir, 'result', f(idx).name));
        
        fprintf(1, 'Computing Avg EPE for sequence %d\n',classifier_output.scene_id);
        
        epe_table(idx,1) = classifier_output.scene_id;
        
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
            
            epe_table(idx, flow_idx+1) = flow_epe;
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
        epe_table(idx, length(flow_info.algo_ids)+2) = NaN;
        
        % compute the resulting EPE from the classifier (OursKWay)
        valid_clsfr_out = classifier_output.classifier_out(valid_mask);
        valid_epe_ind = sub2ind(size(flow_info.uv_epe), rx, cx, valid_clsfr_out);
        classifier_epe = mean(flow_info.uv_epe(valid_epe_ind));
        epe_table(idx, length(flow_info.algo_ids)+3) = classifier_epe;
        
        % choose the algorithm having most votes in the scene (OursScene)
        h = hist(classifier_output.classifier_out(:), 1:length(flow_info.algo_ids));
        [no_votes max_votes_algo] = max(h);
        max_votes_epe = flow_info.uv_epe(:,:,max_votes_algo);
        max_votes_epe = mean(max_votes_epe(valid_mask));
        epe_table(idx, length(flow_info.algo_ids)+4) = max_votes_epe;
        
        % choose an algorithm randomly at each pixel (RandCombo)
        sz = size(flow_info.uv_epe);
        temp = randi(sz(3), sz([1 2]));
        [c r] = meshgrid(1:sz(2), 1:sz(1));
        temp = flow_info.uv_epe(sub2ind(sz, r,c,temp));
        rand_epe = mean(temp(valid_mask));
        epe_table(idx, length(flow_info.algo_ids)+5) = rand_epe;
        
        % choose the algo which has the least EPE at each pixel (OptCombo)
        opt_epe = min(flow_info.uv_epe, [], 3);
        opt_epe = mean(opt_epe(valid_mask));
        epe_table(idx, length(flow_info.algo_ids)+6) = opt_epe;
    end

    epe_table(:,end-4) = [];
    
    [temp sorted_idxs] = sort(epe_table(:,1));
    epe_table = epe_table(sorted_idxs,:);
    
    % write the header for the latex table
    flow_id_latex = sprintf(' {\\tblfnt %s} &', flow_info.algo_ids{:});
    latex_tbl = sprintf(['\n{\\tblfnt Image Sequence} &%s ', ...
                        '{\\tblfnt OursKWay} & {\\tblfnt OursScene} & ', ...
                        '{\\tblfnt RandCombo} & {\\tblfnt OptCombo} ', ...
                        '\\\\ \\hline'], flow_id_latex);
    
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
    set(gca, 'YTickLabel',[ classifier_output.settings.label_obj.label_names ...
            'OursKWay' 'OursScene' 'RandCombo' 'OptCombo'], 'FontSize',14);
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

