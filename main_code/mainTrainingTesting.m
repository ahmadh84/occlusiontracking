function [ unique_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, out_dir, override_settings, produce_rf_xml_out )
%MAINTRAININGTESTING Summary of this function goes here
%   Detailed explanation goes here

    % if not bothered about an RF xml classifier, don't create it
    if ~exist('produce_rf_xml_out', 'var')
        produce_rf_xml_out = 0;
    end
    
    COMPUTE_REFRESH = 0;
    RANDOM_FOREST_RUN = 'randomForest\src\predictDescriptor\Release\predictDescriptor.exe ';
    
    
    uv_ftrs1_ss_info =            [ 10             0.8 ];   % this and the var below are there, because Temporal gradient and other features need different UV SS
    uv_ftrs2_ss_info =            [ 4              0.8 ];
    
    assert( uv_ftrs1_ss_info(2) == uv_ftrs2_ss_info(2), 'Use the same scaling factor for UV');
    
    % get the image pyramid, which is needed for some features
                            % no_scales     % scale
    settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
    settings.ss_info_im2 =  [ 1              1 ];                                   % image pyramid to be built for im2
    settings.uv_ss_info =   [ max(uv_ftrs1_ss_info(1), uv_ftrs2_ss_info(1)) ...     % image pyramid to be built for flow
                                             uv_ftrs2_ss_info(2) ];
    
    % build parameters for OFAngleVarianceFeature, OFLengthVarianceFeature,
    % OFCollidingSpeedFeature
    [c r] = meshgrid(-2:2, -2:2);
    nhood = cat(3, r(:), c(:));
    nhood_cs = nhood;
    nhood_cs(nhood_cs(:,:,1)==0 & nhood_cs(:,:,2)==0,:,:) = [];
    
    % number of examples used in training for each class
    settings.MAX_MARKINGS_PER_LABEL = 7000;
    
    % if you want to build Photoconstancy feature for all classes but only
    % use one in training/esting
    settings.USE_ONLY_OF = '';  % HuberL1OF.OF_SHORT_TYPE;
    
    % OpenCV Random Forest parameters
    settings.RF_MAX_DEPTH = '35';           % maximum levels in a tree
    settings.RF_MIN_SAMPLE_COUNT = '20';    % don't split a node if less
    settings.RF_MAX_CATEGORIES = '25';      % limits the no. of categorical values before the decision tree preclusters those categories so that it will have to test no more than 2^max_categories–2 possible value subsets. Low values reduces computation at the cost of accuracy
    settings.RF_NO_ACTIVE_VARS = '11';      % size of randomly selected subset of features to be tested at any given node (typically the sqrt of total no. of features)
    settings.RF_MAX_TREE_COUNT = '105';
    settings.RF_GET_VAR_IMP = '1';          % calculate the variable importance of each feature during training (at cost of additional computation time)
    
    % create the structure of OF algos to use and Features to compute
    settings.cell_flows = { BlackAnandanOF, ...
                            TVL1OF, ...
                            HornSchunckOF, ...
                            HuberL1OF, ...
                            ClassicNLOF, ...
                            LargeDisplacementOF };
    settings.cell_features = { GradientMagFeature(settings.ss_info_im1), ....
                               EdgeDistFeature(settings.ss_info_im1), ...
                               TemporalGradFeature(settings.cell_flows, uv_ftrs1_ss_info), ...
                               OFAngleVarianceFeature(settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                               OFLengthVarianceFeature(settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                               OFCollidingSpeedFeature(settings.cell_flows, nhood_cs, uv_ftrs2_ss_info), ...
                               PhotoConstancyFeature(settings.cell_flows) };
    
    % the labelling class used for the classifier
    settings.label_obj = OcclusionLabel;
    
    if exist('override_settings', 'var')
        % override settings given by the user
        override_fields = fieldnames(override_settings);
        for idx = 1:length(override_fields)
            if isfield(settings, override_fields{idx})
                settings.(override_fields{idx}) = override_settings.(override_fields{idx});
            else
                error('mainTrainingTesting:override_fields', 'Field %s cannot be overriden since it does not exist', override_fields{idx});
            end
        end
    end
    
    % create the main object, which creates the test and training data
    traintest_data = ComputeTrainTestData( main_dir, out_dir, settings, 0, COMPUTE_REFRESH );
    
    
    % do K-fold cross-validation for each of scenes (using all the remaining sequences)
    for scenes_idx = 1:length(testing_seq)
        scene_id = testing_seq(scenes_idx);
        
        if ~isempty(training_seq)
            % if need to train and test both
            
            % bootstrap
            training_ids = setdiff(training_seq, scene_id);

            % produce the training and testing data
            [ TRAIN_PATH TEST_PATH unique_id ] = traintest_data.produceTrainingTestingData(scene_id, training_ids);
            
            PREDICTION_DATA_PATH = getPredictionDataFilename(out_dir, scene_id, unique_id, settings.USE_ONLY_OF);
            
            if produce_rf_xml_out == 0
                % if you dont want to produce the xml classifier from the% RF
                
                randomforest_cmd = [RANDOM_FOREST_RUN ' ' settings.RF_MAX_TREE_COUNT ' ' ...
                    settings.RF_NO_ACTIVE_VARS ' ' settings.RF_MAX_DEPTH ' ' settings.RF_MIN_SAMPLE_COUNT ' ' ...
                    settings.RF_MAX_CATEGORIES ' ' settings.RF_GET_VAR_IMP ' "' TRAIN_PATH '" "' ...
                    TEST_PATH '" "' PREDICTION_DATA_PATH '" -b'];
            else
                % if you want to produce the xml classifier from the RF
                CLASS_XML_PATH = getXMLDataFilename(out_dir, unique_id, settings.USE_ONLY_OF);
                
                randomforest_cmd = [RANDOM_FOREST_RUN ' ' settings.RF_MAX_TREE_COUNT ' ' ...
                    settings.RF_NO_ACTIVE_VARS ' ' settings.RF_MAX_DEPTH ' ' settings.RF_MIN_SAMPLE_COUNT ' ' ...
                    settings.RF_MAX_CATEGORIES ' ' settings.RF_GET_VAR_IMP ' -s "' CLASS_XML_PATH '" "' ...
                    TRAIN_PATH '" "' TEST_PATH '" "' PREDICTION_DATA_PATH '" -b'];
            end
        else
            % if need to test only
            
            % produce the training and testing data
            [ TEST_PATH unique_id ] = traintest_data.produceTestingData( scene_id );
            
            PREDICTION_DATA_PATH = getPredictionDataFilename(out_dir, scene_id, unique_id, settings.USE_ONLY_OF);
            CLASS_XML_PATH = getXMLDataFilename(out_dir, unique_id, settings.USE_ONLY_OF);

            randomforest_cmd = [RANDOM_FOREST_RUN ' -l "' CLASS_XML_PATH '" "' ...
                TEST_PATH '" "' PREDICTION_DATA_PATH '" -b'];
        end
        
        fprintf(1, '\nRunning Random Forest classifier (get some coffee - this will take time!)\n');
        tic;
        [ ret_val out ] = system(randomforest_cmd);
        fprintf(1, 'Random Forest classifier took %f secs\n', toc);
        
        if ret_val == 0
            fprintf(1, 'Done - Success!\n');

            output_handler = ClassifierOutputHandler( out_dir, scene_id, PREDICTION_DATA_PATH, traintest_data, out, settings );
            output_handler.printPosteriorImage();
            output_handler.printROCCurve();
            output_handler.printRFFeatureImp();
            output_handler.saveObject();
        else
            fprintf(2, 'Classifier Failed!\n');
            fprintf(1, out);
        end
    end
end


function filename = getXMLDataFilename(out_dir, comp_feat_vec_id, only_of)
    if isnumeric(comp_feat_vec_id)
        comp_feat_vec_id = num2str(comp_feat_vec_id);
    end

    if exist('only_of', 'var') && ~isempty(only_of)
        filename = fullfile(out_dir, [comp_feat_vec_id '_' only_of '_class.xml']);
    else
        filename = fullfile(out_dir, [comp_feat_vec_id '_class.xml']);
    end
end


function filename = getPredictionDataFilename(out_dir, scene_id, comp_feat_vec_id, only_of)
    if isnumeric(scene_id)
        scene_id = num2str(scene_id);
    end
    if isnumeric(comp_feat_vec_id)
        comp_feat_vec_id = num2str(comp_feat_vec_id);
    end

    if exist('only_of', 'var') && ~isempty(only_of)
        filename = fullfile(out_dir, [scene_id '_' comp_feat_vec_id '_' only_of '_prediction.data']);
    else
        filename = fullfile(out_dir, [scene_id '_' comp_feat_vec_id '_prediction.data']);
    end
end