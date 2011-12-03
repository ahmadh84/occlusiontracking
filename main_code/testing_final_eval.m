function [ output_args ] = testing_final_eval( input_args )
%TESTING_FINAL_EVAL Summary of this function goes here
%   Detailed explanation goes here

main_dir = '../../Data/oisin+middlebury';
out_dir = 'D:/ahumayun/Results/features_comparison_tests3';

training_seq = [4 5 9 10 11 12 13 14 18 19];
testing_seq = [1];
% 
% training_seq = [];
% testing_seq = [1 2 13 14];

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


%%% All features %%%
temp_out_dir = fullfile(out_dir, 'ed_pc_st_stm_tg_av_lv_cs_rc_ra_sans-ba-hs');
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
                                
% [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings, 1 );
% 
% trainTestDelete('deleteTrainTestData', temp_out_dir);
% trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);


main_dir = '../../Data/evaluation_data/stein';
% out_dir = 'D:/ahumayun/Results/Final_Tests';

training_seq = [];
testing_seq = [3 7 8 12 13 16 23 24 27 28 29 30];
temp_out_dir = fullfile(out_dir, 'ed_pc_st_stm_tg_av_lv_cs_rc_ra_sans-ba-hs', 'stein');

[ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

trainTestDelete('deleteTrainTestData', temp_out_dir);
trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
