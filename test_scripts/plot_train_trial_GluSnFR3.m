%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = getDataFold();
exp_date = '20220224';
reporter = 'GluSnFR3';
dish = 'dish3';
div = 16; 
condition = 'train'; % 'control', '5nM_DTX', '50nM_DTX'
roi_set_filename = 'RoiSet_pos0';
img_name = 'control';
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
% Optional settings
ps = plotTrialSettings();
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
ps.save_fig = 1;
ps.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0'
if strcmp(ps.roi_func_mode,'combine')
    ps.y_lim = [];
else
    ps.y_lim = [-0.2 30];
end
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, stim_wind];
else
    ps.x_lim = [-0.2 stim_vals(end) + stim_wind];
end
ps.recenterROIs = 0;
ps.transform_type = 'displace'; % 'none' or 'displace'
ps.registration_rec = fullfile(data_fold,exp_date,...
                                          reporter,dish,'burst',...
                                          'control.fits'); 
burst_stim_vals = defineStimTrain(3,50,0.1); % burst
exp_settings2 = ExperimentSettings(burst_stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames                                 
plot_settings.registration_rec_settings = exp_settings2;                                       
ps.show_roi_labels = 1;  
ps.close_img_after_save = 1;                           
%%
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roi_set_filename,...
                   trace_axis,ps);
%% Plot trials within each condition
img_names = {}; % use all images in condition folder
trials_data = plotTrials(img_names,exp_settings,roi_set_filename,ps);
%% Save summary data from all train trials as experiment output file
ps.show_diff_image = []; % can include [1,2,3]
ps.save_fig = 0; 
ps.plot_func = 'none';
ps.roi_func_mode = 'separate';
roiset_filename_no_ext = getROIset_name(roi_set_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,condition,...
                            ['figs_',roiset_filename_no_ext]);
summary_datafile = sprintf('%s_%s_%s_%s_%s_train',exp_date,reporter,dish,ps.roi_func_mode,...
                                    roiset_filename_no_ext);
out = plotTrials_multipleConditions({condition},ps,exp_settings,...
                                    roi_set_filename,...                               
                                   'summary_fig_dir',summary_fig_dir,...
                                   'summary_datafile',summary_datafile,...
                                   'plot_overlaid',0);
%% Plot overlaid if roi_func_mode is separate
cond_inds = 1:4; 
glut_norm = 1; % load already generated glut_norm file
norm_datafile = sprintf('%s_%s_%s_separate_%s_glutnorm',exp_date,reporter,dish,...
                        roiset_filename_no_ext);
if strcmp(ps.roi_func_mode,'separate')
    deltaF_F0_aligned = trials_data.deltaF_F0_aligned;
    mean_deltaF_F0_aligned = squeeze(mean(deltaF_F0_aligned,3)); % [num_frames x num_rois x num_conditions]
    t = exp_settings.getTimeVector(size(mean_deltaF_F0_aligned,1));
    
    if regexp(ps.plot_func,'aligned')
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