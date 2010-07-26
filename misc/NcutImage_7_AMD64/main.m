function main;
% main;
% 
% Initializes matlab paths to subfolders
% Timothee Cour, Stella Yu, Jianbo Shi, 2004.

files = dir(cd);
for i=1:length(files)
    if files(i).isdir & strcmp(files(i).name,'.') == 0  && strcmp(files(i).name,'..') == 0
        addpath([cd '/' files(i).name]);
    end
end
