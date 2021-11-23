%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = getDataFold();
exp_date= '20211005';
reporter = 'GluSnFR3';
dish = 'dish1';
condition = 'control'; % 'control', '5nM_DTX', '50nM_DTX'
position = 'PosX'; 
img_name = 'control.fits'; 
stim_vals = 3; % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.5; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 200; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
roi_set_filename = 'RoiSet_pc_posX.zip'; 
% Optional settings
plot_settings = struct();
plot_settings.show_diff_image = [3]; % can include [1,2,3]
plot_settings.filt_width = 0;
plot_settings.funcs = {'mean','baseline','deltaF_F0'};
plot_settings.roi_func_mode = 'combine'; % 'combine' or 'separate'
plot_settings.save_processed_data = 1;
plot_settings.load_processed_data = 0;
plot_settings.save_fig = 0;
plot_settings.y_lim = [-0.2 1.4];
plot_settings.x_lim = [-0.2 1.5]; 
plot_settings.recenterROIs = 0;
plot_settings.plot_func = 'deltaF_F0'; % 'deltaF_F0'
plot_settings.transform_type = 'displace'; % 'none' or 'displace'
plot_settings.registration_rec = fullfile(data_fold,exp_date,reporter,dish,'control',...
                               'control.fits'); 
plot_settings.show_roi_labels = 1;  
plot_settings.close_img_after_save = 0;
%%
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(data_fold,exp_date,reporter,dish,condition,position,...
                   img_name,exp_settings,roi_set_filename,...
                   trace_axis,plot_settings);
%% Plot multiple trials, same condition
condition = 'control'; % 'control', '5nM_DTX', '50nM_DTX'
img_names = {}; % use all images in condition folder
trials_data = plotTrials(data_fold,exp_date,reporter,dish,condition,position,img_names,...
                exp_settings,roi_set_filename,plot_settings);
%% Plot multiple trials, multiple conditions       
conditions = {'control','10nM_DTX'}; 
% conditions = {'control','10nM_DTX','50nM_DTX','100nM_DTX','wash'}; % ,'wash'             
positions = repmat({position},1,length(conditions));
img_names = cell(1,length(conditions)); % use all images in condition folder
roi_set_filenames = [repmat({roi_set_filename},1,length(conditions))];
plot_settings.transform_type = 'displace'; % coregister and get displacement field 
plot_settings.registration_rec = fullfile(data_fold,exp_date,reporter,dish,'control',...
                               'control.fits'); 
out = plotTrials_multipleConditions(data_fold,exp_date,reporter,dish,...
                               conditions,positions,img_names,exp_settings,...
                               roi_set_filenames,...
                               plot_settings);
%% Plot summary data
plot_inds = [1,2,3,4];
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,['figs_',roi_set_filenames{1}]);       
plotDefaultSummaryStats(out.peaks_deltaF_F0_all,out.poststim_ints_all,out.peak_times_all,...
                         out.baselines_all,out.rel_times_cond_starts,...
                         conditions,exp_date,reporter,dish,plot_settings,...
                         'summary_fig_dir',summary_fig_dir,'plot_inds',plot_inds,...
                         'roi_set_filename',roi_set_filenames{1}) 
%% Generate diff image stack
img_stack_name = sprintf('%s_%s_%s_diffimage_stack',exp_date,reporter,dish); 
makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),...
                      conditions,exp_settings,'img_stack_name',img_stack_name)                     