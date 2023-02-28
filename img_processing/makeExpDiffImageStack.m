function img_stack = makeExpDiffImageStack(exp_folder,trial_folders,exp_settings,varargin)
%MAKEEXPDIFFIMAGESTACK Save fits image stack of diff images for set of trials 
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
in.include_plots = [0 4]; % same format as diffImage, 1 - baseline, 2 - peak, 
                      % 3 diff image, leave empty or set to 0 to skip 
                      % plotting
in.img_stack_name = 'diffimage_stack';     
in.img_names_all = cell(size(trial_folders)); 
in.save_sep_images = 0;
in.sep_images_dir = 'stack';
in = sl.in.processVarargin(in,varargin); 
% Format Experiment Settings
if length(exp_settings) == 1
    exp_settings = repmat(exp_settings,length(trial_folders),1); % convert to object array
else
    if iscell(exp_settings) % cell array of ExperimentSettings objects
        % convert to object array
        exp_settings = [exp_settings{:}];
    end
end
% Format file names
img_names_all = in.img_names_all; 
for i = 1:length(trial_folders)    
    trial_folders{i} = fullfile(exp_folder,trial_folders{i}); % make full path 
    if isempty(img_names_all{i}) % assume all .fits files are relevant trial data
        img_names_all{i} = getImagesWithinDir(trial_folders{i});
    elseif ischar(img_names_all{i})
        img_names_all{i} = img_names_all(i); 
    end
end
num_trials = sum(cellfun(@length,img_names_all));
% Load first image to get dimensions
if ischar(img_names_all{1})
   img_name1 = img_names_all{1};
else
   img_name1 = img_names_all{1}{1}; 
end
full_path_to_img1 = fullfile(trial_folders{1},img_name1); 
rec1 = Recording(full_path_to_img1); rec1.load();
assert(sum(in.include_plots > 0)  == 1,...
        'include_plots should include single plot to output')
[img_struct,~] = diffImage(rec1,exp_settings(1),in.include_plots);
img_fields = fieldnames(img_struct); 
img_field = img_fields{end}; % skip bsline_img if include_plots = 3 or 4
img1 = img_struct.(img_field); 
img_stack = zeros([size(img1,[1 2]),num_trials]);
img_stack(:,:,1) = img1; 

% Load rest of images 
trial_ind = 2;
% Load images and compute difference, specified by parameters in
% exp_settings
if in.save_sep_images
    sep_images_dir = fullfile(exp_folder,in.sep_images_dir); 
    if ~exist(sep_images_dir,'dir')
       mkdir(sep_images_dir); 
       fprintf('Made %s to save stack as separate image fils\n',sep_images_dir); 
    end
    fitswrite(img_stack(:,:,1),fullfile(sep_images_dir,['1_' img_name1]))
    imwrite(flipud(img_stack(:,:,1)/max(img_stack(:,:,1),[],'all')),...
                fullfile(sep_images_dir,['1_' img_name1(1:end-5) '.png']),'png')
end

for i = 1:length(trial_folders)    
    img_namesi = img_names_all{i};
    trial_folderi = trial_folders{i}; 
    if i == 1
        startj = 2; % skip first
    else
        startj = 1;
    end
    for j = startj:length(img_namesi)
        full_path_to_imgj = fullfile(trial_folderi,img_namesi{j}); 
        rec_ij = Recording(full_path_to_imgj); 
        rec_ij.load(); 
        [img_struct,~] = diffImage(rec_ij,exp_settings(i),in.include_plots); 
        img_stack(:,:,trial_ind)  = img_struct.(img_field);
        
        if in.save_sep_images
            path_to_img = fullfile(sep_images_dir,[num2str(i),'_',img_namesi{j}]); 
            fitswrite(img_stack(:,:,trial_ind),path_to_img);
            imwrite(flipud(img_stack(:,:,trial_ind)/max(img_stack(:,:,trial_ind),[],'all')),...
                [path_to_img(1:end-5) '.png'],'png')
        end
        trial_ind = trial_ind + 1; 
    end
end
% Save image stack
path_to_diff_img_stack = fullfile(exp_folder,[in.img_stack_name '.fits']);
fitswrite(img_stack,path_to_diff_img_stack); 
fprintf('Wrote image stack to %s\n',path_to_diff_img_stack); 