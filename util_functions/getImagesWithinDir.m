function img_names = getImagesWithinDir(filedir)
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
d = dir(filedir); 
file_names = {d.name};
creation_time = [d.datenum];
[~,inds] = sort(creation_time,'ascend');
file_names = file_names(inds);
[~,~,file_exts] = cellfun(@(x) fileparts(x),file_names,'UniformOutput',0);
is_fits = cellfun(@(x) strcmp(x,'.fits'),file_exts,'UniformOutput',1);
is_tif = cellfun(@(x) strcmp(x,'.tif'),file_exts,'UniformOutput',1);
is_tiff = cellfun(@(x) strcmp(x,'.tiff'),file_exts,'UniformOutput',1);
is_nd2 = cellfun(@(x) strcmp(x,'.nd2'),file_exts,'UniformOutput',1);
is_czi = cellfun(@(x) strcmp(x,'.czi'),file_exts,'UniformOutput',1);
is_not_hidden = cellfun(@(x) ~strcmp(x(1),'.'),file_names,'UniformOutput',1);
img_names = file_names((is_fits | is_tif | is_tiff | is_nd2 | is_czi) & is_not_hidden);
if isempty(img_names)
    fprintf('No image files found in %s\n',filedir); 
end
end
