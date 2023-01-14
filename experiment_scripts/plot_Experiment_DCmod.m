%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = fullfile(getDataFold(),'DC_mod_experiments'); 
exp_date = '221202';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish2';
div = 17; 
roiset_filename = 'RoiSet_auto_SynmRuby_pos5b.mat';
num_stim = 20; 
num_trains = 3; 
del = 0; % sec 
freq = 2; % Hz
dur = (1+num_stim)/freq; 
stim_vals = defineStimTrains(del,freq,dur,num_trains,num_stim/freq); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.4; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 100; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
% Optional settings
ps = plotTrialSettings();
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div;
ps.show_diff_image = [4]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate'; % combine or separate
ps.save_processed_data = 1;
ps.load_processed_data = 1; 
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0' 'deltaF_F0_aligned'
if strcmp(ps.roi_func_mode,'combine')
    ps.y_lim = [];
else
    ps.y_lim = [];
end
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, 1.4];
else
    ps.x_lim = [-0.2 stim_vals(end) + stim_wind];
end
ps.recenterROIs = 0;
ps.transform_type = 'displace'; % 'none' or 'displace'         
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,'control_8mABi_1mAG',...
                               'control_8mABi_1mAG.fits'); 
ps.show_roi_labels = 1;  
ps.close_img_after_save = 0;   
ps.roi_func_fig_size = [19.8 15]; 
ps.overlay_trials = 0; 
ps.offset_factor = 1;
ps.analyze_traces = 'deltaF_F0_aligned2';
ps.motion_correct = 0;
%%
ps.condition = 'control_8mABi_2mAG';
img_name = [ps.condition '.fits'];
trace_fig = figure('Units','normalized'); trace_fig.Position(1:2) = [1 0.4]; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%% Plot trials within each condition
ps.condition = 'control_10mABi_-0.1mAG'; % 'control', '5nM_DTX', '50nM_DTX'
img_names = {}; % use all images in condition folder
trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
%% Save summary data from all train trials as experiment output file
ps.show_diff_image = []; % can include [1,2,3, 4]
ps.load_processed_data = 1;
ps.save_fig = 2; 
ps.plot_func = 'deltaF_F0';
ps.roi_func_mode = 'separate';
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  
amps = [-2,-1, -0.5,-0.1,-0.05,0.05,0.1,0.5,1,2];
conditions = arrayfun(@(x) sprintf('control_8mABi_%gmAG',x),amps,'UniformOutput',0);

if regexp(ps.plot_func,'aligned')
%     ps.x_lim = [-baseline_wind, 0.9];
    ps.x_lim = [-baseline_wind, 1.4];    
    ps.y_lim = []; 
else
    ps.x_lim = [-0.2 stim_vals(end) + stim_wind];
    ps.y_lim = [-0.2 24.4];
end

summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                            ['figs_',roiset_filename_no_ext]);
summary_datafile = sprintf('%s_%s_%s_%s_%s_train',exp_date,reporter,dish,ps.roi_func_mode,...
                                    roiset_filename_no_ext);

out = plotTrials_multipleConditions(conditions,ps,exp_settings,...
                                    roiset_filename,...                               
                                   'summary_fig_dir',summary_fig_dir,...
                                   'summary_datafile',summary_datafile,...
                                   'plot_overlaid',0);
%%
cond_inds = [2:9]; 
amps = [-2,-1, -0.5,-0.1,-0.05,0.05,0.1,0.5,1,2];
% amps = [-1,1];
cond_names = arrayfun(@(x) sprintf('%g mA',x),amps,'UniformOutput',0);
sort_amp_ind = 1;
save_figs = 1;
norm_to_cont = 1;
plot_roi_ind = 15; 
plot_figs = [1:7]; % Select analysis figures to plot
                      % 1 - Plot mean trace averaged across ROIs
                      % 2 - Plot mean traces averaged within ROIs
                      % 3 - Plot responses within specific ROI in single figure                      
                      % 4 - Plot distribution of peaks within specific ROI at each 
                      %     DC intensity
                      % 5 - Plot peaks and change in peaks within ROI at
                      %     each intensity 
                      % 6 - Bar plot of fraction of ROIs modulated at each
                      %     intensity
                      % 7 - ROI spatial positions colored by modulation
                      % category (increase/decrease/no change)
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);                        
data_file_suffix = 'train';
analysis_fig_fold = ['figs_' roiset_filename_no_ext];

if exist('out','var')
    analyze_DCmod_GluSnFR3_experiment2(out,...
                        cond_inds,cond_names,sort_amp_ind,save_figs,...
                        'plot_figs',plot_figs,'plot_roi_ind',plot_roi_ind,...
                        'norm_to_cont',norm_to_cont,'data_file_suffix',data_file_suffix,...
                        'data_fold',data_fold,'analysis_fig_fold',...
                        analysis_fig_fold);
else
    data_params.exp_date = exp_date;
    data_params.reporter = reporter;
    data_params.dish = dish; 
    data_params.roiset_filename = roiset_filename_no_ext; 
    analyze_DCmod_GluSnFR3_experiment2(data_params,...
                        cond_inds,cond_names,sort_amp_ind,save_figs,...
                        'plot_figs',plot_figs,'plot_roi_ind',plot_roi_ind,...
                        'norm_to_cont',norm_to_cont,'data_file_suffix',data_file_suffix,...
                        'data_fold',data_fold,'analysis_fig_fold',...
                        analysis_fig_fold);
end