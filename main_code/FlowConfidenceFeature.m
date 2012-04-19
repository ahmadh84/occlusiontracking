classdef FlowConfidenceFeature < AbstractFeature
    %FLOWCONFIDENCEFEATURE this feature runs a a random forest classifier
    %   to find the confidence that a certain pixel is under a certain
    %   end-point-error and angular-error (using FlowEPEConfidenceLabel and 
    %   FlowAEConfidenceLabel). The features used for the classifier are
    %   GradientMagFeature(GM), EdgeDistFeature (ED), TemporalGradFeature
    %   (TG), PhotoConstancyFeature (PC), as specified in prepareSettings.
    %   Classifier are created and run for all flow algorithms specified in
    %   the constructor. Note that if the testing sequence is not part
    %   of the training set, an XML classifier is saved in the training
    %   sequences root directory.
    %
    %   The features are first ordered by algorithms and the first feature
    %   is End Point Error (EPE) and the second feature is Angular Error 
    %   (AE)
    
    
    properties
        training_seqs = [];
        seq_conflicts = {};
        cell_flows = {};
        training_dir;
        confidence_epe_th = -1;
        confidence_ae_th = -1;
        
        extra_id = [];
        flow_ids = [];
        flow_short_types = {};
        
        TEMP_SUBDIR = 'temp_delete_if_found_%s';
    end
    
    
    properties (Constant)
        PRECOMPUTED_FC_FILE = 'fc_%s.mat';
        CLASSIFIER_XML_FILE = 'fc_%s_%s_%s.xml';
        
        FEATURE_TYPE = 'Flow Confidence';
        FEATURE_SHORT_TYPE = 'FC';
    end
    
    
    methods
        function obj = FlowConfidenceFeature( cell_flows, training_seqs, seq_conflicts, training_dir, confidence_epe_th, confidence_ae_th )
            assert(~isempty(cell_flows), ['There should be atleast 1 flow algorithm to compute ' class(obj)]);
            
            % store the flow algorithms to be used and their ids
            obj.cell_flows = cell_flows;
            for algo_idx = 1:length(obj.cell_flows)
                obj.flow_short_types{end+1} = obj.cell_flows{algo_idx}.OF_SHORT_TYPE;
                obj.flow_ids(end+1) = obj.cell_flows{algo_idx}.returnNoID();
            end
            
            obj.confidence_epe_th = confidence_epe_th;
            obj.confidence_ae_th = confidence_ae_th;
            obj.training_seqs = training_seqs;
            obj.seq_conflicts = seq_conflicts;
            obj.training_dir = training_dir;
            
            obj.extra_id = obj.getExtraID();
            
            t = clock;
            obj.TEMP_SUBDIR = sprintf(obj.TEMP_SUBDIR, sprintf('%04d%02d%02d_%02d%02d%02d_%03d', t(1), t(2), t(3), t(4), t(5), uint16(t(6)), uint16(mod(t(6)*1000,1000))));
        end
        
        
        function [ featconf feature_depth compute_time ] = calcFeatures( obj, calc_feature_vec )
        % this function outputs the feature for this class, and the depth 
        %   of this feature (number of unique features associated with this
        %   class). The size of featconf is the same as the input image, 
        %   with a depth equivalent to the number of flow algos times the 
        %   number of scales
        
            t_start_main = tic;
            compute_time = {'totaltime', 0.0; sprintf('fc_confidence_%s', num2str(obj.getExtraID())), 0.0};
            
            % find which algos to use
            algos_to_use = cellfun(@(x) find(strcmp(x, calc_feature_vec.extra_info.calc_flows.algo_ids)), obj.flow_short_types);

            assert(length(algos_to_use)==length(obj.flow_short_types), ['Can''t find matching flow algorithm(s) used in computation of ' class(obj)]);
            assert(isfield(calc_feature_vec.extra_info, 'calc_flows'), 'The CalcFlows object has not been defined in the passed ComputeFeatureVectors');

            precompute_fc_filename = sprintf(obj.PRECOMPUTED_FC_FILE, num2str(obj.returnNoID()));
            
            if exist(fullfile(calc_feature_vec.scene_dir, precompute_fc_filename), 'file') == 2
                load(fullfile(calc_feature_vec.scene_dir, precompute_fc_filename));

                compute_time{2,2} = fc_compute_time;
                compute_time{1,2} = compute_time{1,2} + compute_time{2,2};
            else
                t_start_fc = tic;
                
                assert(~(exist(fullfile(obj.training_dir, obj.TEMP_SUBDIR),'dir')==7), ['The temp directory to be used by ' class(obj) ' already exists']);
                mkdir(fullfile(obj.training_dir, obj.TEMP_SUBDIR));
                
                % make feature vector which will be used for training
                [ settings ] = obj.prepareSettings(calc_feature_vec);
                COMPUTE_REFRESH = 0;
                
                training_s = obj.training_seqs;
                
                % see if the seq. we want to test is in the training seq.s
                [dir_scene, scene_id] = fileparts(calc_feature_vec.scene_dir);
                training_ids = training_s;
                if strcmp(regexprep(obj.training_dir, '/', '\'), regexprep(dir_scene, '/', '\'))
                    training_ids = trainingSequencesUtils('getTrainingSequences', training_s, str2num(scene_id), obj.seq_conflicts);
                end
                
                [scene_main_dir scene_id] = fileparts(calc_feature_vec.scene_dir);
                scene_id = str2double(scene_id);
                
                % labels to compute on
                labels_to_use = {FlowEPEConfidenceLabel(obj.confidence_epe_th), FlowAEConfidenceLabel(obj.confidence_ae_th)};
                
                % initialize the feature vector
                featconf = zeros(calc_feature_vec.image_sz(1), calc_feature_vec.image_sz(2), length(labels_to_use)*length(obj.flow_short_types));
                
                % if the sequences contain the sequence we want to test
                if ~all(ismember(training_s, training_ids))
                    % test with a classifier which doesn't have the testing seq.
                    %   (throw away the classifier)
                    training_s = training_ids;
                    
                    % get feature for each flow algo.
                    for algo_idx = 1:length(obj.flow_short_types)
                        % we want to build Photoconstancy feature for all 
                        %   algo.s but only use one at a time in 
                        %   training/testing
                        settings.USE_ONLY_OF = obj.flow_short_types{algo_idx};
                        
                        for label_idx = 1:length(labels_to_use)
                            no_test = ((algo_idx-1)*length(labels_to_use))+label_idx;
                            
                            % the labelling class used for the classifier
                            settings.label_obj = labels_to_use{label_idx};    

                            % create the main object, which creates the test and training data
                            traintest_data = ComputeTrainTestData( obj.training_dir, fullfile(obj.training_dir, obj.TEMP_SUBDIR), settings, 0, COMPUTE_REFRESH, 1 );
                            
                            % produce the training and testing data
                            [ TRAIN_PATH TEST_PATH unique_id featvec_id ] = traintest_data.produceTrainingTestingData(scene_id, training_s);

                            PREDICTION_DATA_PATH = obj.getPredictionDataFilename(fullfile(obj.training_dir, obj.TEMP_SUBDIR), scene_id, unique_id, settings.USE_ONLY_OF);

                            randomforest_cmd = [settings.RANDOM_FOREST_RUN ' ' settings.RF_MAX_TREE_COUNT ' ' ...
                                    settings.RF_NO_ACTIVE_VARS ' ' settings.RF_MAX_DEPTH ' ' settings.RF_MIN_SAMPLE_COUNT ' ' ...
                                    settings.RF_MAX_CATEGORIES ' ' settings.RF_GET_VAR_IMP ' "' TRAIN_PATH '" "' ...
                                    TEST_PATH '" "' PREDICTION_DATA_PATH '" -b'];

                            fprintf(1, '//> Running %d/%d Random Forest classifier (for FlowConfidenceFeature)\n', no_test, length(labels_to_use)*length(obj.flow_short_types));
                            [ ret_val out ] = system(randomforest_cmd);

                            % read in predicted file
                            classifier_out = textread(PREDICTION_DATA_PATH, '%f');
                            classifier_out = reshape(classifier_out, calc_feature_vec.image_sz(2), calc_feature_vec.image_sz(1))';   % need the transpose to read correctly

                            % store the classifier output as the feature
                            featconf(:,:,no_test) = classifier_out;
                            
                            % delete all the data used to build the classifier
                            obj.deleteTrainTestData(unique_id);
                        end
                    end
                else
                    unique_id = -1;
                    
                    % get feature for each flow algo.
                    for algo_idx = 1:length(obj.flow_short_types)
                        % we want to build Photoconstancy feature for all 
                        %   algo.s but only use one at a time in 
                        %   training/testing
                        settings.USE_ONLY_OF = obj.flow_short_types{algo_idx};
                        
                        for label_idx = 1:length(labels_to_use)
                            no_test = ((algo_idx-1)*length(labels_to_use))+label_idx;
                            
                            % the labelling class used for the classifier
                            settings.label_obj = labels_to_use{label_idx};
                            
                            % if not then check if the classifier class file is there
                            precompute_filename = sprintf(obj.CLASSIFIER_XML_FILE, num2str(obj.getExtraID()), settings.USE_ONLY_OF, settings.label_obj.LABEL_SHORT_TYPE);
                            CLASS_XML_PATH = fullfile(obj.training_dir, precompute_filename);
                            
                            if exist(CLASS_XML_PATH, 'file') ~= 2
                                % if not, train with the training seq. and test with the classifier built

                                % create the main object, which creates the test and training data
                                traintest_data = ComputeTrainTestData( obj.training_dir, fullfile(obj.training_dir, obj.TEMP_SUBDIR), settings, 0, COMPUTE_REFRESH, 1 );
                                
                                % produce the training and testing data
                                if unique_id == -1
                                    [ TRAIN_PATH unique_id featvec_id ] = traintest_data.produceTrainingData(scene_id, training_s);
                                else
                                    [ TRAIN_PATH unique_id featvec_id ] = traintest_data.produceTrainingData(scene_id, training_s, unique_id, featvec_id);
                                end

                                randomforest_cmd = [settings.RANDOM_FOREST_RUN ' ' settings.RF_MAX_TREE_COUNT ' ' ...
                                    settings.RF_NO_ACTIVE_VARS ' ' settings.RF_MAX_DEPTH ' ' settings.RF_MIN_SAMPLE_COUNT ' ' ...
                                    settings.RF_MAX_CATEGORIES ' ' settings.RF_GET_VAR_IMP ' -s "' CLASS_XML_PATH '" "' ...
                                    TRAIN_PATH '" -b'];
                                
                                fprintf(1, '//> Running Random Forest for building XML classifier (for FlowConfidenceFeature) - %s %s\n', settings.USE_ONLY_OF, settings.label_obj.LABEL_SHORT_TYPE);
                                [ ret_val out ] = system(randomforest_cmd);
                            end
                            
                            % once the classifier is ready
                            
                            % create the main object, which creates the training data
                            traintest_data = ComputeTrainTestData( scene_main_dir, fullfile(obj.training_dir, obj.TEMP_SUBDIR), settings, 0, COMPUTE_REFRESH, 1 );
                            
                            % produce the testing data
                            [ TEST_PATH unique_id featvec_id ] = traintest_data.produceTestingData( scene_id );
                            
                            PREDICTION_DATA_PATH = obj.getPredictionDataFilename(fullfile(obj.training_dir, obj.TEMP_SUBDIR), scene_id, unique_id, settings.USE_ONLY_OF);

                            randomforest_cmd = [settings.RANDOM_FOREST_RUN ' -l "' CLASS_XML_PATH '" "' ...
                                    TEST_PATH '" "' PREDICTION_DATA_PATH '" -b'];

                            fprintf(1, '//> Running %d/%d Random Forest classifier (for FlowConfidenceFeature)\n', no_test, length(labels_to_use)*length(obj.flow_short_types));
                            [ ret_val out ] = system(randomforest_cmd);
                            
                            % read in predicted file
                            classifier_out = textread(PREDICTION_DATA_PATH, '%f');
                            classifier_out = reshape(classifier_out, calc_feature_vec.image_sz(2), calc_feature_vec.image_sz(1))';   % need the transpose to read correctly

                            % store the classifier output as the feature
                            featconf(:,:,no_test) = classifier_out;
                            
                            % delete all the data used to build the classifier
                            obj.deleteTrainTestData(unique_id);
                        end
                    end
                end
                
                obj.deleteFVData(calc_feature_vec.scene_dir, scene_id, obj.training_seqs, unique_id, featvec_id);
                
                fc_compute_time = toc(t_start_fc);
                fprintf(1, '//> FlowConfidenceFeature took %f secs to compute\n', fc_compute_time);
                
                % save the classifier's output
                save(fullfile(calc_feature_vec.scene_dir, precompute_fc_filename), 'featconf', 'fc_compute_time');
                
                compute_time{2,2} = fc_compute_time;
                
                % remove the temporary folder if present and empty
                if isdir(fullfile(obj.training_dir, obj.TEMP_SUBDIR))
                    rmdir(fullfile(obj.training_dir, obj.TEMP_SUBDIR), 's');
                end
            end
            
            feature_depth = size(featconf,3);
            
            compute_time{1,2} = compute_time{1,2} + toc(t_start_main);
        end
        
        
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = returnNoID@AbstractFeature(obj);
            
            feature_no_id = (nos*100) + sum(obj.flow_ids) + obj.extra_id;
        end
        
        
        function return_feature_list = returnFeatureList(obj)
        % creates a cell vector where each item contains a string of the
        % feature type (in the order the will be spit out by calcFeatures)
            
            return_feature_list = cell(2*length(obj.flow_short_types),1);
            
            for flow_id = 1:length(obj.flow_short_types)
                return_feature_list{((flow_id-1)*2)+1} = {[obj.FEATURE_TYPE ' using ' obj.flow_short_types{flow_id}], 'End Point Error (EPE)', sprintf('Threshold %.3f', obj.confidence_epe_th)};
                return_feature_list{((flow_id-1)*2)+2} = {[obj.FEATURE_TYPE ' using ' obj.flow_short_types{flow_id}], 'Angular Error (AE)', sprintf('Threshold %.3f', obj.confidence_ae_th)};
            end
        end
    end
    
    
    methods (Access = private)
        function [ settings ] = prepareSettings(obj, calc_feature_vec)
            % number of examples used in training for each class
            settings.MAX_MARKINGS_PER_LABEL = 7000;

            % if you want to build Photoconstancy feature for all algo.s 
            %   but only use one in training/testing
            settings.USE_ONLY_OF = '';      % HuberL1OF.OF_SHORT_TYPE;

            % OpenCV Random Forest parameters
            settings.RF_MAX_DEPTH = '30';           % maximum levels in a tree
            settings.RF_MIN_SAMPLE_COUNT = '25';    % don't split a node if less
            settings.RF_MAX_CATEGORIES = '30';      % limits the no. of categorical values before the decision tree preclusters those categories so that it will have to test no more than 2^max_categories-2 possible value subsets. Low values reduces computation at the cost of accuracy
            settings.RF_NO_ACTIVE_VARS = '4';       % size of randomly selected subset of features to be tested at any given node (typically the sqrt of total no. of features)
            settings.RF_MAX_TREE_COUNT = '100';
            settings.RF_GET_VAR_IMP = '0';          % calculate the variable importance of each feature during training (at cost of additional computation time)

            % create the structure of OF algos to use and Features to compute
            settings.cell_flows = obj.cell_flows;
            
                                     % no_scales     % scale
            settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
            settings.ss_info_im2 =  [ 1              1 ];                                   % image pyramid to be built for im2
            settings.uv_ss_info =   [ 10             0.8 ];
            
            settings.cell_features = { GradientMagFeature(settings.ss_info_im1), ....
                                       EdgeDistFeature(settings.ss_info_im1), ...
                                       TemporalGradFeature(settings.cell_flows, settings.uv_ss_info), ...
                                       PhotoConstancyFeature(settings.cell_flows) };
            
            % store the random forest command to run
            if exist('calc_feature_vec', 'var') == 1
                settings.RANDOM_FOREST_RUN = calc_feature_vec.extra_info.settings.RANDOM_FOREST_RUN;
            else
                settings.RANDOM_FOREST_RUN = '';
            end 
        end
        
        
        function deleteTrainTestData( obj, unique_id )
            delete(fullfile(fullfile(obj.training_dir, obj.TEMP_SUBDIR), ['*' num2str(unique_id) '*_Test.data']));
            delete(fullfile(fullfile(obj.training_dir, obj.TEMP_SUBDIR), ['*' num2str(unique_id) '*_Train.data']));
            delete(fullfile(fullfile(obj.training_dir, obj.TEMP_SUBDIR), ['*' num2str(unique_id) '*_prediction.data']));
        end


        function deleteFVData( obj, main_scene_dir, main_scene_id, training_seqs, unique_id, featvec_id)
            % delete feature vectors from training sequences
            for scene_id = training_seqs
                fv_filename = fullfile(obj.training_dir, num2str(scene_id), sprintf('%d_%d_FV.mat', scene_id, featvec_id));
                if exist(fv_filename, 'file') == 2
                    delete(fv_filename);
                end
            end
            
            % delete feature vectors from scene_dir
            fv_filename = fullfile(main_scene_dir, sprintf('%d_%d_FV.mat', main_scene_id, featvec_id));
            if exist(fv_filename, 'file') == 2
                delete(fv_filename);
            end
        end
        
        
        function filename = getPredictionDataFilename(obj, out_dir, scene_id, comp_feat_vec_id, only_of)
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
        
        
        function [ extra_id ] = getExtraID( obj )
            settings = obj.prepareSettings();
            
            % calculate the id's using the settings
            unique_id = [];
            
            for feature_idx = 1:length(settings.cell_features)
                unique_id = [unique_id settings.cell_features{feature_idx}.returnNoID()];
            end
            
            for algo_idx = 1:length(settings.cell_flows)
                unique_id = [unique_id settings.cell_flows{algo_idx}.returnNoID()];
            end
            
            temp = sum((obj.confidence_epe_th + obj.confidence_ae_th) + obj.training_seqs.^2);
            % get first 2 decimal digits
            temp = mod(round(temp), 1000);
            
            % sum them since order doesn't matter
            extra_id = sum(unique_id) + temp;
        end
    end
    
end

