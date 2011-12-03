function testing_script_sf
%TESTING_SCRIPT Summary of this function goes here
%   Detailed explanation goes here
    
    seq_conflicts = {[2 3], [6 7 16], [11 12], [13 14], [18 19], [9 20 21 22 40:48 10 23 24 25], [26 27 28 29], [30:39], [49:50]};
    [ override_settings ] = create_override_settings( seq_conflicts );
    out_dir = 'D:/ahumayun/Results/features_comparison_tests5';
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test middlebury sequences %
    main_dir = '../../Data/oisin+middlebury';
    temp_out_dir = fullfile(out_dir, 'SF-ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp');

    training_seq = [9 10 17 18 19 22 24 26 29 30 39 49 50];
    testing_seq = [1:6 9:14 17:19 22 24 26:29 30 39 40:48 49 50];
    
    [ MAIN_CLASS_XML_PATH ] = trainTestDelete('trainTestDeleteMain', testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
    
%     MAIN_CLASS_XML_PATH = 'D:\ahumayun\Results\features_comparison_tests5\SF-ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp\808654_class.xml';
    
    % check if the classifier exist before proceedings
    assert(exist(MAIN_CLASS_XML_PATH, 'file')==2, 'Main classifier XML doesn''t exist');
    
    seq_conflicts = {};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Test stein sequences %%%
%     main_dir = '../../Data/evaluation_data/stein';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'stein');
%     testing_seq = [1 2 3 4 7 8 10 12 13 15 16 18 19 21 26 28 29 30];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Test flowergarden sequences %
%     main_dir = '../../Data/evaluation_data/flowerGarden';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'flowerGarden');
%     testing_seq = [1 2 3 4];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Test evaluation sequences %
%     main_dir = '../../Data/evaluation_data';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'evaluation_data');
%     testing_seq = [13:17];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%% Test oisin's sequences %%
%     main_dir = '../../Data/evaluation_data/oisin/trunk';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin', 'trunk');
%     testing_seq = [1:3];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/oisin/plant';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin', 'plant');
%     testing_seq = [3];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/oisin/pebbles';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin', 'pebbles');
%     testing_seq = [1:5];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/oisin/angleChange';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin', 'angleChange');
%     testing_seq = [1:9];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
end


function [ override_settings ] = create_override_settings()
    override_settings = struct;
    uv_ftrs1_ss_info =               [ 10             0.8 ];   % this and the var below are there, because Temporal gradient and other features need different UV SS
    uv_ftrs2_ss_info =               [ 4              0.8 ];
    override_settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
    override_settings.ss_info_im2 =  uv_ftrs2_ss_info;                                       % image pyramid to be built for im2
    
    % create the structure of OF algos to use and Features to compute
%     override_settings.cell_flows = { BlackAnandanOF, ...
%                                      TVL1OF, ...
%                                      HornSchunckOF, ...
%                                      HuberL1OF, ...
%                                      ClassicNLOF, ...
%                                      LargeDisplacementOF };
    override_settings.cell_flows = { TVL1OF, ...
                                     HuberL1OF, ...
                                     ClassicNLOF, ...
                                     LargeDisplacementOF };
    override_settings.uv_ss_info =   [ max(uv_ftrs1_ss_info(1), uv_ftrs2_ss_info(1)) ...     % image pyramid to be built for flow
                                                 uv_ftrs2_ss_info(2) ];

    [c r] = meshgrid(-1:1, -1:1);
    nhood = cat(3, r(:), c(:));
    nhood_cs = nhood;
    nhood_cs(nhood_cs(:,:,1)==0 & nhood_cs(:,:,2)==0,:,:) = [];

    %%% All features %%%
    override_settings.cell_features = { EdgeDistFeature(override_settings.ss_info_im1), ...
                                        PbEdgeStrengthFeature(0.1, uv_ftrs2_ss_info), ...
                                        PbEdgeStrengthFeature(0.4, uv_ftrs2_ss_info), ...
                                        FlowConfidenceSingleFrameFeature(override_settings.cell_flows, [9 10 17 18 19 22 24 26 29 30 39 49 50], seq_conflicts, '../../Data/oisin+middlebury', 50, 60), ...
                                        FlowConfidenceSingleFrameFeature(override_settings.cell_flows, [9 10 17 18 19 22 24 26 29 30 39 49 50], seq_conflicts, '../../Data/oisin+middlebury', 1, 1) };
end