function [ sub_dirs ] = addSubDirsToPath( main_dir )
%ADDSUBDIRSTOPATH Summary finds all the subdirectories in the path
%   recursively and adds them to the path (note it will not add main_dir to
%   the path). It also returns a ; separated list of all the directories
%   added

    % get all the sub-directories
    sub_dirs = genpath(main_dir);
    
    % remove the main_dir from sub_dirs
    idxs = strfind(sub_dirs, ';');
    if ~isempty(idxs)
        sub_dirs = sub_dirs(idxs(1)+1:end);
    end
    
    % add all sub directories to the path
    addpath(sub_dirs);
end

