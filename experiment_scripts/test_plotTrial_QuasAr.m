%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = getDataFold();
exp_date= '20211006';
reporter = 'QuasAr';
dish = 'dish3';
condition = 'axon_pos4'; % 'control', '5nM_DTX', '50nM_DTX'
position = 'Pos4';
img_name = 'axon_5Hz_10ms_pulse_biphasic.fits';
num_stim = 20; % number desired APs 20 or 100
stim_pulse_dur = 0.01; % pulse duration (sec)
stim_freq = 5; % Hz
stim_delay = 3; % sec % 3 or 5 sec delay
stim_duration = num_stim/stim_freq;
total_time = stim_duration + stim_delay;
sampling_rate = 1000; % sampling rate of camera (frames/sec) - exp time 0.0004815
stim_vals = defineStimTrain(stim_delay,stim_freq,stim_duration); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.5; % window
baseline_wind = 0.05; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
% roi_set_filename = 'RoiSet_pc_pos8.zip';
roi_box = [10 40 1 60];
% roi_box = [5 45 5 45;5 45 46 85];
% roi_box = [28 22 6;65 26 6]; 
num_frames = ceil(total_time*sampling_rate);
fprintf('Set stim delay to %g sec, duration to %g sec, interval to %g sec\n',...
        stim_delay,stim_duration,1/stim_freq); 
fprintf('F = %.1f Hz, record for %g frames (%.2f sec)\n',...
        sampling_rate, num_frames,total_time); 
% Optional settings
plot_settings = struct();
plot_settings.show_diff_image = [3]; % can include [1,2,3]
plot_settings.filt_width = 1;
plot_settings.funcs = {'mean','baseline','deltaF_F0'};
plot_settings.roi_func_mode = 'separate';
plot_settings.save_processed_data = 1;
plot_settings.load_processed_data = 1;
plot_settings.save_fig = 0;
plot_settings.y_lim = [];
plot_settings.x_lim = [stim_delay stim_delay+stim_duration];
plot_settings.plot_func = 'deltaF_F0'; % 'deltaF_F0'
plot_settings.recenterROIs = 0;
%%
trace_fig = figure;
trace_axis = gca;
datai = plotTrial(data_fold,exp_date,reporter,dish,condition,position,...
                   img_name,exp_settings,roi_box,...
                   trace_axis,plot_settings);
%% Get AP peaks
means = datai.func_output.mean; % mean signal within each roi
baselines = datai.func_output.baseline; % baseline before each stim, for each roi
[tAP, mean_APs_all, deltaF_F0_all, peak_frames_all] = ...
    extractAPsFromTrain(means,exp_settings,...
                       'method',1,'AP_window',[5 15]*1e-3,'filt_order',0,...
                       'filt_cutoff',1/2); 
               