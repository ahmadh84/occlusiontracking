function [ output_args ] = combine_varying_settings( results_dir )
%COMBINE_VARYING_TRAINING Summary of this function goes here
%   Detailed explanation goes here

    close all;
    
    addpath('main_code');
    
    border = 10;
    
    calcflows_id = '1529'; %'2606'; %'1532';
    
    out_im_dir = 'C:\Users\Ahmad\Documents\UCL\MS Thesis - Learning Occlusion Regions\Writeup\oisin_PAMI\images';
    data_dir = 'E:\Data\oisin+middlebury';

    d = dir(results_dir);
    
    epe_table = [];
    
    inside_dir_desc = [];
    seq_ids = {};
    worst_opt_epe = [];
    
    for d_idx = 1:length(d)
        d_inside = dir(fullfile(fileparts(results_dir), d(d_idx).name));
        fprintf('Checking inside dir %s\n', d(d_idx).name);
        
        d_inside(arrayfun(@(x) x.name(1)=='.', d_inside)) = [];
        
        for d_idx2 = 1:length(d_inside)
            fprintf('\tChecking for EPEs for %s\n', d_inside(d_idx2).name);
            
            if d_idx == 1
                inside_dir_desc(end+1) = str2num(d_inside(d_idx2).name);
                curr_d_idx = length(inside_dir_desc);
            else
                curr_d_idx = find(inside_dir_desc == str2num(d_inside(d_idx2).name));
                if isempty(curr_d_idx)
                    continue;
                end
            end
            
            f = dir(fullfile(fileparts(results_dir), d(d_idx).name, d_inside(d_idx2).name, 'result', '*_rffeatureimp.mat'));

            for f_idx = 1:length(f)
                % load classifier output
                load(fullfile(fileparts(results_dir), d(d_idx).name, d_inside(d_idx2).name, 'result', f(f_idx).name));

                scene_id = num2str(classifier_output.scene_id);
                if d_idx == 1 && d_idx2 == 1
                    seq_ids{end+1} = scene_id;
                    curr_f_idx = length(seq_ids);
                else
                    curr_f_idx = strmatch(scene_id, seq_ids);
                    if isempty(curr_f_idx)
                        continue;
                    end
                end
                frame_sz = size(classifier_output.classifier_out);
                
                % load calc flows file
                load(fullfile(data_dir, scene_id, sprintf('%s_%s_gt.mat', scene_id, calcflows_id)));

                border_mask = true(frame_sz);
                border_mask([1:border end-border+1:end],:) = false;
                border_mask(:,[1:border end-border+1:end]) = false;

                % calculate the EPE values
                valid_mask = flow_info.gt_mask & border_mask;
                [rx cx] = find(valid_mask);
        
                % compute the resulting EPE from the classifier
                valid_clsfr_out = classifier_output.classifier_out(valid_mask);
                valid_epe_ind = sub2ind(size(flow_info.uv_epe), rx, cx, valid_clsfr_out);
                classifier_epe = mean(flow_info.uv_epe(valid_epe_ind));
                epe_table(curr_f_idx, curr_d_idx, d_idx) = classifier_epe;

                if d_idx == 1 && d_idx2 == 1
                    opt_epe = min(flow_info.uv_epe, [], 3);
                    opt_epe = mean(opt_epe(valid_mask));
                    
                    worse_epe = max(flow_info.uv_epe, [], 3);
                    worse_epe = mean(worse_epe(valid_mask));
                    
                    sz = size(flow_info.uv_epe);
                    temp = randi(sz(3), sz([1 2]));
                    [c r] = meshgrid(1:sz(2), 1:sz(1));
                    temp = flow_info.uv_epe(sub2ind(sz, r,c,temp));
                    rand_epe = mean(temp(valid_mask));
                    
                    worst_opt_epe(curr_f_idx,:) = [worse_epe opt_epe rand_epe];
                    fprintf(1, 'Scene ID %s - Worst EPE %0.4f - Opt. EPE %0.4f - Rand. EPE %.4f\n', scene_id, worse_epe, opt_epe, rand_epe);
                end
            end
        end
    end
    
    [inside_dir_desc s_idxs] = sort(inside_dir_desc);
    epe_table = epe_table(:,s_idxs,:);
    
    epe_table = mean(epe_table, 3);
    plot(inside_dir_desc, epe_table, '-x');
    set(gca, 'XScale','log');
    
    xlabel('Training samples per class per sequence');
    ylabel('Avg. EPE');
    h_legend = legend(arrayfun(@(x) sprintf('Sequence %s - Worse %.3f, Opt. %.3f, Rand. %.3f', seq_ids{x},worst_opt_epe(x,1),worst_opt_epe(x,2),worst_opt_epe(x,3)), 1:length(seq_ids), 'UniformOutput',false));
    set(h_legend,'FontSize',8);
    ylim([0 4.8]);
    
    set(gcf,'PaperPositionMode','auto');
    print('-depsc', '-r0', fullfile(out_im_dir, 'training_samples'));
end

