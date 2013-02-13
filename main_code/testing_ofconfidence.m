function testing_ofconfidence()
% train/test with the optical flow confidence classifier
%   Go to for details -> https://docs.google.com/document/d/106nk_4YLzEFLnXcdTwlPm1Z1QuMwdtp4PX-7iQT0msE/edit

    % the path where the download_dataset script downloaded the dataset to
    training_dir = '/home/ahumayun/Desktop/AlgoSuit+Middlebury_Dataset';
    
    % the sequences which are in conflict (for cross-validation) in the
    % training set
    seq_conflicts = {[2 3], [6 7 16], [11 12], [13 14], [18 19], [9 20 21 22 40:48 10 23 24 25], [26 27 28 29], [30:39], [49:50], [51:88], [89:106], [107:124], [125:128]};
    [ override_settings ] = create_override_settings( seq_conflicts, training_dir );
    
    % path where the output files are written to
    out_dir = '/home/ahumayun/Desktop/ofconfidence_result';
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test middlebury + cross-validate training sequences %
    
    % the directory where the sequences that need to be tested are located
    main_dir = '/home/ahumayun/Desktop/AlgoSuit+Middlebury_Dataset';

    % training and testing sequence numbers
    training_seq = [9 10 17 18 19 22 24 26 29 30 39 49 50 51 88 89 106 107 124 125];
    %             |  middlebury   |                    Oisin et al. (PAMI 2013)                        | Sun |
    testing_seq = [1 2 3 4 5 6 7 8 9 10 13 14 17 18 19 22 24 26 29 30 39 49 50 51 88 89 106 107 124 125 15 16];
    

    % store the flow algorithms to be used and their ids
    flow_short_types = {};
    for algo_idx = 1:length(override_settings.cell_flows)
        flow_short_types{end+1} = override_settings.cell_flows{algo_idx}.OF_SHORT_TYPE;
    end
    
    % iterate over multiple EPE confidence threshold values
    for confidence_epe_th = [0.1, 0.25, 0.5, 2, 10]
        override_settings.label_obj = FlowEPEConfidenceLabel(confidence_epe_th);

        % get feature for each flow algo.
        for algo_idx = 1:length(flow_short_types)
            % we want to build Photoconstancy feature for all algo.s but 
            %  only use one the relevant one in training/testing
            override_settings.USE_ONLY_OF = flow_short_types{algo_idx};

            temp_out_dir = fullfile(out_dir, sprintf('FC_%0.2f-gm_ed_pb_pb_tg_pc-%s', confidence_epe_th, override_settings.USE_ONLY_OF));
            [ MAIN_CLASS_XML_PATH ] = trainTestDelete('trainTestDeleteMain', testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
        end
    end
    
    % flow algorithm to regress on
    flow_short_type = 'LD';     % 'TV' = TVL1OF
                                % 'FL' = HuberL1OF
                                % 'CN' = ClassicNLOF
                                % 'LD' = LargeDisplacementOF
    
    % EPE threshold to regress on
    confidence_epe_th = 2;
    
    % the xml regressor path
    temp_out_dir = fullfile(out_dir, sprintf('FC_%0.2f-gm_ed_pb_pb_tg_pc-%s', confidence_epe_th, flow_short_type));
    f = dir(fullfile(temp_out_dir, '*.xml'));
    
    % check if the classifier exist before proceeding
%     assert(length(f) == 1, 'Main classifier XML doesn''t exist');
    
    MAIN_CLASS_XML_PATH = fullfile(temp_out_dir, f(1).name);
    
    seq_conflicts = {};
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%% Test sequences %%%%%%%
%     main_dir = '/home/ahumayun/Desktop/Testing_Dataset/';
%     eval_temp_out_dir = fullfile(temp_out_dir, 'testing_dataset');
%     testing_seq = [11 30];
%     trainTestDelete('trainTestDeleteMain', testing_seq, MAIN_CLASS_XML_PATH, seq_conflicts, main_dir, eval_temp_out_dir, override_settings);
end


function [ override_settings ] = create_override_settings( seq_conflicts, taining_dir )
    override_settings = struct;
    uv_ftrs1_ss_info =               [ 10             0.8 ];   % this and the var below are there, because Temporal gradient and other features need different UV SS
    uv_ftrs2_ss_info =               [ 4              0.8 ];
    override_settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
    override_settings.ss_info_im2 =  uv_ftrs2_ss_info;                                       % image pyramid to be built for im2
    
    override_settings.uv_ss_info = [ max(uv_ftrs1_ss_info(1), uv_ftrs2_ss_info(1)) ...     % image pyramid to be built for flow
                                     uv_ftrs2_ss_info(2) ];
    
    % create the structure of OF algos to use and Features to compute
    override_settings.cell_flows = { TVL1OF, ...
                                     HuberL1OF, ...
                                     ClassicNLOF, ...
                                     LargeDisplacementOF };

    override_settings.MAX_MARKINGS_PER_LABEL = 14000;
    
    override_settings.RF_MAX_DEPTH = '10';
    override_settings.RF_MIN_SAMPLE_COUNT = '50';
    override_settings.RF_MAX_CATEGORIES = '30';
    override_settings.RF_NO_ACTIVE_VARS = '5';
    override_settings.RF_MAX_TREE_COUNT = '50';
    
    %%% All features %%%
    override_settings.cell_features = { GradientMagFeature(override_settings.ss_info_im1), ...
                                        EdgeDistFeature(override_settings.ss_info_im1), ...
                                        PbEdgeStrengthFeature(0.1, uv_ftrs2_ss_info), ...
                                        PbEdgeStrengthFeature(0.4, uv_ftrs2_ss_info), ...
                                        TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        PhotoConstancyFeature(override_settings.cell_flows) };
end
