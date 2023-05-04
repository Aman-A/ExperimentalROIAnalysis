%% Estimate quantal content on single experiment
% Experiment should consist of 1 or multiple recordings from same set of
% boutons
data_dir = '/Volumes/LM/project quantum bipolar/230411.2/GluSnFR evoked';
% list of recording files, include extension if .tiff
% rec_names = {'GluSnFR3(2).tif','GluSnFR3(4).tif','GluSnFR3(6).tif'};  
rec_names = {'GluSnFR3(2).tif'};

% list of ROIset files (.zip if generated in ImageJ)
% Should be in same directory as recording files
roiset_files = {'RoiSetEvoked.zip','RoiSetEvoked.zip','RoiSetEvoked.zip'}; 
% Experiment/imaging settings
sampling_rate = 50; % Hz
% stimulus settings
delay = 0; % delay of start of stimulus train (sec)
freq = 2; % frequency of stimuli (Hz)
dur = 26; % duration of stimulus train (sec)
stim_times = defineStimTrain(delay,freq,dur);  % check that number of stimuli match what you expect!
stim_wind = 0.2; % sec to analyze after each stim 
baseline_wind = 0.1; % sec for baseline window 
units = 'sec'; % 'sec' or 'frames'
exp_settings = ExperimentSettings(stim_times,stim_wind,baseline_wind,units,sampling_rate); %%
%% Settings for histogram fitting function, estimateQuantalContentRecs
opts = struct();
opts.data_dir = data_dir;
opts.plot_func = 'deltaF_F0'; % set to 'deltaF_F0' to plot full fluorescence traces
                              % or 'deltaF_F0_aligned' to plot stimulus
                              % averaged traces
                              % or '' or 'none' to skip

opts.show_diff_image = [4]; % change to [4] to show mean deltaF image for each trial, [0] to skip
opts.load_processed_data = 1; % load if already processed data exists
opts.save_processed_data = 1; % save processed data (extracted deltaF/F traces) 
                              % for faster analysis
opts.save_figs = 2; % set to 2 to save figures, 1 to just plot summary
opts.std_threshold = 0; % threshold to consider peak success vs. failure, 
                      % defined as multiple of std of local baseline for
                      % each stimulus, i.e. peak > 4 x std(baseline) is
                      % success for in.std_threshold = 4. 
                      % Set to 0 to fit histogram to all peaks
opts.min_width = 0; % minimum FWHM of events to consider success, set to 0 
                    % include all peaks regardless of width
% Histogram fitting parameters
opts.plot_fits = 1; % Plot histograms for all ROIs
opts.lw = 2;      % line width of the fit in plots
opts.N_bootstrap = 1e6; % number of bootstrap events
opts.alpha = 1.5; % scaling factor for STD of fluorescence signals to generate bootstrapped events
              % Higher alpha gives larger spread for a given signal
              % variance
opts.num_bins_per_std_B = 4.5; % Number of histogram bins scaled by STD of fluorescence signals
opts.Multi_Gauss_threshold = 6; % minimum number of events to try multi gaussian fitting
opts.alpha_fit_dx = 0.005; % step size for test normalization values
opts.dx = 0.001; % fit function x step
opts.smooth_bs_dist = 1; % smooth bootstrapped peak distributions with 5 point moving average
opts.include_sat_param = 0; % include parameter for saturation of indicator at higher quanta
opts.n_G = 2; % number of Gaussians to attempt to fit
opts.roi_func_fig_size = [33 24];
[params_gaussian_all,peaks_rois_successes_all,Pr] = ...
                        estimateQuantalContentRecs(rec_names,roiset_files,...
                                                    exp_settings,opts);
if opts.save_figs
    printFig(gcf,sprintf('figs_%s',roiset_files{1}),sprintf('hist_n%g',length(rec_names)))

end

%% Interpreting output
% params_gaussian_all is a num_rois x 5 or 6 array of best fit parameters for
% multigaussian function fit to the peaks from each roi
%
% If opts.include_sat_param = 0, the function is:
% y = A1*exp(-(x - mu)^2/(2*(noise^2 + sigma^2)) + 
%     A2*exp(-(x - 2*mu)^2/(2*(noise^2 + sigma^2)) + 
%     A3*exp(-(x - 3*mu)^2/(2*(noise^2 + sigma^2)) 
% A1,A2,A3 are heights of each histogram peak
% mu would be the size of a single quantum
% sigma is the width of each peak
% noise is a noise factor dervied from the fluorescence trace
% so in params_gaussian_all this would be:
% [A1,A2,A3,mu,sigma; parameters for ROI 1
%  A1,A2,A3,mu,sigma; parameters for ROI 2
% ...
% A1,A2,A3,mu,sigma] parameters for last ROI
% If opts.include_sat_param = 1, a saturation factor (sat) is added to account
% for indicator saturation causing decreasing (sub-linear) mean values with 
% increasing quantal content
% y = A1*exp(-(x - mu)^2/(2*(noise^2 + sigma^2)) + 
%     A2*exp(-(x - mu - mu*sat)^2/(2*(noise^2 + sigma^2)) + 
%     A3*exp(-(x - mu - mu*sat - mu*sat^2)^2/(2*(noise^2 + sigma^2)) 
% and params_gaussian_all:
% [A1,A2,A3,mu,sigma,sat; parameters for ROI 1
%  A1,A2,A3,mu,sigma,sat; parameters for ROI 2
% ...
% A1,A2,A3,mu,sigma,sat] parameters for last ROI
%
% peaks_rois_successes_all is a num_rois x 1 cell array where each element is a vector
% of all the peaks from that ROI
% if you set std_thresh or min_width > 0, this is peaks of only the "successful"
% release events, otherwise it's all the peaks
% Pr is an estimate of Pr based on the std_thresh/min_width you set, if
% these were set to zero you can ignore this