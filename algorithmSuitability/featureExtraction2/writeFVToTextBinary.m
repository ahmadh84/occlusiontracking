%
%   Note the change in the op dir at the very end, should be writing to a
%   folder specific to each flow al
%

% write training data to file
clear all;

addpath(genpath('utils'));

test = 0; % if test ==1, no gt and dont want training files
noScenes = 30;
sceneID = 5;
dir  = fullfile(pwd, '../data/');
opDir = fullfile(pwd, '../data/');

% noScenes = 12;
% dir  = 'D:/Oisin/GTFlowData/OpticalFlow/data/test/';
% opDir = 'D:/Oisin/GTFlowData/OpticalFlow/data/predictions/midTest/';

scenes_seq = [4 5 9 10 11 12 13 14 17 18 19];%[1:noScenes]

fvFile = 'fv'
%al = 'tv';%, 2 tv, 3 hs, 4 fl
flowError = 0.25;
sizeLimit = 7000;
for al = {'fl'}%{'ba', 'tv', 'hs', 'fl'}
    for testId = scenes_seq
        al = char(al);
        sequences = scenes_seq;
        %delete([opDir  al '/'  num2str(testId) '_Train.data']) % remove same named file if there is one
        fprintf(1, 'Creating data set for %s using sequence %d\n', al, testId);
        
        %% training data
        if (test == 0)
            fprintf(1, 'Creating training data for %d\n', testId);
            
%             sequences = scenes_seq;
%             sequences(sequences == testId) = [];
            for i = setdiff(scenes_seq, testId)
                fprintf(1, '\t... using data from sequence %d\n', i);
                
                load([dir num2str(i) '/' num2str(i)])
                load([dir num2str(i) '/' num2str(i) fvFile])
                
                % get error - get rid of reprojection error of other als - be carefull if you change feature vector
                if(al == 'ba')
                    [angBA errVal] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvBA(:,:,1), uvBA(:,:,2));
                    data(:, [42,43,44]) = [];
                elseif (al == 'tv')
                    [angTV errVal] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvTV(:,:,1), uvTV(:,:,2));
                    data(:, [41,43,44]) = [];
                elseif (al == 'hs')
                    [angHS errVal] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvHS(:,:,1), uvHS(:,:,2));
                    data(:, [41,42,44]) = [];
                elseif (al == 'fl')
                    [angFL errVal] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvFL(:,:,1), uvFL(:,:,2));
                    data(:, [41,42,43]) = [];
                end
                
                % labels - 0 if hard to flow, 1 otherwise
%                 labels = ~((errVal > flowError) | (mask == 0))';

                tuv = readFlowFile([dir num2str(i) '/1_2.flo']);
                mask = loadGTMask( tuv, 0 );
                labels = (mask == 0)';
                labels = labels(:);
                
                % want equal contribution from each class
                nonocclRegions = data(labels==0,:);
                occlRegions = data(labels==1,:);
                
                % shuffle
                amt  = min([size(nonocclRegions,1) size(occlRegions,1) sizeLimit]);
                
                shuff = randperm(size(nonocclRegions,1));
                nonocclRegions = nonocclRegions(shuff(1:amt),:);
                
                shuff = randperm(size(occlRegions,1));
                occlRegions = occlRegions(shuff(1:amt),:);
                
                %labelsComb = labels(shuff(1:sizeLimit));
                
                % write training data
                dlmwrite([opDir al '/' num2str(testId) '_Train.data'], [zeros(amt,1) nonocclRegions; ones(amt,1) occlRegions], '-append');
            end
        end
        
        %% test data
        fprintf(1, 'Creating test data for %d\n', testId);
        
        % write test data to file - left to right (row major order)
        load([dir num2str(testId) '/' num2str(testId)])
        load([dir num2str(testId) '/' num2str(testId) fvFile])
        if (test == 0)            
            if(al == 'ba')
                [angBA errVal] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvBA(:,:,1), uvBA(:,:,2));
                data(:, [42,43,44]) = [];
            elseif (al == 'tv')
                [angTV errVal] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvTV(:,:,1), uvTV(:,:,2));
                data(:, [41,43,44]) = [];
            elseif (al == 'hs')
                [angHS errVal] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvHS(:,:,1), uvHS(:,:,2));
                data(:, [41,42,44]) = [];
            elseif (al == 'fl')
                [angFL errVal] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvFL(:,:,1), uvFL(:,:,2));
                data(:, [41,42,43]) = [];
            end
            tuv = readFlowFile([dir num2str(testId) '/1_2.flo']);
            mask = loadGTMask( tuv, 0 );
            labels = (mask == 0)';
%             labels = ~((errVal > flowError) | (mask == 0))';
            labels = labels(:);
        else
            % No GT Labels
            labels = zeros(size(data,1),1);
            if(al == 'ba')
                data(:, [42,43,44]) = [];
            elseif (al == 'tv')
                data(:, [41,43,44]) = [];
            elseif (al == 'hs')
                data(:, [41,42,44]) = [];
            elseif (al == 'fl')
                data(:, [41,42,43]) = [];
            end
        end
        %dlmwrite([opDir al '/' num2str(testId) '_Test.data'], [labels data]);
        dlmwrite([opDir al '/' num2str(testId) '_Test.data'], [labels data]);
        
    end
end