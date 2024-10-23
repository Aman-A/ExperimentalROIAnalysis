%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240826';
reporter = 'Archon';
dish = 'dish1';
div = 20; 

% roiset_filename  = [2 510 2 510]; % 
roiset_filename = 'RoiSet_pc_pos3';

sampling_rate = 2000; % sampling rate of camera (frames/sec)
num_stim = 10; % number desired APs 20 or 100
stim_pulse_dur = 0.5; % pulse duration (sec)
stim_freq = 1; % Hz
stim_delay = 1; % sec % 3 or 5 sec delay
stim_duration = num_stim/stim_freq;
stim_vals = defineStimTrain(stim_delay,stim_freq,stim_duration); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.8; % window
baseline_wind = 0.2; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate,'stim_pulse_dur',...
                                  stim_pulse_dur); % automatically converts to frames
stim_vals1 = defineStimTrain(stim_delay,stim_freq,21/stim_freq); % frames - 3 sec delay (100 Hz sampling time)
exp_settings1 = ExperimentSettings(stim_vals1,stim_wind,baseline_wind,...
                                  units,sampling_rate,'stim_pulse_dur',...
                                  stim_pulse_dur);
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
ps.show_diff_image = [4]; % can include [1,2,3]
ps.filt_width = 1;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'combine';
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 2;
% ps.plot_func = 'deltaF_F0'; % 'deltaF_F0'
ps.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0'
if strcmp(ps.plot_func,'deltaF_F0_aligned')
    ps.x_lim = [-baseline_wind,stim_wind];
    ps.y_lim = [];
else
    ps.x_lim = [0,total_time];
end
ps.recenterROIs = 0;
ps.show_roi_labels = 1;
ps.close_img_after_save = 0; 
ps.offset_factor = 0; 
ps.peak_mode = [0.6*stim_pulse_dur stim_pulse_dur]*sampling_rate;
ps.diff_image_cmap = 'bluewhitered';
ps.rem_pbleach = 0;
ps.motion_correct = 0; 
ps.overlay_trials = 0;
ps.blank_frame_inds = 1;
ps.analysis_funcs = {'peaks','peak_times'};
%% Plot single trial
ps.condition = 'pol_1Hz_500ms_50VpmG';
img_name = [ps.condition '.fits'];
trace_fig = figure;
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%% Plot all trials within condition
ps.condition = 'pol_1Hz_500ms_0.5mAG';
img_names = {};
trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
%% Save summary data from all train trials as experiment output file
ps.show_diff_image = [4]; % can include [1,2,3, 4]
ps.load_processed_data = 1;
ps.save_fig = 1; 
ps.plot_func = 'deltaF_F0_aligned';
ps.roi_func_mode = 'separate';
roiset_filename = 'RoiSet_pc_pos3';

roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  
amps = [-2,-1,-0.5,0.5,1,2];
conditions = arrayfun(@(x) sprintf('pol_1Hz_500ms_%gmAG',x),amps,'UniformOutput',0);

if regexp(ps.plot_func,'aligned')
    ps.roi_func_fig_size = [19.8 19.18];
    ps.x_lim = [-baseline_wind, stim_wind];
    ps.y_lim = []; 
else
    ps.x_lim = [-0.2 stim_vals(end) + stim_wind];
    ps.y_lim = [];
end

summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                            ['figs_',roiset_filename_no_ext '_pol_' ps.roi_func_mode]);
summary_datafile = sprintf('%s_%s_%s_%s_%s_pol',exp_date,reporter,dish,ps.roi_func_mode,...
                                    roiset_filename_no_ext);
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
exp_settings = [repmat(exp_settings,4,1);exp_settings1;exp_settings];
out = plotTrials_multipleConditions(conditions,ps,exp_settings,...
                                    roiset_filename,...                               
                                   'summary_fig_dir',summary_fig_dir,...
                                   'summary_datafile',summary_datafile,...
                                   'plot_overlaid',0);
% set(0,'DefaultFigureVisible','on') % to avoid window taking screen focus
%% Re-plot traces overlaid    
ps.plot_func = 'deltaF_F0_aligned';
ps.y_lim = [];
% ps.y_lim = [-0.4 1.05];
% ps.y_lim = [-0.04 0.2];
ps.x_lim = [-0.1 0.7];
cond_inds = [];
norm_peak_ind = 0; 
align_to = 'none';
% align_to = 'max'; 
fig_size = [42.5 22.4];
cols = flipud([ 0.6445         0    0.1484 % for 8
%             0.8398    0.1875    0.1523
            0.9531    0.4258    0.2617
            0.9883    0.6797    0.3789
            0.6680    0.8477    0.9102
            0.4531    0.6758    0.8164
%             0.2695    0.4570    0.7031
            0.1914    0.2109    0.5820]);
plotExperimentTracesOverlaidGrid(out,ps.plot_func,...
                                'fig_dir',summary_fig_dir,...                                
                                'save_fig',1,...
                                'y_lim',ps.y_lim,...
                                'x_lim',ps.x_lim,...
                                'cond_inds',cond_inds,...
                                'norm_peak_ind',norm_peak_ind,...
                                'align_to',align_to,'fig_size',fig_size,...
                                'colors',cols,'indicator_dir',ps.indicator_dir);