function compare_output_visually()
%COMPARE_OUTPUT_VISUALLY Summary of this function goes here
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
    
    print_frmt = '-dpng';
    border = 10;
    
    calcflows_id = '1529'; %'2606'; %'1532';
    
    out_im_dir = 'C:\Users\Ahmad\Documents\UCL\MS Thesis - Learning Occlusion Regions\Writeup\oisin_PAMI\images\visual_compare';
    data_dir = 'E:\Data\oisin+middlebury';
    results_dir = 'E:\Results\oisin+results\gm_ed_pb_tg_pc-tv_fl_cn_ld_DISCR_new-motion-data';

    f = dir(fullfile(results_dir, 'result', '*_rffeatureimp.mat'));
    
    for idx = 1:length(f)
        load(fullfile(results_dir, 'result', f(idx).name));
        scene_id = classifier_output.scene_id;
        
        fprintf(1, 'Producing images for sequence %d\n',scene_id);
        
        % load calc flows file
        load(fullfile(data_dir, num2str(scene_id), sprintf('%d_%s_gt.mat', scene_id, calcflows_id)));
        
        image_sz = size(classifier_output.classifier_out);
        no_labels = length(classifier_output.settings.cell_flows);
        
        % print valid mask
        border_mask = true(image_sz);
        border_mask([1:border end-border+1:end],:) = false;
        border_mask(:,[1:border end-border+1:end]) = false;
        valid_mask = flow_info.gt_mask & border_mask;
        imshow(valid_mask)
        colormap summer
        set(gcf, 'units', 'pixels', 'position', [100 100 image_sz(2) image_sz(1)], 'paperpositionmode', 'auto');
        set(gca, 'position', [0 0 1 1], 'visible', 'off');
        print(print_frmt, '-r0', fullfile(out_im_dir, sprintf('%d_valid_mask', scene_id)));
        
        % produce k-way classification
        imagesc(classifier_output.classifier_out);
        colormap(jet(no_labels));
        set(gcf, 'units', 'pixels', 'position', [100 100 image_sz(2) image_sz(1)], 'paperpositionmode', 'auto');
        set(gca, 'position', [0 0 1 1], 'visible', 'off');
        print(print_frmt, '-r0', fullfile(out_im_dir, sprintf('%d_classifier_result', scene_id)));
        
        % optimal k-way classification
        imagesc(flow_info.class_epe);
        colormap(jet(no_labels));
        set(gcf, 'units', 'pixels', 'position', [100 100 image_sz(2) image_sz(1)], 'paperpositionmode', 'auto');
        set(gca, 'position', [0 0 1 1], 'visible', 'off');
        print(print_frmt, '-r0', fullfile(out_im_dir, sprintf('%d_class_min_epe', scene_id)));
        
        % print first-second EPE image
        close all;
        gap_epe = flow_info.epe_dist_btwfirstsec;
        gap_epe(~valid_mask) = 0;
        imagesc(gap_epe);
        colorbar
        colormap gray;
        set(gcf, 'units', 'pixels', 'position', [100 100 image_sz(2)*1.15 image_sz(1)], 'paperpositionmode', 'auto');
        set(gca, 'visible', 'off');
        print(print_frmt, '-r0', fullfile(out_im_dir, sprintf('%d_firstsec_epedist', scene_id)));
end

