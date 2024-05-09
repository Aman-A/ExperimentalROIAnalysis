data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240508';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish1';
div = 15; 

% roiset_filename = 'RoiSet_auto_diffimagesG_test.mat';
% roiset_filename = 'RoiSet_auto_pos4.mat';
roiset_filename = 'RoiSet_pc_pos4.zip';
supra_amp = 5; % mA

sampling_rate = 100; % sampling rate (frames/sec)
% Alternate DC on odd trials, off even trials, sort into train 1, train 2,
% respectively
num_stim = 20; 
num_trains = 2; 
del = 0.2; % sec 
freq = 1/0.6; % Hz
dur = num_stim/freq; 
stim_vals = defineStimTrains(del,freq,dur,num_trains,(num_stim)/freq)'; % frames - 3 sec delay (100 Hz sampling time)
stim_vals = reshape(stim_vals(:),num_trains,num_stim);
stim_wind = 0.39; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
stim_pulse_dur2 = 0.1; 
stim_vals2 = stim_vals(1,:) - stim_pulse_dur2; % 0 ms interval between end of subthresh and start of suprathresh pulse
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate,'stim_vals2',stim_vals2,...
                                  'stim_pulse_dur2',stim_pulse_dur2); % automatically converts to frames
% Optional settings
ps = plotTrialSettings();
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div;
ps.show_diff_image = []; % can include [1,2,3,4]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate'; % combine or separate
ps.save_processed_data = 1;
ps.load_processed_data = 0; 
ps.save_fig = 0;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0' 'deltaF_F0_aligned'
% ps.plot_func = 'deltaF_F0_aligned2'; % 'deltaF_F0' 'deltaF_F0_aligned'
% if strcmp(ps.roi_func_mode,'combine')
%     ps.y_lim = [];
% else
%     ps.y_lim = [];
% end
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, stim_wind*2 + baseline_wind];
else
    ps.x_lim = [-0.2 stim_vals(end) + stim_wind];
end
ps.recenterROIs = 0;
ps.transform_type = 'none'; % 'none' or 'displace'         
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,'control_6.5mAB_50VpmG',...
                               'control_6.5mAB_50VpmG.fits'); 
ps.show_roi_labels = 1; 
ps.close_img_after_save = 0;   
ps.roi_func_fig_size = [19.8 22]; 
ps.overlay_trials = 0; 
ps.offset_factor = 0.4;
ps.analyze_traces = 'deltaF_F0_aligned2';
ps.motion_correct = 0;
ps.rem_pbleach = 0; 
ps.roi_func_sbar_len = 0.5;
ps.analysis_funcs = {'peaks','peak_times','poststim_ints','decay_fit'};
ps.spike_window = 0.05; 
ps.blank_frame_inds = 1:60:(60*40);
%%
ps.condition = 'test_1AP_trials';
img_name = ['test_1.fits'];
trace_fig = figure('Units','normalized'); trace_fig.Position(1:2) = [1 0.4]; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
