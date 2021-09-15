function [mean_bsline_img,peak_stim_img,diff_img] = diffImage(img,settings,...
                                                              cmap,include_plots,filt_width)
%DIFFIMAGE Plots mean baseline, peak during stim window, and difference
%images
%  
%   Inputs 
%   ------ 
%   img : Recording object with 'vals' field (N x M x num_time_points
%               z stack of image matrices)
%   settings : object, instance of Settings class 
%              Imaging and stimulus settings, with fields:
%       stim_vals : vector of integers or doubles
%                frame/timepoints when stimulus was applied
%       stim_wind : integer or double
%                   window (frames or time length) in which to calculate
%                   peak after stimuli
%       baseline_wind : integer or double
%                   window (frames or time length) in which to calculate
%                   baseline before stimuli
%   cmap : string or N x 3 array
%          specify colormap as string or N x 3 RGB array
%   include_plots : integer array
%                   Specify which plots to include, can include 1, 2, 3 in
%                   any order
%   filt_width : double
%               width (std) of symmetric gaussian spatial filter, NOTE:
%               REQUIRES IMAGE PROCESSING TOOLBOX
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if nargin < 2
    settings = Settings(300,100,100,'frames',100);    
end
if nargin < 3
   cmap = 'inferno'; % specify colormap as string or N x 3 RGB array
end
if nargin < 4
   include_plots = [3]; % include indices of plots 1: baseline,2: pk,3: pk-baseline 
end
if nargin < 5
   filt_width = 0; 
end

mean_bsline_img = mean(img.vals(:,:,settings.baseline_wind_inds),3); 
peak_stim_img = max(img.vals(:,:,settings.stim_wind_inds),[],3); 
if filt_width > 0
    mean_bsline_img = imgaussfilt(mean_bsline_img,filt_width); %,'FilterSize',filt_wind);
    peak_stim_img = imgaussfilt(peak_stim_img,filt_width); %,'FilterSize',filt_wind);
    filt_str = sprintf('filter window %g',filt_width);
else
    filt_str = 'filter off';
end
% diff_img = (peak_stim_img-mean_bsline_img)./mean_bsline_img;
diff_img = peak_stim_img-mean_bsline_img;
%% Plot
if any(include_plots==1) % Mean baseline image
    figure('Units','normalized','Position',[1 0.1667 0.75 0.744]); 
    % subplot(3,1,1);
    imagesc(mean_bsline_img); axis equal; axis off; colormap(cmap); colorbar;
    title(sprintf('%s: Mean baseline (frames %g to %g), %s',img.img_name,...
                    settings.baseline_wind_inds(1),settings.baseline_wind_inds(end),...
                    filt_str),'Interpreter','none'); 
end
if any(include_plots==2) % Peak image
    % subplot(3,1,2);
    figure('Units','normalized','Position',[1 0.1667 0.75 0.744]); 
    imagesc(peak_stim_img); axis equal; axis off; colormap(cmap); colorbar;
    title(sprintf('%s: Peak during stim (frames %g to %g), %s',img.img_name,...
                  settings.stim_wind_inds(1),settings.stim_wind_inds(end),filt_str),...
                  'Interpreter','none');
end
if any(include_plots==3) % Difference image
    % subplot(3,1,3); 
    figure('Units','normalized','Position',[1 0.1667 0.75 0.744]); 
    imagesc(diff_img); axis equal; axis off; colormap(cmap); colorbar;
    title(sprintf('%s: Peak - mean baseline, %s',img.img_name,filt_str),...
          'Interpreter','none'); 
    axis([0 size(diff_img,2) 0 size(diff_img,1)]); 
end
end