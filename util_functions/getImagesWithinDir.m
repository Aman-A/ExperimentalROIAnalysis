function img_names = getImagesWithinDir(filedir,ignore_mot_corr,exclude_formats)
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
if nargin < 2
    ignore_mot_corr = 1; % ignore files with _motcorr_ in name, typically 
                         % corresponds to motion corrected recordings in same folder
end
if nargin < 3
    exclude_formats = {}; 
end
d = dir(filedir); 
file_names = {d.name};
creation_time = [d.datenum];
[~,inds] = sort(creation_time,'ascend');
file_names = file_names(inds);
formats = {'.fits','.tif','.tiff','.nd2','.czi'};
formats = setdiff(formats,exclude_formats); 
[~,~,file_exts] = cellfun(@(x) fileparts(x),file_names,'UniformOutput',0);
is_img = false(1,length(file_names));
for i = 1:length(formats)
    is_img = is_img | cellfun(@(x) strcmp(x,formats{i}),file_exts,'UniformOutput',1);
end
% is_fits = cellfun(@(x) strcmp(x,'.fits'),file_exts,'UniformOutput',1);
% is_tif = cellfun(@(x) strcmp(x,'.tif'),file_exts,'UniformOutput',1);
% is_tiff = cellfun(@(x) strcmp(x,'.tiff'),file_exts,'UniformOutput',1);
% is_nd2 = cellfun(@(x) strcmp(x,'.nd2'),file_exts,'UniformOutput',1);
% is_czi = cellfun(@(x) strcmp(x,'.czi'),file_exts,'UniformOutput',1);
is_not_hidden = cellfun(@(x) ~strcmp(x(1),'.'),file_names,'UniformOutput',1);

img_names = file_names(is_img & is_not_hidden);
if ignore_mot_corr
    img_names = img_names(~contains(img_names,'_motcorr'));    
end
if isempty(img_names)
    fprintf('No image files found in %s\n',filedir); 
end
end
