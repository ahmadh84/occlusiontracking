function testing2
% TESTING - Changing RF params
main_dir = '../../Data/oisin+middlebury';
out_dir = 'H:/middlebury/dataset_comparison_tests';

training_seq = [4 5 9 10 11 12 13 14 18 19];
testing_seq = [4 9 18];


for max_training_markers = [30:30:150 300:300:1500 3000:3000:15000]
    close all;
    
    override_settings = struct;
    override_settings.MAX_MARKINGS_PER_LABEL = max_training_markers;
    
    temp_out_dir = fullfile(out_dir, 'training_samples', num2str(max_training_markers));
    
    mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
end


if ~all(ismember(testing_seq, training_seq))
    warning('testing:TestingParam', 'For unbiased testing across sequences, it is better that the sequences given for testing are all present in the list of training sequences');
end
for no_training_sequences = length(testing_seq)+1:length(training_seq)
    close all;
    
    temp = setdiff(training_seq, testing_seq);
    temp = temp(randperm(length(temp)));
    temp_training = union(testing_seq, temp(1:no_training_sequences-length(testing_seq)));
    
    temp_out_dir = fullfile(out_dir, 'training_sequences', num2str(no_training_sequences-1));
    
    mainTrainingTesting( testing_seq, temp_training, main_dir, temp_out_dir, struct );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
end


out_dir = 'H:/middlebury/features_comparison_tests';
for nhood_size = 2:4
    close all;
    
    override_settings = struct;
    uv_ftrs2_ss_info = [ 4              0.8 ];
    
    [c r] = meshgrid(-nhood_size:nhood_size, -nhood_size:nhood_size);
    nhood = cat(3, r(:), c(:));
    nhood_cs = nhood;
    nhood_cs(nhood_cs(:,:,1)==0 & nhood_cs(:,:,2)==0,:,:) = [];
    
    override_settings.cell_flows = { BlackAnandanOF, ...
                                     TVL1OF, ...
                                     HornSchunckOF, ...
                                     HuberL1OF, ...
                                     ClassicNLOF, ...
                                     LargeDisplacementOF };
    override_settings.cell_features = { OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info), ...
                                        OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info) };

    temp_out_dir = fullfile(out_dir, 'features_av_lv_cs', num2str(nhood_size));

    [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
    trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
end


for pc_scales = [1:3 6:3:15]
    close all;
    
    override_settings = struct;
    override_settings.ss_info_im1 =  [ pc_scales   0.8 ];                                 % image pyramid to be built for im1
    override_settings.ss_info_im2 =  [ pc_scales   0.8 ];                                 % image pyramid to be built for im2
    
    override_settings.uv_ss_info =   [ pc_scales   0.8 ];

    override_settings.cell_flows = { BlackAnandanOF, ...
                                     TVL1OF, ...
                                     HornSchunckOF, ...
                                     HuberL1OF, ...
                                     ClassicNLOF, ...
                                     LargeDisplacementOF };
    override_settings.cell_features = { PhotoConstancyFeature(override_settings.cell_flows, override_settings.ss_info_im1) };

    temp_out_dir = fullfile(out_dir, 'features_pc', num2str(pc_scales));

    [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
    trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
end


for nhood_size = 1:2
    for pc_scales = 1:3
        close all;

        override_settings = struct;
        uv_ftrs2_ss_info = [ 4              0.8 ];

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

        temp_out_dir = fullfile(out_dir, 'features_av_lv_cs_pc', [num2str(nhood_size) '_' num2str(pc_scales)]);

        [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

        trainTestDelete('deleteTrainTestData', temp_out_dir);
        trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
    end
end


for pc_scales = 1:3
    close all;

    override_settings = struct;
    uv_ftrs2_ss_info = [ 4              0.8 ];

    [c r] = meshgrid(-1:1, -1:1);
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
                                        PbEdgeStrengthFeature(), ...
                                        PhotoConstancyFeature(override_settings.cell_flows, override_settings.ss_info_im1) };

    temp_out_dir = fullfile(out_dir, 'features_av_lv_cs_pc_pb', num2str(pc_scales));

    [ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

    trainTestDelete('deleteTrainTestData', temp_out_dir);
    trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
end


override_settings = struct;
uv_ftrs2_ss_info = [ 4              0.8 ];
pc_scales = 2;

[c r] = meshgrid(-1:1, -1:1);
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
                                 
%%%%%%%%%%%%%%%%
override_settings.cell_features = { OFAngleVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info) };
temp_out_dir = fullfile(out_dir, 'features_av');

[ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

trainTestDelete('deleteTrainTestData', temp_out_dir);
trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
close all;

%%%%%%%%%%%%%%%%
override_settings.cell_features = { OFLengthVarianceFeature(override_settings.cell_flows, nhood, uv_ftrs2_ss_info) };
temp_out_dir = fullfile(out_dir, 'features_lv');

[ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

trainTestDelete('deleteTrainTestData', temp_out_dir);
trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
close all;

%%%%%%%%%%%%%%%%
override_settings.cell_features = { OFCollidingSpeedFeature(override_settings.cell_flows, nhood_cs, uv_ftrs2_ss_info) };
temp_out_dir = fullfile(out_dir, 'features_cs');

[ unique_id featvec_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

trainTestDelete('deleteTrainTestData', temp_out_dir);
trainTestDelete('deleteFVData', main_dir, union(testing_seq, training_seq), unique_id, featvec_id);
close all;

