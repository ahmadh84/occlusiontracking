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
        
        USE_ONLY_OF;
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
            
            obj.USE_ONLY_OF = settings.USE_ONLY_OF;
            obj.unique_id = obj.comp_feat_vec.getUniqueID();
            obj.feature_depths = obj.comp_feat_vec.feature_depths;
            obj.feature_types = obj.comp_feat_vec.feature_types;
            
            % read in predicted file
            obj.classifier_out = textread(prediction_out_filepath, '%f');
            obj.classifier_out = reshape(obj.classifier_out, obj.comp_feat_vec.image_sz(2), obj.comp_feat_vec.image_sz(1))';   % need the transpose to read correctly
            
            % get all the info. from the console output of the classifier
            obj.manageConsoleOutput( classifier_console_out, settings );
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
            % ROC
            mask = obj.calc_flows.gt_mask;
            labels = (mask == 0);

            interval = [0:0.001:1];
            errorToTest = 1;
            i = 1;
            fpr = zeros(length(interval),1);
            tpr = zeros(length(interval),1);
            
            for t  = interval
                tmpC1 = obj.classifier_out >= t;
            %     tmpE1 = ((epe.*tmpC1)<errorToTest);

                tmpC2 = obj.classifier_out < t;
            %     tmpE2 = ((epe.*tmpC2)>=errorToTest);

                % compute the True/False Positive, True/False Negative
                tp = nnz( tmpC1 & labels );
                fp = nnz( tmpC1 & ~labels );
                tn = nnz( tmpC2 & ~labels );
                fn = nnz( tmpC2 & labels );

                fpr(i) = fp / (fp+tn);
                tpr(i) = tp / (tp+fn);
                i = i+1;
            end

            figure
            plot(fpr, tpr)
            for i=1:9    
               hold on; plot(fpr(1+i*100),tpr(1+i*100),'bo')
            end
            hold on;text(fpr(801)+0.02,tpr(801),'0.8', 'Color',[0 0 1])
            hold on;text(fpr(501)+0.02,tpr(501),'0.5', 'Color',[0 0 1])
            hold on;text(fpr(201)+0.02,tpr(201),'0.2', 'Color',[0 0 1])

            obj.area_under_roc = sum((fpr(1:end-1)-fpr(2:end)).*((tpr(1:end-1) + tpr(2:end)).*0.5));
            
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
        function manageConsoleOutput( obj, classifier_console_out, settings )
            print_from = 1;
            
            if str2num(settings.RF_GET_VAR_IMP)
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
            
            ext = regexp(remaining_str, '.*train err\s+((\d+\.)?\d+)\s*%\s+test err\s+((\d+\.)?\d+)\s*%', 'tokenExtents');
            if ~isempty(ext)
                obj.classifier_train_err = str2double(remaining_str(ext{1}(1,1):ext{1}(1,2)));
                obj.classifier_test_err = str2double(remaining_str(ext{1}(2,1):ext{1}(2,2)));
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
            
            if ~isempty(obj.USE_ONLY_OF)
                    filename = fullfile(obj.out_dir, 'result', [scene_id_tag '_' comp_feat_vec_id '_' obj.USE_ONLY_OF '_%s']);
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

