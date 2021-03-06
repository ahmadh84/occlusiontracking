function [ output_args ] = testing6( input_args )
%TESTING6 Summary of this function goes here
%   Detailed explanation goes here

    main_dir = '../../Data/oisin+middlebury';
    
    out_dir = 'D:/ahumayun/Results/features_comparison_tests2';

    training_seq = [4 5 9 10 11 12 13 14 18 19];
    testing_seq = [10 11 12 13 14 18 19];
    
    
    %%%%%%%%%%%%%%%% AV LV CS %%%%%%%%%%%%%%%%%%%%%%%%
%     close all;
%     
%     override_settings = struct;
%     uv_ftrs2_ss_info = [ 4              0.8 ];
%     
%     nhood_size = 1;
%     [c r] = meshgrid(-nhood_size:nhood_size, -nhood_size:nhood_size);
%     nhood = cat(3, r(:), c(:));
%     nhood_cs = nhood;
%     nhood_cs(nhood_cs(:,:,1)==0 & nhood_cs(:,:,2)==0,:,:) = [];
%     
%     override_settings.cell_flows = { BlackAnandanOF, ...
%                                      TVL1OF, ...
%                                      HornSchunckOF, ...
%                                      HuberL1OF, ...
%                                      ClassicNLOF, ...
%                                      LargeDisplacementOF };
%     override_settings.cell_features = { OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
%                                         OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
%                                         OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info) };
% 
%     temp_out_dir = fullfile(out_dir, 'av_lv_cs');
% 
%     [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
%     
%     deleteTrainTestData(temp_out_dir);
%     deleteFVData(main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
    
    
    %%%%%%%%%%%%%%%% AV LV CS PC %%%%%%%%%%%%%%%%%%%%%%%%
    close all;
    
    override_settings = struct;
    uv_ftrs2_ss_info = [ 4              0.8 ];
    
    nhood_size = 1;
    pc_scales = 4;
    [c r] = meshgrid(-nhood_size:nhood_size, -nhood_size:nhood_size);
    nhood = cat(3, r(:), c(:));
    nhood_cs = nhood;
    nhood_cs(nhood_cs(:,:,1)==0 & nhood_cs(:,:,2)==0,:,:) = [];
        
    override_settings.ss_info_im1 =  [ pc_scales   0.8 ];                                 % image pyramid to be built for im1
    override_settings.ss_info_im2 =  [ pc_scales   0.8 ];                                 % image pyramid to be built for im2

    override_settings.uv_ss_info =   [ max([uv_ftrs2_ss_info(1) pc_scales])   0.8 ];

    override_settings.cell_flows = { BlackAnandanOF, ...
                                     TVL1OF, ...
                                     HornSchunckOF, ...
                                     HuberL1OF, ...
                                     ClassicNLOF, ...
                                     LargeDisplacementOF };
    override_settings.cell_features = { OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info), ...
                                        PhotoConstancyFeature(override_settings.cell_flows, override_settings.ss_info_im1) };

    temp_out_dir = fullfile(out_dir, 'av_lv_cs_pc');

    [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
    trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);

