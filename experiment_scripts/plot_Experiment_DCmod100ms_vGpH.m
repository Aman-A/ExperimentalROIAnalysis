%% Experiment measuring effect of subthreshold pre-pulse on single AP vG-pH 
% responses
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240522';
reporter = 'vGlut-pHluorin';
dish = 'dish1';
div = 15;

roiset_filename = 'RoiSet_pc_test.zip';

stim_pulse_dur = 0.001; % sec - train duration
num_stim = 1; 
num_trains = 1; 
del = 2; % sec 
freq = 1/4; % Hz
dur = (num_stim)/freq; 
stim_vals = defineStimTrains(del,freq,dur,num_trains,num_stim/freq); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 1.9; % window
baseline_wind = 2; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 50; % sampling rate (frames/sec)
stim_pulse_dur2 = 0.1;
subthresh_interval = 0; % no delay
stim_vals2 = stim_vals - stim_pulse_dur2 - subthresh_interval; 
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate,...
                                  'stim_pulse_dur',stim_pulse_dur,...
                                  'stim_vals2',stim_vals2,...
                                  'stim_pulse_dur2',stim_pulse_dur2); % automatically converts to frames
% Optional settings
ps = plotTrialSettings();
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div;
ps.show_diff_image = []; % can include [1,2,3,4]
ps.filt_width = 1;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'combine'; % combine or separate
ps.save_processed_data = 1;
ps.load_processed_data = 1; 
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0' 'deltaF_F0_aligned'
% if strcmp(ps.roi_func_mode,'combine')
%     ps.y_lim = [];
% else
%     ps.y_lim = [];
% end
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, 1.4];
else
    ps.x_lim = [];
%     ps.x_lim = [-baseline_wind stim_vals(end)-stim_vals(1) + stim_wind];
end
ps.recenterROIs = 0;
ps.transform_type = 'none'; % 'none' or 'displace'         
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,'15mAB_50AP_25Hz_0mAG',...
                               '15mAB_50AP_25Hz_0mAG.fits'); 
ps.show_roi_labels = 1;  
ps.close_img_after_save = 0;   
ps.roi_func_fig_size = [19.8 22]; 
ps.overlay_trials = 0; 
ps.analyze_traces = 'deltaF_F0_aligned';
ps.motion_correct = 0;
ps.rem_pbleach = 0; 
ps.offset_factor = 0.4;
ps.roi_func_sbar_len = 0.5; 
ps.analysis_funcs = {'peaks','peak_times','poststim_ints'};
%%
ps.condition = '0mA_100ms';
% img_name = [ps.condition '.fits'];
img_name = ['trial.fits'];
trace_fig = figure('Units','normalized'); trace_fig.Position(1:2) = [1 0.4]; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%% Plot trials within each condition
ps.condition = '0mA_100ms'; % 'control', '5nM_DTX', '50nM_DTX'
% img_names = '20mAB_50AP_25Hz_0mAG_3.fits'; % use all images in condition folder
img_names = {};

% roiset_filenames = {'RoiSet_pc.zip','RoiSet_pc.zip','RoiSet_pc.zip'};

trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
%% Save summary data from all train trials as experiment output file
ps.show_diff_image = [4]; % can include [1,2,3, 4]
ps.load_processed_data = 0;
ps.save_fig = 2; % 1 - save trials overlaid, 2- save individual trials as separate files
ps.plot_func = 'deltaF_F0';
ps.roi_func_mode = 'combine';
 
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  
amps = [-1,0,1];
% amps = [-1,-0.5,-0.1,0.1,0.5,1];
conditions = arrayfun(@(x) sprintf('20mAB_50AP_25Hz_%gmAG',x),amps,'UniformOutput',0);

if regexp(ps.plot_func,'aligned')
%     ps.x_lim = [-baseline_wind, 0.9];
    ps.x_lim = [-baseline_wind, 1.4];    
    ps.y_lim = []; 
else
%     ps.x_lim = [-0.2 stim_vals(end) + stim_wind];
%     ps.y_lim = [-0.1 0.7];
end

summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                            ['figs_',roiset_filename_no_ext]);
summary_datafile = sprintf('%s_%s_%s_%s_%s_train',exp_date,reporter,dish,ps.roi_func_mode,...
                                    roiset_filename_no_ext);
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
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
ps.x_lim = [-0.5 3.5];
cond_inds = [];
norm_peak_ind = 0; 
align_to = 'none';
% align_to = 'max'; 
fig_size = [42.5 22.4];
cols = flipud([ 0.6445         0    0.1484 % for 8
%             0.8398    0.1875    0.1523
%             0.9531    0.4258    0.2617
%             0.9883    0.6797    0.3789
             0 0 0;
%             0.6680    0.8477    0.9102
%             0.4531    0.6758    0.8164
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
%% Analyze NH4Cl wash trial
load_existing_settings = 0;
nh4_cl_rec_name = 'trial.fits';
ps.condition = 'nh4_cl';
ps.x_lim = []; ps.y_lim = []; 
ps.show_diff_image = 3; 
ps.save_fig = 2; 
norm_func = 'mean';
if load_existing_settings
    roiset_filename_load = roiset_filename; 
    roiset_filename_no_ext_load = getROIset_name(roiset_filename_load,...
                                                ps.transform_type,...
                                                ps.registration_rec);
    data = load(fullfile(data_fold,exp_date,reporter,dish,ps.condition,...
                  sprintf('%s-%s-%s-data.mat',glut_img_name,ps.roi_func_mode,...
                                        roiset_filename_no_ext_load)));
    nh4cl_exp_settings = data.settings;
    check_settings = 0;
else
    nh4cl_exp_settings = ExperimentSettings(50,20,20,'frames',2); % place holders
    check_settings = 1;
end
mean_wind = []; 
[dF_metrics,norm_out,nh4cl_trace,exp_settings] = analyzeNH4ClNormTrial(nh4_cl_rec_name,...
                                        nh4cl_exp_settings,roiset_filename,...
                                        ps,mean_wind,[],...
                                        'check_settings',check_settings,...
                                        'norm_func',norm_func);
