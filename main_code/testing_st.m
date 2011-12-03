function [ output_args ] = testing_st( input_args )
%TESTING_PB Summary of this function goes here
%   Detailed explanation goes here

main_dir = '../../Data/oisin+middlebury';
out_dir = 'D:/ahumayun/Results/features_comparison_tests/features_st';

training_seq = [4 5 9 10 11 12 13 14 18 19];
testing_seq = [4 5 9 10 11 12 13 14 18 19];


override_settings.cell_flows = { BlackAnandanOF, ...
                                 TVL1OF, ...
                                 HornSchunckOF, ...
                                 HuberL1OF, ...
                                 ClassicNLOF, ...
                                 LargeDisplacementOF };
temp_out_dir = [out_dir '_mhlnbs'];
override_settings.cell_features = { SparseSetTextureFeature(override_settings.cell_flows) };
[ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

trainTestDelete('deleteTrainTestData', temp_out_dir);
trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);


for w = [17:4:21]
    close all;

    [c r] = meshgrid(-w:w, -w:w);
    nhood = cat(3, r(:), c(:));

    override_settings = struct;
    override_settings.cell_flows = { BlackAnandanOF, ...
                                 TVL1OF, ...
                                 HornSchunckOF, ...
                                 HuberL1OF, ...
                                 ClassicNLOF, ...
                                 LargeDisplacementOF };    
    override_settings.cell_features = { SparseSetTextureFeature2(override_settings.cell_flows, nhood) };

    temp_out_dir = fullfile(out_dir, [num2str((w*2)+1)]);

    [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

    trainTestDelete('deleteTrainTestData', temp_out_dir);
    trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
end

