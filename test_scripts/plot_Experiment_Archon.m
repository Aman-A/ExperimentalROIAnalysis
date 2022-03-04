%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
data_fold = getDataFold();
exp_date= '20220301';
reporter = 'Archon';
dish = 'dish1';
div = 14; 
condition = 'control'; %  test_soma
% roiset_filename  = [2 24 2 88]; % 
roi_set_filename = 'RoiSet_pos0';
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
ps.show_diff_image = [3]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'combine';
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 1;
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
%%
ps.condition = 'post_wash';
img_name = 'wash_1';
trace_fig = figure;
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%%
ps.condition = '1mM_TEA_50nM_DTX';
trials_data = plotTrials({},exp_settings,roiset_filename,...
                        ps);
%%
conditions = {'control','1mM_TEA','50nM_DTX','1mM_TEA_50nM_DTX','wash'};
ps.show_diff_image = [];
ps.roi_func_mode = 'combine';
ps.save_fig = 0;
ps.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0'
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
out = plotTrials_multipleConditions(conditions,ps,exp_settings,...
                                    roiset_filename); 
% set(0,'DefaultFigureVisible','on')
%% Re-plot traces overlaid
summary_fig_dir = fullfile(data_fold,out.exp_date,out.reporter,out.dish,...
            ['figs_',out.roiset_filename_no_ext,'_' out.plot_settings.roi_func_mode]);       
ps.plot_func = 'deltaF_F0_aligned';
ps.y_lim = [-0.01 1.05];
ps.x_lim = [-0.05 0.15];
cond_inds = [];
norm_peak_ind = -1; 
% align_to = 'none';
align_to = 'max'; 
plotExperimentTracesOverlaidGrid(out,ps.plot_func,...
                                'fig_dir',summary_fig_dir,...                                
                                'save_fig',1,...
                                'y_lim',ps.y_lim,...
                                'x_lim',ps.x_lim,...
                                'cond_inds',cond_inds,...
                                'norm_peak_ind',norm_peak_ind,...
                                'align_to',align_to);
%% Plot summary data
plot_inds = [1,3,4,7];
summary_fig_dir = fullfile(data_fold,out.exp_date,out.reporter,out.dish,...
            ['figs_',out.roiset_filename_no_ext,'_' out.plot_settings.roi_func_mode]);       
plotExpDefaultSummaryStats(out,out.plot_settings,...
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
               