%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240826';
reporter = 'Archon';
dish = 'dish1';
div = 20; 

roiset_filename = 'RoiSet_pc_pos3';

num_stim = 50; 
num_trains = 1; 
del = 0.5; % sec 
freq = 2; % Hz
dur = num_stim/freq; 
stim_vals = defineStimTrains(del,freq,dur,num_trains,num_stim/freq); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.1; % window
baseline_wind = 0.015; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 2e3; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
total_time = stim_vals(end) + stim_wind; 
num_frames = total_time*sampling_rate;
fprintf('F = %.1f Hz, record for at least %g frames (%.2f sec)\n',...
        sampling_rate, num_frames,total_time); 
% Optional settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.show_diff_image = [4]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'combine';
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0_aligned' 'deltaF_F0'
% ps.plot_func = 'deltaF_F0_aligned2'; % 'deltaF_F0_aligned' 'deltaF_F0'
if strcmp(ps.plot_func,'deltaF_F0')
   ps.x_lim = [-baseline_wind stim_vals(end)+stim_wind];
   ps.y_lim = [];
else
    ps.x_lim = [-baseline_wind,stim_wind];
    ps.y_lim = [-0.02 0.12];
end
ps.close_img_after_save = 0; 
ps.offset_factor = 0;
ps.rem_pbleach = 0;
ps.analysis_funcs = {'peaks','peak_times','successful_spikes'};
ps.analyze_traces = 'deltaF_F0_aligned';    
ps.overlay_trials = 0;
ps.roi_func_peak_align = 1; 
%%
ps.condition = '50AP_2Hz_before';
img_name = [ps.condition '.fits'];
trace_fig = figure;
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%%
ps.condition = '50AP_2Hz';
trials_data = plotTrials({},exp_settings,roiset_filename,...
                        ps);

%% Save summary data from all train trials as experiment output file
ps.show_diff_image = []; % can include [1,2,3, 4]
ps.load_processed_data = 0;
ps.save_fig = 2; 
ps.plot_func = 'deltaF_F0';
ps.roi_func_mode = 'combine';
roiset_filename = 'RoiSet_pc_pos3';

roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  
conditions = {'50AP_2Hz_before','50AP_2Hz_after'};

if regexp(ps.plot_func,'aligned')
    ps.roi_func_fig_size = [19.8 19.18];
    ps.x_lim = [-baseline_wind, stim_wind];
%     ps.x_lim = [-baseline_wind, 1.4];    
%     ps.y_lim = [-0.05 0.7]; 
%     ps.y_lim = [-0.05 0.165];
    ps.y_lim = [-0.02 0.1]; 
else
    ps.x_lim = [-0.2 stim_vals(end) + stim_wind];
    ps.y_lim = [];
end

summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                            ['figs_',roiset_filename_no_ext '_' ps.roi_func_mode]);
summary_datafile = sprintf('%s_%s_%s_%s_%s_APwave',exp_date,reporter,dish,ps.roi_func_mode,...
                                    roiset_filename_no_ext);
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
out = plotTrials_multipleConditions(conditions,ps,exp_settings,...
                                    roiset_filename,...                               
                                   'summary_fig_dir',summary_fig_dir,...
                                   'summary_datafile',summary_datafile,...
                                   'plot_overlaid',0);
% set(0,'DefaultFigureVisible','on') % to avoid window taking screen focus
               