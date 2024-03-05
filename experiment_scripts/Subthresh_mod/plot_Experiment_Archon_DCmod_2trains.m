%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '230309';
reporter = 'Archon';
dish = 'dish1';
div = 16; 

roiset_filename = 'RoiSet_pc_pos4';

num_stim = 20; 
num_trains = 2; 
del = 0.5; % sec 
freq = 2; % Hz
dur = (num_stim)/freq; 
stim_vals = defineStimTrains(del,freq,dur,num_trains,num_stim/freq); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.1; % window
baseline_wind = 0.015; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 2e3; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
total_time = stim_vals(end) + stim_wind; 
num_frames = total_time*sampling_rate;
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
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate';
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 1;
ps.plot_func = 'deltaF_F0_aligned2'; % 'deltaF_F0_aligned' 'deltaF_F0'
if strcmp(ps.plot_func,'deltaF_F0')
   ps.x_lim = [stim_delay stim_delay+stim_duration];
   ps.y_lim = [];
else
    ps.x_lim = [-baseline_wind,stim_wind];
    ps.y_lim = [-0.04 0.14];
end
ps.recenterROIs = 0;
ps.show_roi_labels = 1;
ps.close_img_after_save = 0; 
ps.offset_factor = 0;
ps.rem_pbleach = 1;
ps.motion_correct = 0;
ps.analyze_traces = 'deltaF_F0_aligned2';
%%
ps.condition = '15mAB_-0.1mAG';
img_name = [ps.condition '.fits'];
trace_fig = figure;
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%% Get AP peaks
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  
fig_dir = [ps.condition filesep 'fig_' roiset_filename_no_ext];
means = datai.func_output.mean; % mean signal within each roi
% baselines = datai.func_output.baseline; % baseline before each stim, for each roi
AP_window = [15 50]*1e-3; 
[tAP, mean_APs_all, deltaF_F0_all, peak_frames_all] = ...
    extractAPsFromTrain(means,exp_settings,'method',1,...
    'save_fig',1,'fig_dir',fig_dir,...
    'fig_basename',[img_name,'_APs'],'AP_window',AP_window,...
    'biphasic_mode',0); 
%%
ps.condition = '15mAB_1mAG';
trials_data = plotTrials({},exp_settings,roiset_filename,...
                        ps);
%% Plot all conditions
ps.show_diff_image = [4]; % can include [1,2,3, 4]
ps.load_processed_data = 1;
ps.save_fig = 2; 
ps.plot_func = 'deltaF_F0_aligned';
ps.roi_func_mode = 'separate';
ps.motion_correct = 1;
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  
amps = [-1,-0.1,0,0.1,1];
conditions = arrayfun(@(x) sprintf('15mAB_%gmAG',x),amps,'UniformOutput',0);
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                            ['figs_',roiset_filename_no_ext]);
summary_datafile = sprintf('%s_%s_%s_%s_%s',exp_date,reporter,dish,ps.roi_func_mode,...
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
ps.y_lim = [-0.4 1.05];
% ps.y_lim = [-0.04 0.2];
ps.x_lim = [-0.01 0.01];
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
% summary_fig_dir = fullfile(data_fold,out.exp_date,out.reporter,out.dish,...
%             ['figs_',out.roiset_filename_no_ext,'_' out.plot_settings.roi_func_mode '_APwave']);       
plotExpDefaultSummaryStats(out,out.plot_settings,...
                         'plot_inds',plot_inds,'summary_fig_dir',summary_fig_dir,...
                         'save_fig',1) 
%% For sep roi set
mean_fwhm = cell2mat(out.mean_fwhm);