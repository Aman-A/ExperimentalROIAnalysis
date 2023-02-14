function [img_struct,fig_hands] = diffImage(recording,exp_settings,include_plots,...
                                    varargin)
%DIFFIMAGE Plots mean baseline, peak during stim window, and difference
%images
%  
%   Inputs 
%   ------ 
%   recording : Recording object with 'vals' field (N x M x num_time_points
%               z stack of image matrices)
%   exp_settings : object, instance of Settings class 
%              Imaging and stimulus settings, with fields:
%       stim_vals : vector of integers or doubles
%                frame/timepoints when stimulus was applied
%       stim_wind : integer or double
%                   window (frames or time length) in which to calculate
%                   peak after stimuli
%       baseline_wind : integer or double
%                   window (frames or time length) in which to calculate
%                   baseline before stimuli
%   include_plots : integer array
%                   Specify which plots to include, can include 1, 2, 3 in
%                   any order (1 - Baseline, 2 - Peak, 3 - Difference, 
%                   or 4 - Difference averaged across stimuli)
%   Optional Inputs 
%   --------------- 
%   cmap : string or N x 3 array
%          specify colormap as string or N x 3 RGB array
%   filt_width : double
%               width (std) of symmetric gaussian spatial filter, NOTE:
%               REQUIRES IMAGE PROCESSING TOOLBOX
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if nargin < 2
    exp_settings = ExperimentSettings(300,100,100,'frames',100);    
end
in.cmap = 'inferno';
in.baseline_mode = 'mean'; % 'mean' or 'max' - metric to calculate on 
                           % baseline frames for bsline_img
in.peak_mode = 'max'; % 'max' or 'mean' for peak_stim_img and meanDiffImage                           
in.filt_width = 0;
in.formats = {'png'};
in.resolutions = {'-r300'};
in.save_fig = 0;
in.fig_dir = './figs'; % default to current directory
in.fig_settings = {'Units','normalized','Position',[0 0.1667 0.75 0.744],...
                    'Color','k'};
in.cb_settings = {'Color','w','FontSize',14};
in.title_settings = {'Interpreter','none','Color','w'}; 
in.cax_mode = 'quantile'; % 'quantile', 'abs', or 'auto'
in.cax_lims = [0.02 0.998]; % color limits, units defined in cax_mode
in.pixel_size = recording.pixel_size*recording.bin_size;
in.indicator_dir = 1; % 1 = positive going, -1 = negative going
in = sl.in.processVarargin(in,varargin);
if isa(recording,'Recording') && recording.loaded == 0
    recording.load(); 
end
img_struct = struct(); % add imgs to struct
%% Compute baseline for bsline_img or diff_img/mean_diff_img
if strcmp(in.baseline_mode,'mean')
    bsline_img = mean(recording.vals(:,:,exp_settings.baseline_wind_inds(:,1)),3); % use first stimulus if applied as train
elseif strcmp(in.baseline_mode,'max') || strcmp(in.baseline_mode,'peak')
    bsline_img = max(recording.vals(:,:,exp_settings.baseline_wind_inds(:,1)),[],3); % use first stimulus if applied as train
end
if in.filt_width > 0
    bsline_img = imgaussfilt(bsline_img,in.filt_width); %,'FilterSize',filt_wind);        
end
img_struct.bsline_img = bsline_img; 

%% Compute peak or post-stim peak for peak_stim_img
if exp_settings.num_stim > 0 % use 1st stim timing if stim were applied
    if strcmp(in.peak_mode,'max')
        peak_stim_img = max(recording.vals(:,:,exp_settings.stim_wind_inds(:,1)),[],3);
    elseif strcmp(in.peak_mode,'mean')
        peak_stim_img = mean(recording.vals(:,:,exp_settings.stim_wind_inds(:,1)),3);
    elseif strcmp(in.peak_mode,'min')
        peak_stim_img = min(recording.vals(:,:,exp_settings.stim_wind_inds(:,1)),[],3);
    elseif isvector(in.peak_mode)
        peak_stim_img = mean(recording.vals(:,:,exp_settings.stim_wind_inds(in.peak_mode(1):in.peak_mode(end),1)),3);
    end
else
    peak_stim_img = max(recording.vals,[],3); % peak across recording
end
if in.filt_width > 0      
    peak_stim_img = imgaussfilt(peak_stim_img,in.filt_width); %,'FilterSize',filt_wind);
end
img_struct.peak_stim_img = peak_stim_img; 

%% Create peak - baseline image (diff_img)
diff_img = (peak_stim_img-bsline_img)*in.indicator_dir;
% diff_img = (peak_stim_img-mean_bsline_img)./mean_bsline_img;
% already filtered peak and bsline imgs, no need to refilter
img_struct.diff_img = diff_img; 

% Mean stim-evoked peak - baseline image
if exp_settings.num_stim > 0
    mean_diff_img = meanDiffImage(recording.vals,exp_settings.stim_vals,exp_settings.baseline_wind,...
                            exp_settings.stim_wind,in.peak_mode,in.indicator_dir);
    if in.filt_width > 0
        mean_diff_img = imgaussfilt(mean_diff_img,in.filt_width); %,'FilterSize',filt_wind);    
    end
    img_struct.mean_diff_img = mean_diff_img; 
end

if ~isempty(include_plots) && all(include_plots ~= 0)
    if ~isempty(recording.condition)
        img_name = [recording.condition '/' recording.img_name];
    else
        img_name = recording.img_name; 
    end
    fig_hands = plotDiffImage(img_struct,img_name,include_plots,exp_settings,in);
else
    fig_hands = {}; 
end
end