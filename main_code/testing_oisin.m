function testing_oisin()
%TESTING_FINAL_EVAL Summary of this function goes here
%   Detailed explanation goes here

    main_dir = 'E:/Data/oisin+middlebury';
    out_dir = 'E:/Results/oisin+results';
    
    %              |  middlebury   |       Oisin (Maya)      | Sun |
    training_seq = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 17 18 19 15 16];
    testing_seq = [17 18 19 15 16];
    seq_conflicts = {[2 3], [6 7 16], [11 12], [13 14], [18 19], [9 20 21 22 40:48 10 23 24 25], [26 27 28 29], [30:39], [49:50], [51:88], [89:106], [107:124], [125:128]};

    
    training_seq = [9 10 17 18 19 22 24 26 29 30 39 49 50 51 88 89 106 107 124 125];
    testing_seq = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 22 24 26 29 30 39 49 50 51 88 89 106 107 124 125];
    
    % 
    % training_seq = [];
    % testing_seq = [1 2 13 14];

    override_settings = struct;
    uv_ftrs1_ss_info =               [ 10             0.8 ];   % this and the var below are there, because Temporal gradient and other features need different UV SS
    uv_ftrs2_ss_info =               [ 4              0.8 ];
    override_settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
    override_settings.ss_info_im2 =  uv_ftrs2_ss_info;                                       % image pyramid to be built for im2
    
    override_settings.uv_ss_info = [ max(uv_ftrs1_ss_info(1), uv_ftrs2_ss_info(1)) ...     % image pyramid to be built for flow
                                                 uv_ftrs2_ss_info(2) ];
    
    override_settings.MAX_MARKINGS_PER_LABEL = 17000;
    
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
                                 
    override_settings.label_obj = AlgoSuitabilityLabel( override_settings.cell_flows, 0 );
    
    override_settings.cell_features = { GradientMagFeature(override_settings.ss_info_im1), ...
                                        EdgeDistFeature(override_settings.ss_info_im1), ...
                                        PbEdgeStrengthFeature(0.1, uv_ftrs2_ss_info), ...
                                        PbEdgeStrengthFeature(0.4, uv_ftrs2_ss_info), ...
                                        TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                        PhotoConstancyFeature(override_settings.cell_flows)};
    
    temp_out_dir = fullfile(out_dir, 'temp');
    
    [ MAIN_CLASS_XML_PATH ] = trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);
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