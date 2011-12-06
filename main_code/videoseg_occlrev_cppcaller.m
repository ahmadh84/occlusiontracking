function videoseg_occlrev_cppcaller(main_dir, temp_out_dir, testing_seq, CLASSIFIER_PATH)
%TESTING5 Summary of this function goes here
%   Detailed explanation goes here
    
    %CLASSIFIER_PATH = '/home/ahumayun/algosuitability/Results/VideoSegTest/RCGT_VS/';

    seq_conflicts = {[2 3], [6 7 16], [11 12], [13 14], [18 19], [9 20 21 22 40:48 10 23 24 25], [26 27 28 29], [30:39], [49:50], [51:88], [89:106], [107:124], [125:128]};
    
    %main_dir = '/home/ahumayun/videoseg/formatlab/';
    %temp_out_dir = '/home/ahumayun/videoseg/formatlab/result/';
    %testing_seq = [1];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test middlebury sequences %

    % 4  - PhotoConstancyFeature
    % 7  - TemporalGradFeature
    % 8  - OFAngleVarianceFeature
    % 9  - OFLengthVarianceFeature
    % 10 - OFCollidingSpeedFeature
    % 11 - ReverseFlowConstancyFeature
    % 12 - ReverseFlowAngleDiffFeature
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% All Sub-features above %%%%%%
    %MAIN_CLASS_XML_PATH = fullfile(CLASSIFIER_PATH, 'VS-_pc_tg_av_lv_cs_rc_ra-RCGT/269845_class.xml');
    %[ override_settings ] = create_override_settings( seq_conflicts, [4 7 8 9 10 11 12] );
    %trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, temp_out_dir, override_settings, 0);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Just PC,TG,RC,RA %%%%%%
    MAIN_CLASS_XML_PATH = fullfile(CLASSIFIER_PATH, 'VS-_pc_tg_rc_ra-RCGT/144523_class.xml');
    [ override_settings ] = create_override_settings( seq_conflicts, [4 7 11 12] );
    trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, temp_out_dir, override_settings, 0);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Just PC,RC,RA %%%%%%
    %MAIN_CLASS_XML_PATH = fullfile(CLASSIFIER_PATH, 'VS-_pc_rc_ra-RCGT/107274_class.xml');
    %[ override_settings ] = create_override_settings( seq_conflicts, [4 11 12] );
    %trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, temp_out_dir, override_settings, 0);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Just PC,RC %%%%%%
    %MAIN_CLASS_XML_PATH = fullfile(CLASSIFIER_PATH, 'VS-_pc_rc-RCGT/72625_class.xml');
    %[ override_settings ] = create_override_settings( seq_conflicts, [4 11] );
    %trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, temp_out_dir, override_settings, 0);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% All Features %%%%%%
    %MAIN_CLASS_XML_PATH = fullfile(CLASSIFIER_PATH, VS--ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_sp-RCGT/905689_class.xml');
    %[ override_settings ] = create_override_settings( seq_conflicts, [] );
    %trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, temp_out_dir, override_settings, 0);
    
    % delete the CalcFlows file
    calcflows_filepath = fullfile(main_dir, sprintf('%d', testing_seq), sprintf('%d_836_nogt.mat',testing_seq));
    delete(calcflows_filepath);
end


function [ override_settings ] = create_override_settings( seq_conflicts, select_features )
    override_settings = struct;
    uv_ftrs1_ss_info =               [ 10             0.8 ];   % this and the var below are there, because Temporal gradient and other features need different UV SS
    uv_ftrs2_ss_info =               [ 4              0.8 ];
    override_settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
    override_settings.ss_info_im2 =  uv_ftrs2_ss_info;                                       % image pyramid to be built for im2
    
    % create occlusion label but ignore occlusions due to change in
    % field of view as not occlusions
    override_settings.label_obj = OcclusionLabel(1, 0);
    
    % create the structure of OF algos to use and Features to compute
%     override_settings.cell_flows = { BlackAnandanOF, ...
%                                      TVL1OF, ...
%                                      HornSchunckOF, ...
%                                      HuberL1OF, ...
%                                      ClassicNLOF, ...
%                                      LargeDisplacementOF };
    override_settings.cell_flows = { HuberL1VSOF };
    
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
                                        PhotoConstancyFeature(override_settings.cell_flows, uv_ftrs2_ss_info), ...
                                        SparseSetTextureFeature2(override_settings.cell_flows, nhood), ...
                                        SparseSetTextureFeature(override_settings.cell_flows), ...
                                        TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info, {'MAX'}), ...
                                        ReverseFlowConstancyFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        ReverseFlowAngleDiffFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        FlowConfidenceFeature(override_settings.cell_flows, [9 10 17 18 19 22 24 26 29 30 39 49 50], seq_conflicts, '../../../Data/Images/UCL/oisin+middlebury', 50, 60), ...
                                        FlowConfidenceFeature(override_settings.cell_flows, [9 10 17 18 19 22 24 26 29 30 39 49 50], seq_conflicts, '../../../Data/Images/UCL/oisin+middlebury', 1, 1), ...%FlowAngleVarianceFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...                                        %FlowLengthVarianceFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        SPFlowBoundaryFeature(override_settings.cell_flows) };
    if ~isempty(select_features)
        override_settings.cell_features = override_settings.cell_features(select_features);
    end
end