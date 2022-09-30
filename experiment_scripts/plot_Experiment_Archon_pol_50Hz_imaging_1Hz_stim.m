%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
data_fold = getDataFold();
exp_date= '20220928';
reporter = 'Archon_SynmRuby';
dish = 'dish2';
div = 15; 
condition = 'pol_1Hz_stim_50Hz_imaging'; %  test_soma
% roiset_filename  = [2 510 2 510]; % 
roiset_filename = 'RoiSet_pc_fullchip';
num_stim = 20; % number desired APs 20 or 100
stim_pulse_dur = 0.5; % pulse duration (sec)
stim_freq = 1; % Hz
stim_delay = 0; % sec % 3 or 5 sec delay
% stim_delay = 0.2; 
stim_duration = (num_stim+1)/stim_freq;
total_time = stim_duration + stim_delay;
sampling_rate = 50; % sampling rate of camera (frames/sec) - exp time 0.0004815
stim_vals = defineStimTrain(stim_delay,stim_freq,stim_duration); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 1; % window
baseline_wind = 0.2; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate,'stim_pulse_dur',...
                                  stim_pulse_dur); % automatically converts to frames

num_frames = ceil(total_time*sampling_rate);
fprintf('Set stim delay to %g sec, duration to %g sec, interval to %g sec\n',...
        stim_delay,stim_duration,1/stim_freq); 
fprintf('F = %.1f Hz, record for %g frames (%.2f sec)\n',...
        sampling_rate, num_frames,total_time); 
% Optional settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.condition = condition;
ps.show_diff_image = []; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate';
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0'
if strcmp(ps.plot_func,'deltaF_F0')
   ps.x_lim = [stim_delay stim_delay+stim_duration];
   ps.y_lim = [];
else
    ps.x_lim = [-baseline_wind,stim_wind];
    ps.y_lim = [];
end
ps.recenterROIs = 0;
ps.show_roi_labels = 1;
ps.close_img_after_save = 0; 
% ps.bin_size = 2;
ps.offset_factor = 0; 
ps.peak_mode = [10 40];
ps.diff_image_cmap = 'bluewhitered';
ps.filt_width = 1; 
ps.rem_pbleach = 1;
ps.motion_correct = 1; 
ps.overlay_trials = 0; 
%%
ps.condition = 'pol_1Hz_stim_50Hz_imaging';
img_name = 'trial_-10mAY';
trace_fig = figure; 
ps.roi_func_fig_units = 'inches'; 
ps.roi_func_fig_size = [9.8 6.33]; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%%
img_names = {};
trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
%% Plot multiple conditions
% '5Hz_50AP'
conditions = {'pol_1Hz_stim_50Hz_imaging'}; 
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                        ps.registration_rec);  
summary_datafile = sprintf('%s_%s_%s_%s_%s_pol',ps.exp_date,...
                                    ps.reporter,ps.dish,...
                                    ps.roi_func_mode,...
                                    roiset_filename_no_ext);
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
            ['figs_',roiset_filename_no_ext,'_' ps.roi_func_mode]);  
out = plotTrials_multipleConditions(conditions,ps,exp_settings,...
                                    roiset_filename,...
                                    'summary_datafile',summary_datafile,...
                                    'summary_fig_dir',summary_fig_dir); 
%% Analysis
img_names = trials_data.img_names;
theta_deg = [0,180,270,90,135,315,225,45];
roi_ind = 10; % soma
mean_deltaF_F0_aligned = squeeze(mean(trials_data.deltaF_F0_aligned,3)); 
mean_peaks = squeeze(mean(trials_data.analysis.peaks,2)); 
ta = exp_settings.getTimeVector(size(mean_deltaF_F0_aligned,1));
ta = ta-ta(exp_settings.baseline_wind+1);
mean_deltaF_F0_aligned_roi = squeeze(mean_deltaF_F0_aligned(:,roi_ind,:)); 
mean_peaks_roi = mean_peaks(roi_ind,:);
% Sort increasing theta
[theta_deg,sort_inds] = sort(theta_deg); 
mean_deltaF_F0_aligned_roi = mean_deltaF_F0_aligned_roi(:,sort_inds);
cols = parula(length(theta_deg));
cols = mat2cell(cols,ones(1,length(theta_deg)),3);
trial_times = trials_data.trial_times;
rel_trial_times = minutes(trial_times - trial_times(1)); % min
% Plot
fig = figure; 
p = plot(ta,mean_deltaF_F0_aligned_roi); box off; grid on; hold on;
    stimpoints_hand = addStimPointsToPlot(0,3,gca,'stim_pulse_dur',...
                  exp_settings.convert2Time(exp_settings.stim_pulse_dur));
set(p,{'color'},cols)    
xlabel('time (sec)')
ylabel('Mean \Delta F/F_{0}');
legend(p,numericVec2chars(theta_deg,'theta = %g^{\\circ}'),...
               'Box','off'); 
