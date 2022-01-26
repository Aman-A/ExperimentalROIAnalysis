function data_fold = getDataFold()
%GETDATAFOLD Reads data_fold_<username>.txt for data folder on this
%computer

%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if isunix
    username = getenv('USER');
elseif ispc
    [~,username]=dos('echo %USERNAME%');
    username = strtrim(username); 
end
current_dir =  fileparts(which('getDataFold.m'));
data_fold_filename = sprintf('data_fold-%s.txt',username); 
data_fold_file = fullfile(current_dir,data_fold_filename);
if exist(data_fold_file,'file')
    fid = fopen(data_fold_file);
    data_fold = fscanf(fid,'%s');
    fclose(fid);
else
    error('Need to create %s containing path to top level data folder',data_fold_file); 
end
end

