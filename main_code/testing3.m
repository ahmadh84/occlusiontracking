function testing3
%TESTING3 Summary of this function goes here
%   Detailed explanation goes here

main_dir = 'H:/oisin+middlebury_cropped';
out_dir = 'H:/middlebury/temp_tests';

training_seq = [4 5 9 10 11 12 13 14 18 19];
testing_seq = [4 9 18];


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

        temp_out_dir = fullfile(out_dir, 'cropped_av_lv_cs_pc', [num2str(nhood_size) '_' num2str(pc_scales)]);

        [ unique_id ] = mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );

        deleteTrainTestData(temp_out_dir);
        deleteFVData(main_dir, union(testing_seq, training_seq), unique_id);
    end
end



function deleteTrainTestData( d )
delete(fullfile(d, '*_Test.data'));
delete(fullfile(d, '*_Train.data'));

function deleteFVData( d, sequences, unique_id )
for scene_id = sequences
    fv_filename = sprintf('%d_%d_FV.mat', scene_id, unique_id);
    delete(fullfile(d, num2str(scene_id), fv_filename));
end