function matching_file_names = getFilesWithinDir(filedir,formats,exclude_formats)
%GETIMAGESWITHINDIR Gets images within directory sorted by time of creation
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
% Includes files with .fits, .tiff, or .tif extension
% AUTHOR    : Aman Aberra 
if nargin < 3
    exclude_formats = {}; 
end
d = dir(filedir); 
file_names = {d.name};
creation_time = [d.datenum];
[~,inds] = sort(creation_time,'ascend');
file_names = file_names(inds);
formats = setdiff(formats,exclude_formats); 
[~,~,file_exts] = cellfun(@(x) fileparts(x),file_names,'UniformOutput',0);
is_ext = false(1,length(file_names));
for i = 1:length(formats)
    is_ext = is_ext | cellfun(@(x) strcmp(x,formats{i}),file_exts,'UniformOutput',1);
end
is_not_hidden = cellfun(@(x) ~strcmp(x(1),'.'),file_names,'UniformOutput',1);

matching_file_names = file_names(is_ext & is_not_hidden);

if isempty(matching_file_names)
    fprintf('No files with input extensions found in %s\n',filedir); 
end
end
