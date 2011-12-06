function [ varargout ] = trainTestDelete( varargin )
% See comments of trainTestDeleteMain for understanding the functionality 
%   of the main function in this file. The function called is given by the  
%   first argument, which is a string indicating the function name:
%
% 'trainTestDeleteMain': to train and test sequences (see comments in
%       function).
% 'deleteTrainTestData': to delete any training and testing data used by
%       the classifier.
% 'deleteFVData': to delete the feature vector data (mat files) built by
%       the classifier.
%
%
% @author: Ahmad Humayun
% @email: ahmad.humyn@gmail.com
% @date: December 2011
%

    % evaluate function according to the number of inputs and outputs
    if nargout(varargin{1}) > 0
        [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
end


function [ MAIN_CLASS_XML_PATH ] = trainTestDeleteMain(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings, output_results_data)
%TRAINTESTDELETE calls mainTrainingTesting function for running the
% classifier for the given test and training sequences. It will also do any
% required cleanup, like deleting the feature vector files, training, or
% testing files created during the classification process.
%
%
% args:
%   testing_seq: A vector of sequence numbers (directories) user wants to
%      run the classifier on.
%
%   training_seq: Can be a vector of sequence numbers (directories); a
%      string giving the filepath for the classifier; or an empty array. In
%      case of a vector, it is used to indicate which sequence numbers
%      (directories) are used as training sequences. In case the user 
%      already has a trained classifier file, you can pass the classifier
%      filepath in this argument. If an empty array is passed, the program
%      considers that the trained classifier file exists, and it is
%      searched for in the <temp_out_dir>.
%
%   seq_conflicts: Is a cell array, where is cell gives sequence numbers of
%      related sequences. 'Related' here refers to a group of sequences
%      such that it would not be fair to test a sequence while one of its 
%      cohort sequences is in the training set. For instance image pairs of
%      of the same objects taken from different view-points might
%      constitute a group. Hence if,
%       <training_seq> := [1 2 3 4]
%       <seq_conflicts> := {[1 2], [3 4]}
%      and we are testing sequence 3, the actual classifier will be only
%      built using sequences [1 2]. In case a trained classifier file
%      provided, it is the responsibility of the user to check for any such
%      conflicts.
%
%   main_dir: Path of the directory holding all the testing sequences (and
%      training sequences if <training_seq> does not specify a trained 
%      classifier file). This directory should have subdirectories named
%      as sequence numbers.
%
%   temp_out_dir: Path where the output will be written to. This would
%      include any classifier file built, output images, and
%      ClassifierOutputHandler mat files.
%
%   override_settings: Struct giving the settings which need to be 
%      overwritten. See mainTrainingTesting.m for an explanation of the
%      settings that the user can override.
% 
% returns:
%   MAIN_CLASS_XML_PATH: Path to the classifier file created in the process
%      of training.
%

    % set extra arguments
    if exist('output_results_data','var') ~= 1
        output_results_data = 1;
    end

    MAIN_CLASS_XML_PATH = '';
    
    if isempty(training_seq)
        [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, [], seq_conflicts, main_dir, temp_out_dir, override_settings, 0, '', output_results_data );
    elseif ischar(training_seq)
        [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings, 0, '', output_results_data );
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
                [ unique_id featvec_id CLASS_XML_PATH ] = mainTrainingTesting( test_seq_groups{idx}(1), training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings, 1, xml_filename_append, output_results_data );
            
                % make the rest use the trained classifier
                [ unique_id featvec_id ] = mainTrainingTesting( test_seq_groups{idx}(2:end), CLASS_XML_PATH, seq_conflicts, main_dir, temp_out_dir, override_settings, 0, '', output_results_data );
            else
                % if only one sequence, only produce XML in the case that
                % it has the full training set
                [ unique_id featvec_id CLASS_XML_PATH ] = mainTrainingTesting( test_seq_groups{idx}, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings, isempty(xml_filename_append), output_results_data );
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
        deleteFVData(main_dir, testing_seq, unique_id, featvec_id);
    else
        deleteFVData(main_dir, union(training_seq, testing_seq), unique_id, featvec_id);
    end
    close all;
end


function deleteTrainTestData( d, delete_classifier )
    delete(fullfile(d, '*_Test.data'));
    delete(fullfile(d, '*_Train.data'));
    
    if exist('delete_classifier','var')==1 && delete_classifier == 1
        delete(fullfile(d, '*_class.xml'));
    end
end


function deleteFVData( d, sequences, unique_id, featvec_id )
    for scene_id = sequences
        fv_filename = sprintf('%d_%d_FV.mat', scene_id, featvec_id);
        fv_filepath = fullfile(d, num2str(scene_id), fv_filename);
        if exist(fv_filepath, 'file') == 2
            delete(fv_filepath);
        end
    end
end
