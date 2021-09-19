%% Script to plot multiple trials across multiple conditions
data_fold = getDataFold();
exp_date= '20210917';
reporter = 'GluSnFR3';
dish = 'dish5';
conditions = {'control','1nM_DTX','5nM_DTX','50nM_DTX','wash'}; % ,'wash'             
positions = repmat({'Pos7'},1,length(conditions));
img_names = cell(1,length(conditions)); % use all images in condition folder
stim_vals = 3; % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.5; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
sampling_rate = 100; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
roi_set_filenames = [repmat({'RoiSet_pos7'},1,length(conditions)-1),'RoiSet2_pos7'];
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,['figs_',roi_set_filenames{1}]);       
% Optional settings
plot_settings = struct();
plot_settings.show_diff_image = []; % can include [1,2,3]
plot_settings.filt_width = 0;
plot_settings.funcs = {'baseline','deltaF_F0'};
plot_settings.roi_func_mode = 'combine';
plot_settings.save_processed_data = 1;
plot_settings.load_processed_data = 1;
plot_settings.save_fig = 1;
%% Plot trial data
out = plotTrials_multipleConditions(data_fold,exp_date,reporter,dish,...
                               conditions,positions,img_names,exp_settings,...
                               roi_set_filenames,...
                               plot_settings);
%% Plot summary data
plotDefaultSummaryStats(out.peaks_deltaF_F0_all,out.poststim_ints_all,out.peak_times_all,...
                         out.baselines_all,out.rel_times_cond_starts,...
                         conditions,exp_date,reporter,dish,plot_settings,...
                         summary_fig_dir)   