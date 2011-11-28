classdef ClassifierOutputHandler < handle
    %CLASSIFIEROUTPUTHANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant, Transient)
        SAVE_OBJ_NAME = 'classifier_output';
    end
    
    
    properties
        out_dir;
        scene_id;
        unique_id;
        prediction_out_filepath;
        
        classifier_out;
        feature_importance = [];
        
        area_under_roc;
        max_f1_score_pr;
        max_f1_score_idx = -1;
        
        feature_depths;
        feature_types;
        classifier_train_err;
        classifier_test_err;
        
        feature_compute_times = [];
        flow_compute_times = [];
        extra_compute_times = {};
        
        tpr = [];
        fpr = [];
        precision = [];
        thresholds = 0:0.001:1;
        
        settings;
    end
    
    
    properties (Transient) 
        comp_feat_vec;
        calc_flows;
    end
    
    
    methods
        function obj = ClassifierOutputHandler( out_dir, scene_id, prediction_out_filepath, traintest_data, classifier_info, settings )
            obj.out_dir = out_dir;
            obj.scene_id = scene_id;
            [ obj.comp_feat_vec obj.calc_flows ] = traintest_data.getFeatureVecAndFlow(scene_id);
            
            obj.settings = settings;
            obj.unique_id = obj.comp_feat_vec.getUniqueID();
            obj.feature_depths = obj.comp_feat_vec.feature_depths;
            obj.feature_types = obj.comp_feat_vec.feature_types;
            
            obj.feature_compute_times = obj.comp_feat_vec.feature_compute_times;
            obj.flow_compute_times = obj.calc_flows.flow_compute_times;
            obj.extra_compute_times = [obj.extra_compute_times; {'extra_calcflows_time', obj.calc_flows.flow_extra_time}];
            obj.extra_compute_times = [obj.extra_compute_times; {'classifier_compute_time', classifier_info.classifier_time}];
            
            % read in predicted file
            obj.classifier_out = textread(prediction_out_filepath, '%f');
            obj.classifier_out = reshape(obj.classifier_out, obj.comp_feat_vec.image_sz(2), obj.comp_feat_vec.image_sz(1))';   % need the transpose to read correctly
            
            % get all the info. from the console output of the classifier
            obj.manageConsoleOutput( classifier_info.classifier_console_out );
            
            % get the ROC statistics
            obj.computeROCPR();
        end
        
        
        function saveObject( obj )
            mat_filepath = obj.getSavingFilename();
            
            fprintf('--> Saving ClassifierOutputHandler object to %s\n', mat_filepath);
            eval([ClassifierOutputHandler.SAVE_OBJ_NAME ' = obj;']);
            save(mat_filepath, ClassifierOutputHandler.SAVE_OBJ_NAME);
        end
        
        
        function printPosteriorImage( obj )
            figure
            
            % if the label is binary, than we will have a posterior
            if obj.settings.label_obj.LABEL_IS_BINARY
                imshow(obj.classifier_out);
                colormap summer;
            else
                imagesc(obj.classifier_out);
                
                % find number of labels
                mc = metaclass(obj.settings.label_obj);
                if any(cellfun(@(x) strcmp(x.Name, 'label_names'), mc.Properties))
                    no_labels = length(obj.settings.label_obj.label_names);
                else
                    no_labels = max(max(obj.classifier_out));
                end
                
                % create colormap
                colormap(jet(no_labels));
                clrb_h = colorbar('location','east', 'YTick',linspace(1 + ((no_labels-1)/no_labels)/2, no_labels - ((no_labels-1)/no_labels)/2, no_labels), 'YLim',[1 no_labels], 'YTickLabel',obj.settings.label_obj.label_names);
                pos = get(clrb_h, 'Position');
                set(clrb_h, 'Position',[0.9 0.65 0.05 0.3], 'YColor',[0 0 0], 'FontWeight','bold');
            end
            set(gcf, 'units', 'pixels', 'position', [100 100 obj.comp_feat_vec.image_sz(2) obj.comp_feat_vec.image_sz(1)], 'paperpositionmode', 'auto');
            set(gca, 'position', [0 0 1 1], 'visible', 'off');
            
            posterior_filepath = obj.getPosteriorImageFilename();
            print('-dpng', '-r0', posterior_filepath);
        end
        
        
        function printROCCurve( obj )
            % if the label wasnt binary, skip this
            if ~obj.settings.label_obj.LABEL_IS_BINARY
                return;
            end
            
            % print to new figure
            figure
            plot(obj.fpr, obj.tpr);
            hold on;
            
            if ~isempty(obj.fpr)
                for i=0.1:0.1:0.9
                    plot(obj.fpr(obj.thresholds==i), obj.tpr(obj.thresholds==i), 'bo');
                end

                text(obj.fpr(obj.thresholds==0.8)+0.02, obj.tpr(obj.thresholds==0.8), '0.8', 'Color',[0 0 1]);
                text(obj.fpr(obj.thresholds==0.5)+0.02, obj.tpr(obj.thresholds==0.5), '0.5', 'Color',[0 0 1]);
                text(obj.fpr(obj.thresholds==0.2)+0.02, obj.tpr(obj.thresholds==0.2), '0.2', 'Color',[0 0 1]);
            end
            
            title(sprintf('ROC of %s - Area under ROC %.4f', obj.settings.label_obj.LABEL_PURPOSE, obj.area_under_roc));
            line([0;1], [0;1], 'Color', [0.7 0.7 0.7], 'LineStyle','--', 'LineWidth', 1.5);     % draw the line of no-discrimination
            
            xlabel('FPR');
            ylabel('TPR');
            roc_filepath = obj.getROCPlotFilename();
            print('-depsc', '-r0', roc_filepath);
        end
        
        
        function printPRCurve( obj )
            % if the label wasnt binary, skip this
            if ~obj.settings.label_obj.LABEL_IS_BINARY
                return;
            end
            
            recall = obj.tpr;
            
            % print to new figure
            figure
            plot(recall, obj.precision);
            hold on;
            
            if ~isempty(obj.precision)
                for i=0.1:0.1:0.9
                    plot(recall(obj.thresholds==i), obj.precision(obj.thresholds==i), 'bo');
                end

                text(recall(obj.thresholds==0.8)+0.02, obj.precision(obj.thresholds==0.8), '0.8', 'Color',[0 0 1]);
                text(recall(obj.thresholds==0.5)+0.02, obj.precision(obj.thresholds==0.5), '0.5', 'Color',[0 0 1]);
                text(recall(obj.thresholds==0.2)+0.02, obj.precision(obj.thresholds==0.2), '0.2', 'Color',[0 0 1]);
            end
            
            % mark the optimal F1 score point
            if obj.max_f1_score_idx ~= -1
                plot(recall(obj.max_f1_score_idx), obj.precision(obj.max_f1_score_idx), 'rx', 'MarkerSize',8, 'LineWidth',1.5);
            end
            
            set(gca, 'XLim',[0 1], 'YLim',[0 1]);
            
            title(sprintf('PR of %s - Maximum F1 score %.4f (marked on graph)', obj.settings.label_obj.LABEL_PURPOSE, obj.max_f1_score_pr));
            
            xlabel('Recall');
            ylabel('Precision');
            pr_filepath = obj.getPRPlotFilename();
            print('-depsc', '-r0', pr_filepath);
        end
        
        
        function printRFFeatureImp( obj )
            % in case the feature imp wasn't computed
            if isempty(obj.feature_importance) || ~str2num(obj.settings.RF_GET_VAR_IMP)
                return;
            end
            
            figure, plot(obj.feature_importance);
            h = get(gca);
            hold on;
            
            feature_divs = [ 0 cumsum(obj.feature_depths) ] + 0.5;
            
            for feature_idx = 1:length(feature_divs)-1
                x_axis_1 = feature_divs(feature_idx);
                x_axis_2 = feature_divs(feature_idx+1);
                
                plot([x_axis_2; x_axis_2], [0; h.YLim(2)], 'Color', [0.6 0.6 0.6], 'LineStyle','--');
                text((x_axis_1+x_axis_2)/2, h.YLim(2)*0.95, obj.feature_types{feature_idx}, ...
                    'Color', [0.6 0.6 0.6], 'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
            end
            
            title('Importance of individual features as given by Random Forest classifier');
            xlabel('Feature no.');
            ylabel('Feature importance %');
            imp_filepath = obj.getRFFeatureFilename();
            print('-depsc', '-r0', imp_filepath);
        end
        

        function [ optimal_th optimal_th2 ] = getOptimalThreshold( obj )
        % gets the threshold which gives the closest point to the (0,1)
        % point on the ROC
        
            dist_perfect = obj.fpr.^2 + (obj.tpr-1).^2;
            [val idx] = min(dist_perfect);
            mean_idx = round(mean(find(dist_perfect == val)));
            optimal_th2 = obj.thresholds(mean_idx);
            
            % min||(0,1)-(FPR,TPR)||
            % FPR dFPR/dT = (TPR-1) dTPR/dT
            tmp1 = obj.fpr.*gradient(obj.fpr, obj.thresholds);
            tmp2 = (obj.tpr-1).*gradient(obj.tpr, obj.thresholds);
            [val, idx] = min(abs(tmp1 - tmp2));
    
            optimal_th = obj.thresholds(idx);
        end
        
        
        function filename = getPosteriorImageFilename( obj )
            filename = sprintf(regexprep(obj.getUniqueObjFilename(), '\', '/'), 'posterior');
            filename = regexprep(filename, '/', filesep);
        end


        function filename = getROCPlotFilename( obj )
            filename = sprintf(regexprep(obj.getUniqueObjFilename(), '\', '/'), 'roc');
            filename = regexprep(filename, '/', filesep);
        end
        

        function filename = getPRPlotFilename( obj )
            filename = sprintf(regexprep(obj.getUniqueObjFilename(), '\', '/'), 'pr');
            filename = regexprep(filename, '/', filesep);
        end
        
        
        function filename = getRFFeatureFilename( obj )
            filename = sprintf(regexprep(obj.getUniqueObjFilename(), '\', '/'), 'rffeatureimp');
            filename = regexprep(filename, '/', filesep);
        end
        
        
        function filename = getSavingFilename( obj )
            filename = [sprintf(regexprep(obj.getUniqueObjFilename(), '\', '/'), 'rffeatureimp') '.mat'];
            filename = regexprep(filename, '/', filesep);
        end
        
    end
    
    
    methods (Access = private)    
        function manageConsoleOutput( obj, classifier_console_out )
            print_from = 1;
            
            if str2num(obj.settings.RF_GET_VAR_IMP)
                ext = regexp(classifier_console_out, '\d+\s+((\d+\.)?\d+)\s*[\f\n\r]', 'tokenExtents');
                obj.feature_importance = zeros(length(ext), 1);
                for ext_idx = 1:length(ext)
                    obj.feature_importance(ext_idx) = str2double( classifier_console_out(ext{ext_idx}(1):ext{ext_idx}(2)) );
                end
                print_from = ext{length(ext)}(2) + 1;
            end
            
            remaining_str = classifier_console_out(print_from:end);
            
            % printout everything else
            fprintf(1, '%s\n', remaining_str);
            
            ext = regexp(remaining_str, '.*train err\s+(-?(?:\d+\.)?\d+)\s*%\s+test err\s+(-?(?:\d+\.)?\d+)\s*%', 'tokenExtents');
            if ~isempty(ext)
                obj.classifier_train_err = str2double(remaining_str(ext{1}(1,1):ext{1}(1,2)));
                obj.classifier_test_err = str2double(remaining_str(ext{1}(2,1):ext{1}(2,2)));
            end
        end
        
        
        function computeROCPR( obj )
            % computes the TPR and FPR at different thresholds (given by
            % obj.thresholds). Also computes the Area under the curve for
            % ROC
            
            % if the label wasnt binary, skip this
            if ~obj.settings.label_obj.LABEL_IS_BINARY
                return;
            end
            
            % get and adjust extra info and feature vector
            extra_label_info.calc_flows = obj.calc_flows;
            [ obj.comp_feat_vec extra_label_info ] = ComputeTrainTestData.adjustFeaturesInfo(obj.comp_feat_vec, obj.calc_flows, extra_label_info, obj.settings, isempty(obj.calc_flows.gt_mask));
            
            [ labels ignore_labels ] = obj.settings.label_obj.calcLabelWhole( obj.comp_feat_vec, extra_label_info );
            
            if isempty(labels)
                return;
            end
            
            % remove labels which we are unsure about
            labels(ignore_labels) = [];
            
            not_labels = ~labels;
            
            % get the number of positives and negatives
            T = nnz(labels);
            N = nnz(~labels);
            
            obj.fpr = zeros(length(obj.thresholds),1);          % fall-out
            obj.tpr = zeros(length(obj.thresholds),1);          % recall / Hit-rate / sensitivity
            obj.precision = zeros(length(obj.thresholds),1);    % positive predictive value (PPV)
    
            temp_classifier_out = obj.classifier_out';
            temp_classifier_out = temp_classifier_out(:);
            
            % remove classifier output which we are unsure about
            temp_classifier_out(ignore_labels) = [];
            
            for idx = 1:length(obj.thresholds)
                tmpC1 = temp_classifier_out >= obj.thresholds(idx);
%                 tmpE1 = ((epe.*tmpC1)<errorToTest);

%                 tmpC2 = ~tmpC1;
%                 tmpE2 = ((epe.*tmpC2)>=errorToTest);

                % compute the True/False Positive, True/False Negative
                tp = nnz( tmpC1 & labels );
                fn = T - tp;
                fp = nnz( tmpC1 & not_labels );
                tn = N - fp;

                obj.fpr(idx) = fp / (fp+tn);
                obj.tpr(idx) = tp / (tp+fn);
                obj.precision(idx) = tp / (tp+fp);
            end
            
            % compute the area under the curve
            obj.area_under_roc = sum((obj.fpr(1:end-1)-obj.fpr(2:end)).*((obj.tpr(1:end-1) + obj.tpr(2:end)).*0.5));
            
            % compute F1 score at all operating points
            f1_scores = 2 * (obj.precision .* obj.tpr) ./ (obj.precision + obj.tpr);
            obj.max_f1_score_pr = max(f1_scores);
            found_idx = find(f1_scores == obj.max_f1_score_pr);
            if ~isempty(found_idx)
                obj.max_f1_score_idx = found_idx(round(length(found_idx)/2));
            end
        end
        
        
        function filename = getUniqueObjFilename( obj )
            scene_id_tag = obj.scene_id;
            if isnumeric(scene_id_tag)
                scene_id_tag = num2str(scene_id_tag);
            end
            comp_feat_vec_id = obj.unique_id;
            if isnumeric(comp_feat_vec_id)
                comp_feat_vec_id = num2str(comp_feat_vec_id);
            end
            
            if ~isempty(obj.settings.USE_ONLY_OF)
                    filename = fullfile(obj.out_dir, 'result', [scene_id_tag '_' comp_feat_vec_id '_' obj.settings.USE_ONLY_OF '_%s']);
            else
                filename = fullfile(obj.out_dir, 'result', [scene_id_tag '_' comp_feat_vec_id '_%s']);
            end
            
            d = fileparts(filename);
            if ~exist(d, 'dir')
                mkdir(d);
            end
        end
    end
    
end

