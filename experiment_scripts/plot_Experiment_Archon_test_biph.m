%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240826';
reporter = 'Archon';
dish = 'dish1';
div = 20; 

roiset_filename = [2 24 2 88];

num_stim = 10; % number desired APs 20 or 100
stim_pulse_dur = 0.001; % pulse duration (sec)
stim_freq = 10; % Hz
stim_delay = 0.2; 
stim_duration = num_stim/stim_freq;
sampling_rate = 2e3; % sampling rate of camera (frames/sec) - exp time 0.0004815
stim_vals = defineStimTrain(stim_delay,stim_freq,stim_duration); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.1; % window
baseline_wind = 0.05; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
total_time = stim_vals(end) + stim_wind; 
num_frames = ceil(total_time*sampling_rate);
fprintf('F = %.1f Hz, record for %g frames (%.2f sec)\n',...
        sampling_rate, num_frames,total_time); 
% Optional settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
% ps.condition = condition;
ps.show_diff_image = [4]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate';
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 0;
ps.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0' 'deltaF_F0_aligned'
ps.y_lim = [];
if strcmp(ps.plot_func,'deltaF_F0')
    ps.x_lim = [stim_delay stim_delay+stim_duration];
else
    ps.x_lim = [-baseline_wind stim_wind];
end
ps.recenterROIs = 0;
ps.show_roi_labels = 1;
ps.close_img_after_save = 1; 
ps.offset_factor = 0;
ps.rem_pbleach = 0;
ps.roi_func_peak_align = 1; 
%%
ps.condition = 'test';
img_name = 'trial_4';
trace_fig = figure;
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
peaks = max(datai.func_output.deltaF_F0_aligned(exp_settings.baseline_wind:end,:),[],1);
bsline_std = std(datai.func_output.deltaF_F0_aligned(1:exp_settings.baseline_wind,:),0,1);
snrs = peaks./bsline_std; 
fprintf('mean +/- std (min,max)\n')
fprintf('Peaks: %.3f +/- %.3f (%.3f, %.3f)\n',mean(peaks),std(peaks),min(peaks),max(peaks));
fprintf('SNR: %.3f +/- %.3f (%.3f, %.3f)\n',mean(snrs),std(snrs),min(snrs),max(snrs));
%% Get AP peaks
bi_mode = 1; 
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  
fig_dir = [ps.condition filesep 'figs_' roiset_filename_no_ext];

means = datai.func_output.mean; % mean signal within each roi
% baselines = datai.func_output.baseline; % baseline before each stim, for each roi
AP_window = [15 50]*1e-3; 
[tAP, mean_APs_all, deltaF_F0_all, peak_frames_all] = ...
    extractAPsFromTrain(means,exp_settings,'method',1,...
    'save_fig',1,'fig_dir',fig_dir,...
    'fig_basename',[img_name,'_APs'],'AP_window',AP_window,...
    'biphasic_mode',bi_mode); 