function makeExpDiffImageStack(exp_folder,trial_folders,exp_settings,varargin)
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
in.include_plots = 0; % same format as diffImage, 1 - baseline, 2 - peak, 
                      % 3 diff image, leave empty or set to 0 to skip 
                      % plotting
in.img_stack_name = 'diffimage_stack';     
in.img_mode = 'diff';
in = sl.in.processVarargin(in,varargin); 

img_names_all = cell(size(trial_folders)); 
for i = 1:length(trial_folders)    
    trial_folders{i} = fullfile(exp_folder,trial_folders{i}); % make full path 
    if isempty(img_names_all{i}) % assume all .fits files are relevant trial data
        img_names_all{i} = getImagesWithinDir(trial_folders{i});
    end
end
num_trials = sum(cellfun(@length,img_names_all));
% Load first image to get dimensions
full_path_to_img1 = fullfile(trial_folders{1},img_names_all{1}{1}); 
rec1 = Recording(full_path_to_img1); rec1.load();
[bsline_img1,pk_img1,diff_img1,~] = diffImage(rec1,exp_settings,'include_plots',...
                            in.include_plots);                         
img_stack = zeros(size(diff_img1,1),size(diff_img1,2),num_trials);
if strcmp(in.img_mode,'diff')
    img_stack(:,:,1) = diff_img1; 
elseif strcmp(in.img_mode,'peak')
   img_stack(:,:,1) = pk_img1; 
elseif strcmp(in.img_mode,'bsline')
    img_stack(:,:,1) = bsline_img1;
end
% Load rest of images 
trial_ind = 2;
% Load images and compute difference, specified by parameters in
% exp_settings
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
        [bsline_img,pk_img,diff_img,~] = diffImage(rec_ij,exp_settings,'include_plots',...
                                    in.include_plots); 
        if strcmp(in.img_mode,'diff')
            img_stack(:,:,trial_ind) = diff_img;
        elseif strcmp(in.img_mode,'peak')
            img_stack(:,:,trial_ind) = pk_img;
        elseif strcmp(in.img_mode,'bsline')
            img_stack(:,:,trial_ind) = bsline_img;
        end
        trial_ind = trial_ind + 1; 
    end
end
% Save image stack
path_to_diff_img_stack = fullfile(exp_folder,[in.img_stack_name '.fits']);
fitswrite(img_stack,path_to_diff_img_stack); 
fprintf('Wrote image stack to %s\n',path_to_diff_img_stack); 