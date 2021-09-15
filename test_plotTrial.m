%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = '/Volumes/BACKUPDRIVE/Dartmouth_data';
exp_date= '20210914';
reporter = 'GluSnFr3';
dish = 'dish1';
condition = 'control'; % 'control', '5nM_DTX', '50nM_DTX'
position = 'Pos10'; 
img_name = 'control_4.fits'; 
stim_vals = 3; % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 1; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 100; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
roi_set_filename = 'RoiSet2_pos10.zip'; 
% Optional settings
plot_settings = struct();
plot_settings.show_diff_image = []; % can include [1,2,3]
plot_settings.filt_width = 0;
plot_settings.funcs = {'mean','std','baseline','deltaF_F0'};
plot_settings.roi_func_mode = 'combine';
plot_settings.save_processed_data = 0;
plot_settings.load_processed_data = 1;
plot_settings.save_fig = 0;
%%
% trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(data_fold,exp_date,reporter,dish,condition,position,...
                   img_name,exp_settings,roi_set_filename,...
                   trace_axis,plot_settings);