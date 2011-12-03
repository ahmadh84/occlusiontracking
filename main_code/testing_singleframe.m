function [ output_args ] = testing_singleframe( input_args )
%TESTING5 Summary of this function goes here
%   Detailed explanation goes here

main_dir = '../../Data/oisin+middlebury';
out_dir = 'D:/ahumayun/Results/features_comparison_tests4';

% main_dir = '../../Data/evaluation_data/stein';
% out_dir = 'D:/ahumayun/Results/Final_Tests';
% 
% training_seq = [];
% testing_seq = [1 2 3 7 8 10 12 13 16 23 24 26 27 28 29 30];
    
override_settings = struct;
uv_ftrs1_ss_info =               [ 10             0.8 ];   % this and the var below are there, because Temporal gradient and other features need different UV SS
uv_ftrs2_ss_info =               [ 4              0.8 ];
override_settings.ss_info_im1 =  [ 10             0.8 ];                                 % image pyramid to be built for im1
override_settings.ss_info_im2 =  uv_ftrs2_ss_info;                                       % image pyramid to be built for im2
% create the structure of OF algos to use and Features to compute
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


training_seq = [4 5 9 10 11 12 13 14 17 18 19 28];
testing_seq = [4 5 9 10 11 12 13 14 17 18 19 28];

%%% All features %%%
temp_out_dir = fullfile(out_dir, 'ed_pb');
override_settings.cell_features = { EdgeDistFeature(override_settings.ss_info_im1), ...
                                    PbEdgeStrengthFeature(0.1, uv_ftrs2_ss_info), ...
                                    PbEdgeStrengthFeature(0.4, uv_ftrs2_ss_info), ...
                                  };

% temp_out_dir = fullfile(out_dir, 'ed_pc_st_stm_tg_av_lv_cs_rc_ra', 'other');
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);



training_seq = [4 5 9 10 11 12 13 14 17 18 19 28];
testing_seq = [4 5 9 10 11 12 13 14 17 18 19 28];

%%% All features %%%
temp_out_dir = fullfile(out_dir, 'ed_pb_fcsf_fcsf-sans-BA-HS');
override_settings.cell_features = { EdgeDistFeature(override_settings.ss_info_im1), ...
                                    PbEdgeStrengthFeature(0.1, uv_ftrs2_ss_info), ...
                                    PbEdgeStrengthFeature(0.4, uv_ftrs2_ss_info), ...
                                    FlowConfidenceSingleFrameFeature(override_settings.cell_flows, [4 5 9 10 11 12 13 14 17 18 19 28], '../../Data/oisin+middlebury', 50, 60), ...
                                    FlowConfidenceSingleFrameFeature(override_settings.cell_flows, [4 5 9 10 11 12 13 14 17 18 19 28], '../../Data/oisin+middlebury', 1, 1), ...
                                  };

% temp_out_dir = fullfile(out_dir, 'ed_pc_st_stm_tg_av_lv_cs_rc_ra', 'other');
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);



main_dir = '../../Data/evaluation_data/stein';

training_seq = [];
testing_seq = [1 2 3 7 8 10 12 13 16 23 24 26 27 28 29 30];
temp_out_dir = fullfile(out_dir, 'ed_pb_fcsf_fcsf-sans-BA-HS', 'stein');
trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);



function trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings)

[ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
% [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, [], main_dir, temp_out_dir, override_settings );

trainTestDelete('deleteTrainTestData', temp_out_dir);
trainTestDelete('deleteFVData', main_dir, union(training_seq, testing_seq), unique_id, featvec_id);
close all;

