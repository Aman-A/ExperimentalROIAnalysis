function [bsline_img,peak_stim_img,diff_img,fig_hands] = diffImage(img,...
                                                                   exp_settings,...
                                                                   varargin)
%DIFFIMAGE Plots mean baseline, peak during stim window, and difference
%images
%  
%   Inputs 
%   ------ 
%   img : Recording object with 'vals' field (N x M x num_time_points
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
%                   any order (1 - Baseline, 2 - Peak, 3 - Difference)
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
in.include_plots = [3];
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
in.pixel_size = img.pixel_size*img.bin_size;
in = sl.in.processVarargin(in,varargin);
if isa(img,'Recording') && img.loaded == 0
    img.load(); 
end
if strcmp(in.baseline_mode,'mean')
    bsline_img = mean(img.vals(:,:,exp_settings.baseline_wind_inds(1,:)),3); % use first stimulus if applied as train
elseif strcmp(in.baseline_mode,'max') || strcmp(in.baseline_mode,'peak')
    bsline_img = max(img.vals(:,:,exp_settings.baseline_wind_inds(1,:)),[],3); % use first stimulus if applied as train
end
peak_stim_img = max(img.vals(:,:,exp_settings.stim_wind_inds(1,:)),[],3);
if in.filt_width > 0
    bsline_img = imgaussfilt(bsline_img,in.filt_width); %,'FilterSize',filt_wind);
    peak_stim_img = imgaussfilt(peak_stim_img,in.filt_width); %,'FilterSize',filt_wind);    
end
% diff_img = (peak_stim_img-mean_bsline_img)./mean_bsline_img;
diff_img = peak_stim_img-bsline_img;
if ~isempty(in.include_plots) && all(in.include_plots ~= 0)
    fig_hands = plotDiffImage(bsline_img,peak_stim_img,diff_img,img.img_name,...
                   exp_settings,in);
else
    fig_hands = {}; 
end
end