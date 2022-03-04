%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = getDataFold();
exp_date = '20220224';
reporter = 'GluSnFR3';
dish = 'dish3';
div = 16; 
condition = 'train'; % 'control', '5nM_DTX', '50nM_DTX'
position = 'pos2'; 
img_name = '50nM_DTX_Sr';
num_stim = 20; 
del = 0; % sec 
freq = 0.5; % Hz
dur = (1+num_stim)/freq; 
stim_vals = defineStimTrain(del,freq,dur); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 1; % window
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
    plot_settings.y_lim = [-0.2 30];
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
%% Save summary data from all train trials as experiment output file
plot_settings.show_diff_image = []; % can include [1,2,3]
plot_settings.save_fig = 0; 
plot_settings.plot_func = 'none';
plot_settings.roi_func_mode = 'separate';
roiset_filename_no_ext = getROIset_name(roi_set_filename,...
                                         plot_settings.transform_type,...
                                            plot_settings.registration_rec);  
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,condition,...
                            ['figs_',roiset_filename_no_ext]);
summary_datafile = sprintf('%s_%s_%s_%s_%s_train',exp_date,reporter,dish,plot_settings.roi_func_mode,...
                                    roiset_filename_no_ext);
out = plotTrials_multipleConditions(data_fold,exp_date,reporter,dish,...
                               {condition},{position},{{}},exp_settings,...
                               {roi_set_filename},...
                               plot_settings,...
                               'summary_fig_dir',summary_fig_dir,...
                               'summary_datafile',summary_datafile,...
                               'plot_overlaid',0);
%% Plot overlaid if roi_func_mode is separate
cond_inds = 1:4; 
glut_norm = 1; % load already generated glut_norm file
norm_datafile = sprintf('%s_%s_%s_separate_%s_glutnorm',exp_date,reporter,dish,...
                        roiset_filename_no_ext);
if strcmp(plot_settings.roi_func_mode,'separate')
    deltaF_F0_aligned = trials_data.deltaF_F0_aligned;
    mean_deltaF_F0_aligned = squeeze(mean(deltaF_F0_aligned,3)); % [num_frames x num_rois x num_conditions]
    t = exp_settings.getTimeVector(size(mean_deltaF_F0_aligned,1));
    
    if regexp(plot_settings.plot_func,'aligned')
        t = t - t(exp_settings.baseline_wind+1); % align to stim
    else
        t = t - t(exp_settings.convert2Time(exp_settings.stim_vals(1))); % align to first stim
    end    
    if glut_norm
        norm_out = load(fullfile(data_fold,exp_date,reporter,dish,[norm_datafile '.mat'])); 
        ss_dFF0 = norm_out.glut_ss_deltaF_F0;
        mean_deltaF_F0_aligned = mean_deltaF_F0_aligned./ss_dFF0;
    end
    plotTracesOverlaidGridArray(t,mean_deltaF_F0_aligned(:,:,cond_inds),[],...
                                'y_lim',[-0.002 0.12],'x_sbar_len1',[]);
end