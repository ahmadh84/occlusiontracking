classdef AbstractLabel
    %ABSTRACTLABEL Feature used as labelling for training and testing the
    %   classifier
    
    properties (Abstract, Constant)
        LABEL_TYPE;
        LABEL_SHORT_TYPE;
        LABEL_IS_BINARY;
        LABEL_PURPOSE;
    end
    
    
    methods (Abstract)
        [ label data_idxs idxs_per_label ] = calcLabelTraining( obj, comp_feat_vec, MAX_MARKINGS_PER_LABEL, extra_label_info );
        
        [ labels ignore_labels ] = calcLabelWhole( obj, comp_feat_vec, extra_label_info );
    end
    
    
    methods
        function feature_no_id = returnNoID(obj)
        % creates unique feature number, good for storing with the file
        % name
        
            % create unique ID
            nos = uint8(obj.LABEL_SHORT_TYPE);
            nos = double(nos) .* ([1:length(nos)].^2);
            feature_no_id = sum(nos);
        end
    end
    
    
    methods (Static)
        function [ cluster_idxs ] = clusterFeatures(comp_feat_vec, num_clusters, pos_idxs)
            if ~exist('pos_idxs','var')
                pos_idxs = true(size(comp_feat_vec.features,1),1);
            end
            % normalize features
%             max_val = max(comp_feat_vec.features,[],1);
%             min_val = min(comp_feat_vec.features,[],1);
%             temp_f = bsxfun(@minus, comp_feat_vec.features, min_val);
%             temp_f = bsxfun(@times, temp_f, 1./(max_val - min_val));
            
            % bring to 0 mean and unit variance
            mean_vals = mean(comp_feat_vec.features(pos_idxs,:), 1);
            std_vals = std(comp_feat_vec.features(pos_idxs,:), 0, 1);
            temp_f = bsxfun(@minus, comp_feat_vec.features(pos_idxs,:), mean_vals);
            temp_f = bsxfun(@times, temp_f, 1./std_vals);

            start_kmeans = tic;
            fprintf(1, 'Clustering feature vector for sampling (%d clusters)\n', num_clusters);
            cluster_idxs = kmeansK(temp_f, num_clusters);
            fprintf(1, 'Clustering took %.1f secs\n', toc(start_kmeans));
        end
    end
    
end

