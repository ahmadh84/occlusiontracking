function gtflow_images( data_dir )
%GTFLOW_IMAGES generates color flow images in all the sub-directories (1
%   level deep) having flow and places them in the same sub-directory

    addpath('main_code/utils/flow-code-matlab');
    addpath('main_code');
    
    d = dir(data_dir);
    
    for no = 1:length(d)
        if d(no).isdir && ~strcmp(d(no).name, '.') && ~strcmp(d(no).name, '..')
            flow_filepath = fullfile(data_dir, d(no).name, CalcFlows.GT_FLOW_FILE);
            if exist(flow_filepath, 'file')
                fprintf(1, 'Printing image - %s\n', d(no).name);
                
                img = flowToColor(readFlowFile(flow_filepath));
                imwrite(img, fullfile(data_dir, d(no).name, sprintf('flow%s.png', d(no).name)));
            end
        end
    end
end
