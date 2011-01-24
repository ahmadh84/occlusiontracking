function [ output_args ] = testing_final_copy_copy( input_args )
%TESTING5 Summary of this function goes here
%   Detailed explanation goes here

main_dir = '../../Data/oisin+middlebury';
out_dir = 'D:/ahumayun/Results/features_comparison_tests5';

seq_conflicts = {[2 3], [6 7 16], [11 12], [13 14], [18 19], [9 20 21 22 40:48 10 23 24 25], [26 27 28 29], [30:39], [49:52]};

training_seq = [4 5 9 10 11 12 13 14 17 18 19 28];
testing_seq = [14];
% training_seq = [];
% testing_seq = [1, 2, 3, 4, 5, 8, 10, 13, 15, 18, 21, 22, 26, 30];

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
override_settings.cell_flows = { BlackAnandanOF, ...
                                 TVL1OF, ...
                                 HornSchunckOF, ...
                                 HuberL1OF, ...
                                 ClassicNLOF, ...
                                 LargeDisplacementOF };
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
temp_out_dir = fullfile(out_dir, 'ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp-sans-BA-HS');
override_settings.cell_features = { EdgeDistFeature(override_settings.ss_info_im1), ...
                                    PbEdgeStrengthFeature(0.1, uv_ftrs2_ss_info), ...
                                    PbEdgeStrengthFeature(0.4, uv_ftrs2_ss_info), ...
                                    PhotoConstancyFeature(override_settings.cell_flows, uv_ftrs2_ss_info), ...
                                    SparseSetTextureFeature2(override_settings.cell_flows, nhood), ...
                                    SparseSetTextureFeature(override_settings.cell_flows), ...
                                    TemporalGradFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                    OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                    OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info, {'MAX'}), ...
                                    ReverseFlowConstancyFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    ReverseFlowAngleDiffFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    FlowConfidenceFeature(override_settings.cell_flows, [4 5 9 10 11 12 13 14 17 18 19 28], '../../Data/oisin+middlebury', 50, 60), ...
                                    FlowConfidenceFeature(override_settings.cell_flows, [4 5 9 10 11 12 13 14 17 18 19 28], '../../Data/oisin+middlebury', 1, 1), ...
                                    FlowAngleVarianceFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    FlowLengthVarianceFeature(override_settings.cell_flows, uv_ftrs1_ss_info), ...
                                    SPFlowBoundaryFeature(override_settings.cell_flows) };

% temp_out_dir = fullfile(out_dir, 'ed_pc_st_stm_tg_av_lv_cs_rc_ra', 'other');
% trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);

temp_out_dir = fullfile(out_dir, 'ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp-sans-BA-HS-middl');
training_seq = [9 10 11 12 13 14 17 18 19 28];
trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings);

% 
% d = dir(fullfile(temp_out_dir, '*_class.xml'));
% 
% copyfile(fullfile(temp_out_dir, d(1).name), fullfile(temp_out_dir, 'stein'));
main_dir = '../../Data/evaluation_data/stein';
% 
temp_out_dir = fullfile(out_dir, 'ed_pb_pb_pc_st_stm_tg_av_lv_cs-max_rc_ra_fc_fc_fa_fn_sp-sans-BA-HS', 'stein');

training_seq = [];
testing_seq = [19 21]; %[1 2 3 4 7 8 10 12 13 15 16 18 19 21 26 28 29 30];

% trainTestDelete(testing_seq, training_seq, main_dir, temp_out_dir, override_settings);



function trainTestDelete(testing_seq, training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings)

if isempty(training_seq)
    [ unique_id ] = mainTrainingTesting( testing_seq, [], seq_conflicts, main_dir, temp_out_dir, override_settings );
else
    % get the XML file first
%     [ unique_id ] = mainTrainingTesting( setdiff(testing_seq, training_seq), training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings, 1 );
    % then test on rest
    [ unique_id ] = mainTrainingTesting( intersect(testing_seq, training_seq), training_seq, seq_conflicts, main_dir, temp_out_dir, override_settings );
end

deleteTrainTestXMLData(temp_out_dir);

deleteFVData(main_dir, union(training_seq, testing_seq), unique_id);
close all;


function deleteTrainTestXMLData( d )
delete(fullfile(d, '*_Test.data'));
delete(fullfile(d, '*_Train.data'));
%delete(fullfile(d, '*_class.xml'));


function deleteFVData( d, sequences, unique_id )
for scene_id = sequences
    fv_filename = sprintf('%d_%d_FV.mat', scene_id, unique_id);
    delete(fullfile(d, num2str(scene_id), fv_filename));
end
