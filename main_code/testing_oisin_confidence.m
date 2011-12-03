function testing_oisin_confidence()
%TESTING_FINAL_EVAL Summary of this function goes here
%   Detailed explanation goes here

    main_dir = 'E:/Data/oisin+middlebury';
    out_dir = 'E:/Results/oisin+results_flowconfidence2';
    
    %              |  middlebury   |       Oisin (Maya)      | Sun |
    training_seq = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 17 18 19 15 16];
    training_seq = [9 10 17 18 19 22 24 26 29 30 39 49 50 51 88 89 106 107 124 125];
    testing_seq = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 22 24 26 29 30 39 49 50 51 88 89 106 107 124 125];
    seq_conflicts = {[2 3], [6 7 16], [11 12], [13 14], [18 19], [9 20 21 22 40:48 10 23 24 25], [26 27 28 29], [30:39], [49:50], [51:88], [89:106], [107:124], [125:128]};

    override_settings = struct;
    
    override_settings.MAX_MARKINGS_PER_LABEL = 14000;
    
    % if you want to build Photoconstancy feature for all algo.s 
    %   but only use one in training/testing
    override_settings.USE_ONLY_OF = '';      % HuberL1OF.OF_SHORT_TYPE;

    override_settings.RF_MAX_DEPTH = '10';
    override_settings.RF_MIN_SAMPLE_COUNT = '50';
    override_settings.RF_MAX_CATEGORIES = '30';
    override_settings.RF_NO_ACTIVE_VARS = '5';
    override_settings.RF_MAX_TREE_COUNT = '50';
    
    % create the structure of OF algos to use and Features to compute
    override_settings.cell_flows = { TVL1OF, ...
                                     HuberL1OF, ...
                                     ClassicNLOF, ...
                                     LargeDisplacementOF };
                                 
    uv_ftrs1_ss_info =               [ 10             0.8 ];   % this and the var below are there, because Temporal gradient and other features need different UV SS
    uv_ftrs2_ss_info =               [ 4              0.8 ];
    override_settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
    override_settings.ss_info_im2 =  uv_ftrs2_ss_info;                                       % image pyramid to be built for im2
    
    override_settings.uv_ss_info = [ max(uv_ftrs1_ss_info(1), uv_ftrs2_ss_info(1)) ...     % image pyramid to be built for flow
                                                 uv_ftrs2_ss_info(2) ];

    override_settings.cell_features = { GradientMagFeature(override_settings.ss_info_im1), ...
                                        EdgeDistFeature(override_settings.ss_info_im1), ...
                                        PbEdgeStrengthFeature(0.1, uv_ftrs2_ss_info), ...
                                        PbEdgeStrengthFeature(0.4, uv_ftrs2_ss_info), ...
                                        TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        PhotoConstancyFeature(override_settings.cell_flows) };

    % store the flow algorithms to be used and their ids
    flow_short_types = {};
    for algo_idx = 1:length(override_settings.cell_flows)
        flow_short_types{end+1} = override_settings.cell_flows{algo_idx}.OF_SHORT_TYPE;
    end
    
    % iterate over multiple EPE confidence threshold values
    for confidence_epe_th = [20 30 50]
        override_settings.label_obj = FlowEPEConfidenceLabel(confidence_epe_th);

        % get feature for each flow algo.
        for algo_idx = 1:length(flow_short_types)
            % we want to build Photoconstancy feature for all algo.s but only 
            %   use one at a time in training/testing
            override_settings.USE_ONLY_OF = flow_short_types{algo_idx};

            temp_out_dir = fullfile(out_dir, sprintf('FC_%0.2f-gm_ed_tg_pc-%s', confidence_epe_th, override_settings.USE_ONLY_OF));
            [ MAIN_CLASS_XML_PATH ] = trainTestDelete('trainTestDeleteMain', testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
        end
    end
    
end
