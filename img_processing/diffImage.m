function [bsline_img,peak_stim_img,diff_img,fig_hands] = diffImage(recording,...
                                                                   exp_settings,...
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
%   Optional Inputs 
%   --------------- 
%   cmap : string or N x 3 array
%          specify colormap as string or N x 3 RGB array
%   include_plots : integer array
%                   Specify which plots to include, can include 1, 2, 3 in
%                   any order (1 - Baseline, 2 - Peak, 3 - Difference, 
%                   or 4 - Difference averaged across stimuli)
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
in.include_plots = [4]; % (1 - Baseline, 2 - Peak, 3 - Difference)
in.baseline_mode = 'mean'; % 'mean' or 'max' - metric to calculate on 
                           % baseline frames for bsline_img
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
in = sl.in.processVarargin(in,varargin);
if isa(recording,'Recording') && recording.loaded == 0
    recording.load(); 
end
if strcmp(in.baseline_mode,'mean')
    bsline_img = mean(recording.vals(:,:,exp_settings.baseline_wind_inds(:,1)),3); % use first stimulus if applied as train
elseif strcmp(in.baseline_mode,'max') || strcmp(in.baseline_mode,'peak')
    bsline_img = max(recording.vals(:,:,exp_settings.baseline_wind_inds(:,1)),[],3); % use first stimulus if applied as train
end
if exp_settings.num_stim > 0
    peak_stim_img = max(recording.vals(:,:,exp_settings.stim_wind_inds(:,1)),[],3);
else
    peak_stim_img = max(recording.vals,[],3); % peak across recording
end
if in.filt_width > 0
    bsline_img = imgaussfilt(bsline_img,in.filt_width); %,'FilterSize',filt_wind);
    peak_stim_img = imgaussfilt(peak_stim_img,in.filt_width); %,'FilterSize',filt_wind);    
end
% diff_img = (peak_stim_img-mean_bsline_img)./mean_bsline_img;
if any(in.include_plots == 4) && exp_settings.num_stim > 0
    diff_img = meanDiffImage(recording.vals,exp_settings.stim_vals,exp_settings.baseline_wind,...
                            exp_settings.stim_wind);
else
    diff_img = peak_stim_img-bsline_img;
end
if ~isempty(in.include_plots) && all(in.include_plots ~= 0)
    fig_hands = plotDiffImage(bsline_img,peak_stim_img,diff_img,recording.img_name,...
                   exp_settings,in);
else
    fig_hands = {}; 
end
end