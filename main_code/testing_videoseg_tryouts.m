function [ output_args ] = testing_videoseg_tryouts( input_args )
%TESTING5 Summary of this function goes here
%   Detailed explanation goes here
    
    seq_conflicts = {[2 3], [6 7 16], [11 12], [13 14], [18 19], [9 20 21 22 40:48 10 23 24 25], [26 27 28 29], [30:39], [49:50], [51:88], [89:106], [107:124], [125:128]};
    out_dir = '../../Results/VideoSegTest';

    training_seq = [9 10 17 18 19 22 24 26 29 30 39 49 50];
    testing_seq = [1:6 9:14 17:19 26:29 30 39 40:48 49 50];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test middlebury sequences %
    for flow_idx = [2 1 3 4]
        % 4  - PhotoConstancyFeature
        % 7  - TemporalGradFeature
        % 8  - OFAngleVarianceFeature
        % 9  - OFLengthVarianceFeature
        % 10 - OFCollidingSpeedFeature
        % 11 - ReverseFlowConstancyFeature
        % 12 - ReverseFlowAngleDiffFeature
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%% All Sub-features above %%%%%%
        [ override_settings ] = create_override_settings( seq_conflicts, flow_idx, [4 7 8 9 10 11 12] );

        main_dir = '../../../Data/Images/UCL/oisin+middlebury';
        temp_out_dir = fullfile(out_dir, [override_settings.cell_flows{1}.OF_SHORT_TYPE '-']);
        for ftr_idx = 1:length(override_settings.cell_features)
            temp_out_dir = [temp_out_dir '_' lower(override_settings.cell_features{ftr_idx}.FEATURE_SHORT_TYPE)];
        end
        temp_out_dir = [temp_out_dir '-CGT'];
        
        trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%% Just PC,TG,RC,RA %%%%%%
        [ override_settings ] = create_override_settings( seq_conflicts, flow_idx, [4 7 11 12] );

        main_dir = '../../../Data/Images/UCL/oisin+middlebury';
        temp_out_dir = fullfile(out_dir, [override_settings.cell_flows{1}.OF_SHORT_TYPE '-']);
        for ftr_idx = 1:length(override_settings.cell_features)
            temp_out_dir = [temp_out_dir '_' lower(override_settings.cell_features{ftr_idx}.FEATURE_SHORT_TYPE)];
        end
        temp_out_dir = [temp_out_dir '-CGT'];

        trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%% Just PC,RC,RA %%%%%%
        [ override_settings ] = create_override_settings( seq_conflicts, flow_idx, [4 11 12] );

        main_dir = '../../../Data/Images/UCL/oisin+middlebury';
        temp_out_dir = fullfile(out_dir, [override_settings.cell_flows{1}.OF_SHORT_TYPE '-']);
        for ftr_idx = 1:length(override_settings.cell_features)
            temp_out_dir = [temp_out_dir '_' lower(override_settings.cell_features{ftr_idx}.FEATURE_SHORT_TYPE)];
        end
        temp_out_dir = [temp_out_dir '-CGT'];
        
        trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%% Just PC,RC %%%%%%
        [ override_settings ] = create_override_settings( seq_conflicts, flow_idx, [4 11] );

        main_dir = '../../../Data/Images/UCL/oisin+middlebury';
        temp_out_dir = fullfile(out_dir, [override_settings.cell_flows{1}.OF_SHORT_TYPE '-']);
        for ftr_idx = 1:length(override_settings.cell_features)
            temp_out_dir = [temp_out_dir '_' lower(override_settings.cell_features{ftr_idx}.FEATURE_SHORT_TYPE)];
        end
        temp_out_dir = [temp_out_dir '-CGT'];

        trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%% All Features %%%%%%
        [ override_settings ] = create_override_settings( seq_conflicts, flow_idx, [] );

        main_dir = '../../../Data/Images/UCL/oisin+middlebury';
        temp_out_dir = fullfile(out_dir, [override_settings.cell_flows{1}.OF_SHORT_TYPE '--ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_sp-CGT']);

        trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
    end
end


function [ MAIN_CLASS_XML_PATH ] = trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings)
    
    MAIN_CLASS_XML_PATH = '';
    
    if isempty(training_seq)
        [ unique_id ] = mainTrainingTesting( testing_seq, [], seq_conflicts, main_dir, temp_out_dir, override_settings );
    elseif ischar(training_seq)
        [ unique_id ] = mainTrainingTesting( testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings );
    else
        % make groups of sequences which need the same training set
        [ test_seq_groups full_training_seq ] = trainingSequencesUtils( 'groupTestingSeqs', training_seq, testing_seq, seq_conflicts );

        % iterate over each group
        for idx = 1:size(test_seq_groups,1)
            if ~full_training_seq(idx)
                training_ids = trainingSequencesUtils('getTrainingSequences', training_seq, test_seq_groups{idx}(1), seq_conflicts);
                xml_filename_append = sprintf('_%d', training_ids);
            else
                xml_filename_append = '';
            end
            
            if length(test_seq_groups{idx}) > 1
                % use one of the testing sequences to create an XML classifier
                [ unique_id CLASS_XML_PATH ] = mainTrainingTesting( test_seq_groups{idx}(1), training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings, 1, xml_filename_append );
            
                % make the rest use the trained classifier
                [ unique_id ] = mainTrainingTesting( test_seq_groups{idx}(2:end), CLASS_XML_PATH, seq_conflicts, main_dir, temp_out_dir, override_settings );
            else
                % if only one sequence, only produce XML in the case that
                % it has the full training set
                [ unique_id CLASS_XML_PATH ] = mainTrainingTesting( test_seq_groups{idx}, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings, isempty(xml_filename_append) );
            end
            
            % delete the classifier only in the case that it is not of the
            % full training set
            if ~full_training_seq(idx) && ~isempty(CLASS_XML_PATH)
                delete(CLASS_XML_PATH);
            else
                MAIN_CLASS_XML_PATH = CLASS_XML_PATH;
            end

            deleteTrainTestData(temp_out_dir);
            close all;
        end
    end

    deleteTrainTestData(temp_out_dir);

    % delete all the FV (feature vector) mat files created
    if ischar(training_seq)
        deleteFVData(main_dir, testing_seq, unique_id);
    else
        deleteFVData(main_dir, union(training_seq, testing_seq), unique_id);
    end
    close all;
end


function deleteTrainTestData( d )
    delete(fullfile(d, '*_Test.data'));
    delete(fullfile(d, '*_Train.data'));
end


function deleteFVData( d, sequences, unique_id )
    for scene_id = sequences
        fv_filename = sprintf('%d_%d_FV.mat', scene_id, unique_id);
        delete(fullfile(d, num2str(scene_id), fv_filename));
    end
end


function [ override_settings ] = create_override_settings( seq_conflicts, select_flow_algos, select_features )
    override_settings = struct;
    uv_ftrs1_ss_info =               [ 10             0.8 ];   % this and the var below are there, because Temporal gradient and other features need different UV SS
    uv_ftrs2_ss_info =               [ 4              0.8 ];
    override_settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
    override_settings.ss_info_im2 =  uv_ftrs2_ss_info;                                       % image pyramid to be built for im2
    
    % create occlusion label but ignore occlusions due to change in
    % field of view as not occlusions
    override_settings.label_obj = OcclusionLabel(0, 1);
    
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
    if ~isempty(select_flow_algos)
        override_settings.cell_flows = override_settings.cell_flows(select_flow_algos);
    end
    
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