function testing_script_lean
% train/test with the lean occlusion classifier
%   Go to for details -> https://docs.google.com/document/d/1AsvYZKiB-8D9F7cmTvqfD6iGzqO521VmvkqcQLByLVI/edit

    % the path where the download_dataset script downloaded the dataset to
    training_dir = '/home/ahumayun/Desktop/AlgoSuit+Middlebury_Dataset';
    
    % the sequences which are in conflict (for cross-validation) in the
    % training set
    seq_conflicts = {[2 3], [6 7 16], [11 12], [13 14], [18 19], [9 20 21 22 40:48 10 23 24 25], [26 27 28 29], [30:39], [49:50]};
    [ override_settings ] = create_override_settings();
    
    % path where the output files are written to
    out_dir = '/home/ahumayun/Desktop/occlusions_result';
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test middlebury + cross-validate training sequences %
    
    % the directory where the sequences that need to be tested are located
    main_dir = '/home/ahumayun/Desktop/AlgoSuit+Middlebury_Dataset';
    temp_out_dir = fullfile(out_dir, 'LEAN1-ed_pc_tg_av_lv_cs-max_rc_ra_fa_fn');

    % training and testing sequence numbers
    training_seq = [9 10 17 18 19 22 24 27 29 30 39 49 50];
    testing_seq = [1:6 9 10 17:25 27 29:50];
    
    % train/test the classifier
    [ MAIN_CLASS_XML_PATH ] = trainTestDelete('trainTestDeleteMain', testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
    
    % check if the classifier exist before proceedings
    assert(exist(MAIN_CLASS_XML_PATH, 'file')==2, 'Main classifier XML doesn''t exist');
    
    seq_conflicts = {};
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Test stein sequences %%%%
%     main_dir = '../../Data/evaluation_data/stein';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'stein');
%     testing_seq = [1 2 3 4 7 8 10 12 13 15 16 18 19 21 26 28 29 30];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test flowergarden sequences %
%     main_dir = '../../Data/evaluation_data/flowerGarden';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'flowerGarden');
%     testing_seq = [1 2 3 4];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Test evaluation sequences %
%     main_dir = '../../Data/evaluation_data';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'evaluation_data');
%     testing_seq = [13:18];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     %%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Test oisin's sequences %
%     main_dir = '../../Data/evaluation_data/oisin/trunk';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin', 'trunk');
%     testing_seq = [1:3];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/oisin/plant';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin', 'plant');
%     testing_seq = [1:3];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/oisin/pebbles';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin', 'pebbles');
%     testing_seq = [1:5];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/oisin/pebbles_gap3';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin', 'pebbles_gap3');
%     testing_seq = [1:3];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/oisin/angleChange';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin', 'angleChange');
%     testing_seq = [1:9];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
    
%     main_dir = '../../Data/evaluation_data/gabriel/Sigal_Seq02';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'gabriel', 'Sigal_Seq02');
%     testing_seq = [1:2];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/gabriel/Sigal_Seq07';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'gabriel', 'Sigal_Seq07');
%     testing_seq = [1];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/gabriel/Sigal_Seq09';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'gabriel', 'Sigal_Seq09');
%     testing_seq = [1:10];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/gabriel/Sigal_Seq13';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'gabriel', 'Sigal_Seq13');
%     testing_seq = [1:2];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/gabriel/Sigal_Seq15';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'gabriel', 'Sigal_Seq15');
%     testing_seq = [1:3];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/gabriel/LobatonPersonWalkingECCV2010_2';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'gabriel', 'LobatonPersonWalkingECCV2010_2');
%     testing_seq = [5:10];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
% 
%     main_dir = '../../Data/evaluation_data/stein-supplementary/7';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'stein-supplementary', '7');
%     testing_seq = [2 4];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/stein-supplementary/10';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'stein-supplementary', '10');
%     testing_seq = [2 4];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/stein-supplementary/18';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'stein-supplementary', '18');
%     testing_seq = [2 4];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/stein-supplementary/26';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'stein-supplementary', '26');
%     testing_seq = [2 4];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/stein-supplementary/28';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'stein-supplementary', '28');
%     testing_seq = [2 4];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/oisin-supplementary/plant';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin-supplementary', 'plant');
%     testing_seq = [1:3];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
%     
%     main_dir = '../../Data/evaluation_data/oisin-supplementary/trunk';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'oisin-supplementary', 'trunk');
%     testing_seq = [1:3];
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
                                     HuberL1OF };
    override_settings.uv_ss_info =   [ max(uv_ftrs1_ss_info(1), uv_ftrs2_ss_info(1)) ...     % image pyramid to be built for flow
                                                 uv_ftrs2_ss_info(2) ];

    [c r] = meshgrid(-1:1, -1:1);
    nhood = cat(3, r(:), c(:));
    nhood_cs = nhood;
    nhood_cs(nhood_cs(:,:,1)==0 & nhood_cs(:,:,2)==0,:,:) = [];

    %%% All features %%%
    override_settings.cell_features = { EdgeDistFeature(override_settings.ss_info_im1), ...
                                        PhotoConstancyFeature(override_settings.cell_flows, uv_ftrs2_ss_info), ...
                                        TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info, {'MAX'}), ...
                                        ReverseFlowConstancyFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        ReverseFlowAngleDiffFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        FlowAngleVarianceFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        FlowLengthVarianceFeature(override_settings.cell_flows, uv_ftrs1_ss_info) };
end
