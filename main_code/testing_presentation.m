function [ output_args ] = testing_presentation( input_args )
%TESTING_PRESENTATION Summary of this function goes here
%   Detailed explanation goes here

training_seq = [];
    
override_settings = struct;
uv_ftrs1_ss_info =               [ 10             0.8 ];   % this and the var below are there, because Temporal gradient and other features need different UV SS
uv_ftrs2_ss_info =               [ 4              0.8 ];
override_settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
override_settings.ss_info_im2 =  uv_ftrs2_ss_info;                                       % image pyramid to be built for im2
% create the structure of OF algos to use and Features to compute
override_settings.cell_flows = { BlackAnandanOF, ...
                                 TVL1OF, ...
                                 HornSchunckOF, ...
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
                                    PhotoConstancyFeature(override_settings.cell_flows, uv_ftrs2_ss_info), ...
                                    SparseSetTextureFeature2(override_settings.cell_flows, nhood), ...
                                    SparseSetTextureFeature(override_settings.cell_flows), ...
                                    TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                    OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                    OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info), ...
                                    ReverseFlowConstancyFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    ReverseFlowAngleDiffFeature(override_settings.cell_flows, uv_ftrs1_ss_info) };

                                
temp_out_dir = 'H:/middlebury/Final_Tests/walking_legs/';
main_dir = 'H:/evaluation_data/walking_legs';
testing_seq = 1:9;
[ unique_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

deleteTrainTestData(temp_out_dir);
deleteFVData(main_dir, union(testing_seq, training_seq), unique_id);


temp_out_dir = 'H:/middlebury/Final_Tests/hand3/';
main_dir = 'H:/evaluation_data/hand3';
testing_seq = 1:9;
[ unique_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

deleteTrainTestData(temp_out_dir);
deleteFVData(main_dir, union(testing_seq, training_seq), unique_id);

temp_out_dir = 'H:/middlebury/Final_Tests/squirrel2/';
main_dir = 'H:/evaluation_data/squirrel2';
testing_seq = 1:7;
[ unique_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

deleteTrainTestData(temp_out_dir);
deleteFVData(main_dir, union(testing_seq, training_seq), unique_id);

temp_out_dir = 'H:/middlebury/Final_Tests/rocking_horse/';
main_dir = 'H:/evaluation_data/rocking_horse';
testing_seq = 1:19;
[ unique_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

deleteTrainTestData(temp_out_dir);
deleteFVData(main_dir, union(testing_seq, training_seq), unique_id);



function trainTestDelete(testing_seq, training_seq, main_dir, temp_out_dir, override_settings)
[ unique_id ] = mainTrainingTesting( testing_seq, [], main_dir, temp_out_dir, override_settings );
deleteTrainTestXMLData(temp_out_dir);
deleteFVData(main_dir, union(training_seq, testing_seq), unique_id);

close all;


function deleteTrainTestXMLData( d )
delete(fullfile(d, '*_Test.data'));
delete(fullfile(d, '*_Train.data'));
delete(fullfile(d, '*_class.xml'));


function deleteFVData( d, sequences, unique_id )
for scene_id = sequences
    fv_filename = sprintf('%d_%d_FV.mat', scene_id, unique_id);
    delete(fullfile(d, num2str(scene_id), fv_filename));
end
