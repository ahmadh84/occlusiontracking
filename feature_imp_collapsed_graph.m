function feature_imp_collapsed_graph( imp_filepath )
%FEATURE_IMP_COLLAPSED_GRAPH Summary of this function goes here
%   Detailed explanation goes here
    
    if ~exist('imp_filepath','var')
        imp_filepath = '';
    end

    close all;
    
    d = 'H:\middlebury\features_comparison_tests5\FINAL-ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp\result\';
%     d = 'H:\middlebury\features_comparison_tests5\LEAN1-ed_pc_tg_av_lv_cs-max_rc_ra_fa_fn\result\';
    
    files = dir(fullfile(d, '*_rffeatureimp.mat'));
    files = {files.name};

    compute_times = [];
    feature_importance = [];
    extra_compute_times = {};
    flow_compute_times = [];
    
    for idx = 1:length(files)
        load(fullfile(d, files{idx}));
        compute_times = [compute_times; classifier_output.feature_compute_times];
        feature_importance = [feature_importance; classifier_output.feature_importance'];
        flow_compute_times = [flow_compute_times; classifier_output.flow_compute_times];
        if isempty(extra_compute_times)
            extra_compute_times = classifier_output.extra_compute_times;
        else
            extra_compute_times(:,2) = arrayfun(@(idx) [extra_compute_times{idx,2} classifier_output.extra_compute_times{idx,2}], 1:size(extra_compute_times,1), 'UniformOutput',false)';
        end
    end
    
    feature_types = classifier_output.feature_types;
    feature_depths = classifier_output.feature_depths;
    fc_idxs = find(strcmp(feature_types, FlowConfidenceFeature.FEATURE_SHORT_TYPE));
    if ~isempty(fc_idxs)
        only_tested_fc = ~cellfun(@isempty, regexp(files', '(?:^2_)|(?:^3_)|(?:^49_)|(?:^50_)'));
        fc_compute_times = compute_times(only_tested_fc,fc_idxs);
        compute_times = mean(compute_times, 1);
        compute_times(fc_idxs) = mean(fc_compute_times,1);
    else
        compute_times = mean(compute_times, 1);
    end
    flow_compute_times = mean(flow_compute_times, 1);
    
    total_feature_time = sum(compute_times);
    fprintf(1, 'Testing time\t %f(s)\n', mean(extra_compute_times{2,2}((extra_compute_times{2,2} < 1000)))+total_feature_time);
    fprintf(1, 'Training time\t %f(s)\n', mean(extra_compute_times{2,2}((extra_compute_times{2,2} >= 1000)))+total_feature_time);
    
    
    % adjust for flow confidence
    fc_idxs = find(strcmp(feature_types, FlowConfidenceFeature.FEATURE_SHORT_TYPE));
    fc_epe = [50 1];
    indv_fc_appender = {'epe', 'ae'};
    fc_appender = {'H', 'L'};
    replace_feat_types = {};
    replace_feature_depths = [];
    replace_for = [];
    for idx = fc_idxs
        type_idx = classifier_output.settings.cell_features{idx}.confidence_epe_th == fc_epe;
        replace_feat_types = [replace_feat_types [FlowConfidenceFeature.FEATURE_SHORT_TYPE indv_fc_appender{1} ',' fc_appender{type_idx}]];
        replace_feat_types = [replace_feat_types [FlowConfidenceFeature.FEATURE_SHORT_TYPE indv_fc_appender{2} ',' fc_appender{type_idx}]];
        replace_for = [replace_for; idx length(replace_feat_types)-1 length(replace_feat_types)];
        
        % shuffle feature importance
        temp = [0 cumsum(feature_depths)];
        family_idxs = [temp(1:end-1)+1; temp(2:end)]';
        feature_importance(:,family_idxs(idx,1):family_idxs(idx,2)) = feature_importance(:,[family_idxs(idx,1):2:family_idxs(idx,2) family_idxs(idx,1)+1:2:family_idxs(idx,2)]);
        replace_feature_depths = [replace_feature_depths length(family_idxs(idx,1):2:family_idxs(idx,2)) length(family_idxs(idx,1)+1:2:family_idxs(idx,2))];
    end
    
    for idx = size(replace_for,1):-1:1
        curr_idx = replace_for(idx,1);
        replacements = replace_for(idx,2:end);
        
        compute_times = [compute_times(1:curr_idx-1) repmat(compute_times(curr_idx)/length(replacements),1,length(replacements)) compute_times(curr_idx+1:end)];
        feature_depths = [feature_depths(1:curr_idx-1) replace_feature_depths(replacements) feature_depths(curr_idx+1:end)];
        feature_types = [feature_types(1:curr_idx-1) replace_feat_types(replacements) feature_types(curr_idx+1:end)];
    end
    
    % collapse feature importance
    temp = [0 cumsum(feature_depths)];
    family_idxs = [temp(1:end-1)+1; temp(2:end)]';
    family_imp = cell2mat(arrayfun(@(i) sum(feature_importance(:,family_idxs(i,1):family_idxs(i,2)),2), 1:size(family_idxs,1), 'UniformOutput',false));
    family_imp = mean(family_imp, 1);
    
    % distribute time for fPB
    pb_idxs = find(strcmp(feature_types, PbEdgeStrengthFeature.FEATURE_SHORT_TYPE));
    compute_times(pb_idxs) = sum(compute_times(pb_idxs))/2;

    % distribute time for fST
    st_idxs = find(strcmp(feature_types, SparseSetTextureFeature.FEATURE_SHORT_TYPE) | strcmp(feature_types, SparseSetTextureFeature2.FEATURE_SHORT_TYPE));
    compute_times(st_idxs) = sum(compute_times(st_idxs))/2;
    
    % adjust feature types to Latex
    for idx = 1:length(feature_types)
        feature_types{idx} = ['$f_{\text{' feature_types{idx} '}}$'];
    end
    feature_types{2} = '$f_{\text{PB}},\tau_{\text{PB}}=0.1$';
    feature_types{3} = '$f_{\text{PB}},\tau_{\text{PB}}=0.4$';
    feature_types{13} = '$f_{\text{FC}_{text{EPE}}},\tau_{\text{EPE}}=50$';
    feature_types{14} = '$f_{\text{FC}_{text{EPE}}},\tau_{\text{AE}}=60$';
    feature_types{15} = '$f_{\text{FC}_{text{EPE}}},\tau_{\text{EPE}}=1$';
    feature_types{16} = '$f_{\text{FC}_{text{EPE}}},\tau_{\text{AE}}=1$';
    
    printRFFeatureImp( feature_types, family_imp, compute_times, flow_compute_times, extra_compute_times, imp_filepath );
    
end

function printRFFeatureImp( feature_types, family_imp, feature_compute_times, flow_compute_times, extra_compute_times, imp_filepath )
    
    figure;
    
    [AX,H1,H2] = plotyy( 1:length(family_imp), family_imp, ...
           1:length(feature_compute_times), feature_compute_times, ...
            'bar', 'bar');
        
    set(H1,'BarWidth',0.6);
    set(H2,'BarWidth',0.2);
    set(H1, 'FaceColor', [0.8 0 0]);
    set(H1, 'EdgeColor', get(H1, 'FaceColor'));
    set(H2, 'FaceColor', [0 1 1]);
    set(H2, 'EdgeColor', [0.0 0.0 0.0]);
    
    set(get(AX(1),'Ylabel'),'String','Feature importance %');
    set(get(AX(2),'Ylabel'),'String','Computation time (s)');
    set(get(AX(1),'Ylabel'),'Color',[0.999 0.999 0.999]);
    set(get(AX(2),'Ylabel'),'Color',[0.999 0.999 0.999]);
    
    h = legend(get(get(AX(1),'Ylabel'),'String'), get(get(AX(2),'Ylabel'),'String'));
    set(h, 'TextColor',[0.999 0.999 0.999]);
    
    ax = axis; % Current axis limits
    axis(axis); % Set the axis limit modes (e.g. XLimMode) to manual
    Yl = ax(3:4); % Y-axis limits
%     t = text(1:length(family_imp),(Yl(1)+eps)*ones(1,length(family_imp)), feature_types, 'Interpreter', 'latex');
%     set(t,'HorizontalAlignment','right','VerticalAlignment','top', ...
%         'Rotation',45);

    set(AX(1), 'XTick', []);
    set(AX(2), 'XTick', []);
    
    set(gcf, 'Position', [100 100 950 300]);
    
    if ~strcmp(imp_filepath, '')
        print('-depsc', '-r0', imp_filepath);
    end
end

