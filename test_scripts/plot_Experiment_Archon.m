%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
data_fold = getDataFold();
exp_date= '20220301';
reporter = 'Archon';
dish = 'dish1';
div = 14; 
condition = 'control'; %  test_soma
position = 'pos7';
img_name = 'control';
num_stim = 50; % number desired APs 20 or 100
stim_pulse_dur = 0.001; % pulse duration (sec)
stim_freq = 5; % Hz
stim_delay = 1; % sec % 3 or 5 sec delay
stim_duration = num_stim/stim_freq;
total_time = stim_duration + stim_delay;
sampling_rate = 2000; % sampling rate of camera (frames/sec) - exp time 0.0004815
stim_vals = defineStimTrain(stim_delay,stim_freq,stim_duration); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.2; % window
baseline_wind = 0.1; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
% roiset_filename  = [11 18 10 85]; % 
roiset_filename = ['RoiSet_' position];
num_frames = ceil(total_time*sampling_rate);
fprintf('Set stim delay to %g sec, duration to %g sec, interval to %g sec\n',...
        stim_delay,stim_duration,1/stim_freq); 
fprintf('F = %.1f Hz, record for %g frames (%.2f sec)\n',...
        sampling_rate, num_frames,total_time); 
% Optional settings
plot_settings = plotTrialSettings;
plot_settings.data_fold = data_fold;
plot_settings.exp_date = exp_date;
plot_settings.reporter = reporter;
plot_settings.dish = dish;
plot_settings.div = div; 
plot_settings.condition = condition;
plot_settings.position = position;
plot_settings.show_diff_image = [3]; % can include [1,2,3]
plot_settings.filt_width = 0;
plot_settings.funcs = {'mean','baseline','deltaF_F0'};
plot_settings.roi_func_mode = 'combine';
plot_settings.save_processed_data = 1;
plot_settings.load_processed_data = 1;
plot_settings.save_fig = 1;
plot_settings.y_lim = [-0.01 0.18];
% plot_settings.x_lim = [stim_delay stim_delay+stim_duration];
plot_settings.x_lim = [-0.05 0.15];
plot_settings.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0'
plot_settings.recenterROIs = 0;
plot_settings.show_roi_labels = 1;
plot_settings.close_img_after_save = 0; 
%%
plot_settings.condition = 'post_wash';
img_name = 'wash_1';
trace_fig = figure;
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,plot_settings);
%%
plot_settings.condition = '1mM_TEA_50nM_DTX';
trials_data = plotTrials({},exp_settings,roiset_filename,...
                        plot_settings);
%%
conditions = {'control','1mM_TEA','50nM_DTX','1mM_TEA_50nM_DTX','wash'};
positions = repmat({position},1,length(conditions));
img_names = cell(1,length(conditions)); % use all images in condition folder
roiset_filenames = [repmat({roiset_filename},1,length(conditions))];
plot_settings.show_diff_image = [];
plot_settings.roi_func_mode = 'combine';
plot_settings.save_fig = 0;
plot_settings.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0'
out = plotTrials_multipleConditions(data_fold,exp_date,reporter,dish,...
                                       conditions,positions,img_names,exp_settings,...
                                       roiset_filenames,plot_settings); 
%% Re-plot traces overlaid
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
            ['figs_',out.roiset_filename_no_ext,'_' out.plot_settings.roi_func_mode]);       
plot_settings.plot_func = 'deltaF_F0_aligned';
plot_settings.y_lim = [-0.01 1.05];
plot_settings.x_lim = [-0.05 0.15];
cond_inds = [];
norm_peak_ind = -1; 
% align_to = 'none';
align_to = 'max'; 
plotExperimentTracesOverlaidGrid(out,plot_settings.plot_func,...
                                'fig_dir',summary_fig_dir,...                                
                                'save_fig',1,...
                                'y_lim',plot_settings.y_lim,...
                                'x_lim',plot_settings.x_lim,...
                                'cond_inds',cond_inds,...
                                'norm_peak_ind',norm_peak_ind,...
                                'align_to',align_to);
%% Plot summary data
plot_inds = [1,3,4];
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
            ['figs_',out.roiset_filename_no_ext,'_' out.plot_settings.roi_func_mode]);       
plotDefaultSummaryStats(out.peaks_deltaF_F0_all,[],out.peak_times_all,...
                         out.baselines_all,out.decay_fits,out.rel_times_cond_starts,...
                         out.conditions,exp_date,reporter,dish,out.plot_settings,...
                         'plot_inds',plot_inds,'summary_fig_dir',summary_fig_dir,...
                         'save_fig',1) 
%% Get AP peaks
% means = datai.func_output.mean; % mean signal within each roi
% baselines = datai.func_output.baseline; % baseline before each stim, for each roi
% AP_window = [5 20]*1e-3; 
% [tAP, mean_APs_all, deltaF_F0_all, peak_frames_all] = ...
%     extractAPsFromTrain(means,exp_settings,'method',1,...
%     'save_fig',1,'fig_dir',[condition filesep 'figs_custom'],...
%     'fig_basename',[img_name,'_APs'],'AP_window',AP_window,...
%     'biphasic_mode',0); 

% ylim([-0.05 0.05]); 
               