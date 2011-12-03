function [ output_args ] = testing_pb( input_args )
%TESTING_PB Summary of this function goes here
%   Detailed explanation goes here

main_dir = '../../Data/oisin+middlebury';
out_dir = 'H:/middlebury/features_comparison_tests/features_pb';

training_seq = [4 5 9 10 11 12 13 14 18 19];
testing_seq = [4 5 9 10 11 12 13 14 18 19];


for threshold = [0.4 0.5]
    close all;

    override_settings = struct;
    override_settings.cell_features = { PbEdgeStrengthFeature(threshold) };

    temp_out_dir = fullfile(out_dir, [num2str(threshold)]);

    [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

    trainTestDelete('deleteTrainTestData', temp_out_dir);
    trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
end

