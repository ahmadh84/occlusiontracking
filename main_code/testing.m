function testing
% TESTING - Changing RF params
main_dir = '../../Data/oisin+middlebury';
out_dir = 'H:/middlebury/temp';

training_seq = [4 5 9 10 11 12 13 14 18 19];
testing_seq = [4 9 18];


% changing no. of features per node
for rf_nactive_vars = [1 2:3:17 40]
    close all;
    
    override_settings = struct;
    override_settings.RF_NO_ACTIVE_VARS = num2str(rf_nactive_vars);
    
    temp_out_dir = fullfile(out_dir, 'rf_nactive', num2str(rf_nactive_vars));
    
    mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
end


% changing max number of categories before pre-clustering
for max_catg = 10:5:40
    close all;
    
    override_settings = struct;
    override_settings.RF_MAX_CATEGORIES = num2str(max_catg);
    
    temp_out_dir = fullfile(out_dir, 'max_catg', num2str(max_catg));
    
    mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
end

% max number of random trees
for max_trees = [1 5 10 30:30:200]
    close all;
    
    override_settings = struct;
    override_settings.RF_MAX_TREE_COUNT = num2str(max_trees);
    
    temp_out_dir = fullfile(out_dir, 'max_trees', num2str(max_trees));
    
    mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
end


for max_depth = [1 5 10:10:50]
    close all;
    
    override_settings = struct;
    override_settings.RF_MAX_DEPTH = num2str(max_depth);
    
    temp_out_dir = fullfile(out_dir, 'max_depth', num2str(max_depth));
    
    mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
end
 

for sample_count = [10:10:50 100 200 300]
    close all;
    
    override_settings = struct;
    override_settings.RF_MIN_SAMPLE_COUNT = num2str(sample_count);
    
    temp_out_dir = fullfile(out_dir, 'min_sample_cnt', num2str(sample_count));
    
    mainTrainingTesting( testing_seq, training_seq, main_dir, temp_out_dir, override_settings );
    
    trainTestDelete('deleteTrainTestData', temp_out_dir);
end

