function testing_script
%TESTING_SCRIPT Summary of this function goes here
%   Detailed explanation goes here
    
    [ override_settings ] = create_override_settings();
    out_dir = 'D:/ahumayun/Results/features_comparison_tests4';
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test middlebury sequences %
    main_dir = '../../Data/oisin+middlebury';
    temp_out_dir = fullfile(out_dir, 'ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp-sans-BA-HS');

    training_seq = [4 5 9 10 17 18 19 22 24 26 29 30 39 49 50];
    testing_seq = [1 4 5 9 10 11 14 17 18 19 26 29 30 39 40:45];
    seq_conflicts = {[2 3], [6 7 16], [11 12], [13 14], [18 19], [9 20 21 22 40:48 10 23 24 25], [26 27 28 29], [30:39], [49:52]};
    
    trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test middlebury sequences %
    
end


function trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings)

    if isempty(training_seq)
        [ unique_id ] = mainTrainingTesting( testing_seq, [], seq_conflicts, main_dir, temp_out_dir, override_settings );
    else
        [ no_conflict_test_seq ] = trainingSequencesUtils( 'getNoConflictTestingSequences', training_seq, testing_seq, seq_conflicts );
        
        % if there is no sequence to create a classifier from
        if isempty(no_conflict_test_seq)
            [ unique_id ] = mainTrainingTesting( testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings );
        else
            % use one of the testing sequences to create an XML classifier
            [ unique_id ] = mainTrainingTesting( no_conflict_test_seq(1), training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings, 1 );
            
            % use the remaining sequences to test using the classifier
            [ unique_id ] = mainTrainingTesting( no_conflict_test_seq(2:end), [], seq_conflicts, main_dir, temp_out_dir, override_settings, 1 );
            
            % do k-fold cross validation for testing on the training sequences
            [ unique_id ] = mainTrainingTesting( setdiff(testing_seq, no_conflict_test_seq), training_seq, main_dir, temp_out_dir, override_settings );
        end
    end

    deleteTrainTestData(temp_out_dir);

    deleteFVData(main_dir, union(training_seq, testing_seq), unique_id);
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
                                        PhotoConstancyFeature(override_settings.cell_flows, uv_ftrs2_ss_info), ...
                                        SparseSetTextureFeature2(override_settings.cell_flows, nhood), ...
                                        SparseSetTextureFeature(override_settings.cell_flows), ...
                                        TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info, {'MAX'}), ...
                                        ReverseFlowConstancyFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        ReverseFlowAngleDiffFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        FlowConfidenceFeature(override_settings.cell_flows, [4 5 9 10 11 12 13 14 17 18 19 28], '../../Data/oisin+middlebury', 50, 60), ...
                                        FlowConfidenceFeature(override_settings.cell_flows, [4 5 9 10 11 12 13 14 17 18 19 28], '../../Data/oisin+middlebury', 1, 1), ...
                                        FlowAngleVarianceFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        FlowLengthVarianceFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        SPFlowBoundaryFeature(override_settings.cell_flows) };
end