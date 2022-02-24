%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = getDataFold();
exp_date = '20220222';
reporter = 'GluSnFR3';
dish = 'dish2';
div = 14; 
condition = 'train'; % 'control', '5nM_DTX', '50nM_DTX'
position = 'pos0'; 
img_name = '50nM_DTX';
num_stim = 20; 
del = 0; % sec 
freq = 0.5; % Hz
dur = (1+num_stim)/freq; 
stim_vals = defineStimTrain(del,freq,dur); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.5; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 200; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
roi_set_filename = ['RoiSet_' position]; 
% Optional settings
plot_settings = plotTrialSettings ();
plot_settings.data_fold = data_fold;
plot_settings.exp_date = exp_date;
plot_settings.reporter = reporter;
plot_settings.dish = dish;
plot_settings.condition = condition;
plot_settings.position = position;
plot_settings.show_diff_image = []; % can include [1,2,3]
plot_settings.filt_width = 0;
plot_settings.funcs = {'mean','baseline','deltaF_F0'};
plot_settings.roi_func_mode = 'separate';
plot_settings.save_processed_data = 1;
plot_settings.load_processed_data = 1;
plot_settings.save_fig = 1;
plot_settings.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0'
if strcmp(plot_settings.roi_func_mode,'combine')
    plot_settings.y_lim = [];
else
    plot_settings.y_lim = [-0.2 20];
end
if regexp(plot_settings.plot_func,'aligned')
    plot_settings.x_lim = [-baseline_wind, stim_wind];
else
    plot_settings.x_lim = [-0.2 stim_vals(end) + stim_wind];
end
plot_settings.recenterROIs = 0;
plot_settings.transform_type = 'displace'; % 'none' or 'displace'
plot_settings.registration_rec = fullfile(data_fold,exp_date,...
                                          reporter,dish,'burst',...
                                          'control.fits'); 
plot_settings.show_roi_labels = 1;  
plot_settings.close_img_after_save = 1;                           
%%
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roi_set_filename,...
                   trace_axis,plot_settings);
%% Plot trials within each condition
img_names = {}; % use all images in condition folder
trials_data = plotTrials(img_names,exp_settings,roi_set_filename,plot_settings);