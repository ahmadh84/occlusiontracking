function [ output_args ] = testing5( input_args )
%TESTING5 Summary of this function goes here
%   Detailed explanation goes here

main_dir = '../../Data/oisin+middlebury/';
out_dir = 'H:/middlebury/texture_comparison_tests';

training_seq = {[4 5 10 11 12 13 14 18 19 24 25], [4 5 9 11 12 13 14 18 19 21 22]};
testing_seq = {[9 20 21 22],                      [10 23 24 25]};

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
                                         
% %%% GM %%%
% temp_out_dir = fullfile(out_dir, 'gm');
% override_settings.cell_features = { GradientMagFeature(override_settings.ss_info_im1) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);
% 
% %%% ED %%%
% temp_out_dir = fullfile(out_dir, 'ed');
% override_settings.cell_features = { EdgeDistFeature(override_settings.ss_info_im1) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);
% 
% %%% TG %%%
% temp_out_dir = fullfile(out_dir, 'tg');
% override_settings.cell_features = { TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);
% 
% %%% PC %%%
% temp_out_dir = fullfile(out_dir, 'pc');
% override_settings.cell_features = { PhotoConstancyFeature(override_settings.cell_flows, uv_ftrs2_ss_info) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);
% 
% %%% AV %%%
% temp_out_dir = fullfile(out_dir, 'av');
% override_settings.cell_features = { OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);
% 
% %%% LV %%%
% temp_out_dir = fullfile(out_dir, 'lv');
% override_settings.cell_features = { OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);
% 
% %%% CS %%%
% temp_out_dir = fullfile(out_dir, 'cs');
% override_settings.cell_features = { OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);
% 
% %%% RC %%%
% temp_out_dir = fullfile(out_dir, 'rc');
% override_settings.cell_features = { ReverseFlowConstancyFeature(override_settings.cell_flows, uv_ftrs1_ss_info) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);
% 
% %%% RA %%%
% temp_out_dir = fullfile(out_dir, 'ra');
% override_settings.cell_features = { ReverseFlowAngleDiffFeature(override_settings.cell_flows, uv_ftrs1_ss_info) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);
% 
% %%% ST %%%
% temp_out_dir = fullfile(out_dir, 'st');
% override_settings.cell_features = { SparseSetTextureFeature(override_settings.cell_flows) };
% trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);

%%% All features %%%
temp_out_dir = fullfile(out_dir, 'gm_ed_tg_pc_av_lv_cs_rc_ra_st');
override_settings.cell_features = { GradientMagFeature(override_settings.ss_info_im1), ...
                                    EdgeDistFeature(override_settings.ss_info_im1), ...
                                    TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    PhotoConstancyFeature(override_settings.cell_flows, uv_ftrs2_ss_info), ...
                                    OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                    OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                    OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info), ...
                                    ReverseFlowConstancyFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    ReverseFlowAngleDiffFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    SparseSetTextureFeature(override_settings.cell_flows) };
trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);



function trainTestDeleteThis(testing_seq, training_seq, main_dir, temp_out_dir, override_settings)
for i = 1:length(testing_seq)
    [ unique_id featvec_id ] = mainTrainingTesting( testing_seq{i}(1), training_seq{i}, main_dir, temp_out_dir, override_settings, 1 );
    [ unique_id featvec_id ] = mainTrainingTesting( testing_seq{i}(2:end), [], main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir, 1);
end
    
trainTestDelete('deleteFVData', main_dir, union(cell2mat(training_seq), cell2mat(testing_seq)), unique_id, featvec_id);

close all;
