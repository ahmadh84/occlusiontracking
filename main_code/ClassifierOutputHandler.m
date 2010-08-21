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
        feature_depths;
        feature_types;
        classifier_train_err;
        classifier_test_err;
        
        tpr = [];
        fpr = [];
        thresholds = 0:0.001:1;
        
        settings;
    end
    
    
    properties (Transient) 
        comp_feat_vec;
        calc_flows;
    end
    
    
    methods
        function obj = ClassifierOutputHandler( out_dir, scene_id, prediction_out_filepath, traintest_data, classifier_console_out, settings )
            obj.out_dir = out_dir;
            obj.scene_id = scene_id;
            [ obj.comp_feat_vec obj.calc_flows ] = traintest_data.getFeatureVecAndFlow(scene_id);
            
            obj.settings = settings;
            obj.unique_id = obj.comp_feat_vec.getUniqueID();
            obj.feature_depths = obj.comp_feat_vec.feature_depths;
            obj.feature_types = obj.comp_feat_vec.feature_types;
            
            % read in predicted file
            obj.classifier_out = textread(prediction_out_filepath, '%f');
            obj.classifier_out = reshape(obj.classifier_out, obj.comp_feat_vec.image_sz(2), obj.comp_feat_vec.image_sz(1))';   % need the transpose to read correctly
            
            % get all the info. from the console output of the classifier
            obj.manageConsoleOutput( classifier_console_out );
            
            % get the ROC statistics
            obj.computeROC();
        end
        
        
        function saveObject( obj )
            mat_filepath = obj.getSavingFilename();
            
            fprintf('--> Saving ClassifierOutputHandler object to %s\n', mat_filepath);
            eval([ClassifierOutputHandler.SAVE_OBJ_NAME ' = obj;']);
            save(mat_filepath, ClassifierOutputHandler.SAVE_OBJ_NAME);
        end
        
        
        function printPosteriorImage( obj )
            figure, imshow(obj.classifier_out);
            colormap summer;
            set(gcf, 'units', 'pixels', 'position', [100 100 obj.comp_feat_vec.image_sz(2) obj.comp_feat_vec.image_sz(1)], 'paperpositionmode', 'auto');
            set(gca, 'position', [0 0 1 1], 'visible', 'off');
            
            posterior_filepath = obj.getPosteriorImageFilename();
            print('-dpng', '-r0', posterior_filepath);
        end
        
        
        function printROCCurve( obj )
            % print to new figure
            figure
            plot(obj.fpr, obj.tpr);
            hold on;
            
            for i=0.1:0.1:0.9
                plot(obj.fpr(obj.thresholds==i), obj.tpr(obj.thresholds==i), 'bo');
            end
            
            text(obj.fpr(obj.thresholds==0.8)+0.02, obj.tpr(obj.thresholds==0.8), '0.8', 'Color',[0 0 1]);
            text(obj.fpr(obj.thresholds==0.5)+0.02, obj.tpr(obj.thresholds==0.5), '0.5', 'Color',[0 0 1]);
            text(obj.fpr(obj.thresholds==0.2)+0.02, obj.tpr(obj.thresholds==0.2), '0.2', 'Color',[0 0 1]);
            
            title(sprintf('ROC of Occlusion Region detection - Area under ROC %.4f', obj.area_under_roc));
            line([0;1], [0;1], 'Color', [0.7 0.7 0.7], 'LineStyle','--', 'LineWidth', 1.5);     % draw the line of no-discrimination
            
            xlabel('FPR');
            ylabel('TPR');
            roc_filepath = obj.getROCPlotFilename();
            print('-depsc', '-r0', roc_filepath);
        end
        
        
        function printRFFeatureImp( obj )
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
        

        function [ optimal_th ] = getOptimalThreshold( obj )
        % gets the threshold which gives the closest point to the (0,1)
        % point on the ROC
        
            % min||(0,1)-(FPR,TPR)||
            % FPR dFPR/dT = (TPR-1) dTPR/dT
            tmp1 = obj.fpr.*gradient(obj.fpr, obj.thresholds);
            tmp2 = (obj.tpr-1).*gradient(obj.tpr, obj.thresholds);
            [val, idx] = min(abs(tmp1 - tmp2));
    
            optimal_th = obj.thresholds(idx);
        end
        
        
        function filename = getPosteriorImageFilename( obj )
            filename = sprintf(regexprep(obj.getUniqueObjFilename(), '\', '/'), 'posterior');
            filename = regexprep(filename, '/', '\');
        end


        function filename = getROCPlotFilename( obj )
            filename = sprintf(regexprep(obj.getUniqueObjFilename(), '\', '/'), 'roc');
            filename = regexprep(filename, '/', '\');
        end
        
        
        function filename = getRFFeatureFilename( obj )
            filename = sprintf(regexprep(obj.getUniqueObjFilename(), '\', '/'), 'rffeatureimp');
            filename = regexprep(filename, '/', '\');
        end
        
        
        function filename = getSavingFilename( obj )
            filename = [sprintf(regexprep(obj.getUniqueObjFilename(), '\', '/'), 'rffeatureimp') '.mat'];
            filename = regexprep(filename, '/', '\');
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
        
        
        function computeROC( obj )
            % computes the TPR and FPR at different thresholds (given by
            % obj.thresholds). Also computes the Area under the curve for
            % ROC
            
            extra_label_info.calc_flows = obj.calc_flows;
            [ labels ignore_labels ] = obj.settings.label_obj.calcLabelWhole( obj.comp_feat_vec, extra_label_info );
            
            % remove labels which we are unsure about
            labels(ignore_labels) = [];
            
            not_labels = ~labels;
            
            % get the number of positives and negatives
            T = nnz(labels);
            N = nnz(~labels);
            
            obj.fpr = zeros(length(obj.thresholds),1);
            obj.tpr = zeros(length(obj.thresholds),1);
            
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
            end
            
            % compute the area under the curve
            obj.area_under_roc = sum((obj.fpr(1:end-1)-obj.fpr(2:end)).*((obj.tpr(1:end-1) + obj.tpr(2:end)).*0.5));
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

