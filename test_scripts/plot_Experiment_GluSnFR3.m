%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = getDataFold();
exp_date= '20211005';
reporter = 'GluSnFR3';
dish = 'dish1';
div = 15; 
condition = 'control'; % 'control', '5nM_DTX', '50nM_DTX'
position = 'posX'; 
num_stim = 1; 
del = 3; % sec 
freq = 1/6; % Hz
dur = num_stim/freq; 
stim_vals = defineStimTrain(del,freq,dur); 
stim_wind = 0.5; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 200; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
roi_set_filename = ['RoiSet_' position];
% Optional settings
plot_settings = plotTrialSettings;
plot_settings.data_fold = data_fold;
plot_settings.exp_date = exp_date;
plot_settings.reporter = reporter;
plot_settings.dish = dish;
plot_settings.div = div; 
plot_settings.condition = condition;
plot_settings.position = position;
plot_settings.show_diff_image = [3]; % can include [1,2,3]
plot_settings.filt_width = 0;
plot_settings.funcs = {'mean','baseline','deltaF_F0'};
plot_settings.roi_func_mode = 'combine'; % 'combine' or 'separate'
plot_settings.save_processed_data = 1;
plot_settings.load_processed_data = 0;
plot_settings.save_fig = 0;
if strcmp(plot_settings.roi_func_mode,'combine')
    plot_settings.y_lim = [-0.2 1.4];
else
    plot_settings.y_lim = [];
end
plot_settings.x_lim = [-baseline_wind,stim_wind*2]; 
plot_settings.recenterROIs = 0;
plot_settings.plot_func = 'deltaF_F0'; % 'deltaF_F0'
plot_settings.transform_type = 'displace'; % 'none' or 'displace'
plot_settings.registration_rec = fullfile(data_fold,exp_date,reporter,dish,...
                                          'burst','control.fits'); 
plot_settings.show_roi_labels = 1;  
plot_settings.close_img_after_save = 0;
%%
plot_settings.condition = 'control'; % 'control', '50nM_DTX'
img_name = 'control'; 
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roi_set_filename,...
                   trace_axis,plot_settings);
%% Plot multiple trials, same condition
plot_settings.condition = 'control'; % 'control', '50nM_DTX'
img_names = {}; % use all images in condition folder
trials_data = plotTrials(img_names,exp_settings,roi_set_filename,plot_settings);
%% Plot multiple trials, multiple conditions       
conditions = {'control','10nM_DTX'}; 
positions = repmat({position},1,length(conditions));
img_names = cell(1,length(conditions)); % use all images in condition folder
roi_set_filenames = [repmat({roi_set_filename},1,length(conditions))];
plot_settings.transform_type = 'displace'; % coregister and get displacement field 
plot_settings.registration_rec = fullfile(data_fold,exp_date,reporter,dish,...
                                         'burst','control.fits'); 
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
plot_settings.save_fig = 1;
plot_settings.show_diff_image = [3];      
plot_settings.roi_func_mode = 'separate'; % 'combine' or 'separate'
if strcmp(plot_settings.roi_func_mode,'combine')
    plot_settings.y_lim = [-0.2 1.4];
else
    plot_settings.y_lim = [];
end
if regexp(plot_settings.plot_func,'aligned')
    plot_settings.x_lim = [-baseline_wind, stim_wind];
else
    plot_settings.x_lim = [-0.2 stim_vals(end) + stim_wind];
end
out = plotTrials_multipleConditions(data_fold,exp_date,reporter,dish,...
                               conditions,positions,img_names,exp_settings,...
                               roi_set_filenames,...
                               plot_settings);
% set(0,'DefaultFigureVisible','on')
%% Plot summary data
plot_inds = [1,2,3,4,5,6];
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                           ['figs_',roi_set_filenames{1} '_' plot_settings.roi_func_mode]);       
plotDefaultSummaryStats(out.peaks_deltaF_F0_all,out.poststim_ints_all,out.peak_times_all,...
                         out.baselines_all,out.decay_fits,out.rel_times_cond_starts,...
                         conditions,exp_date,reporter,dish,plot_settings,...
                         'summary_fig_dir',summary_fig_dir,'plot_inds',plot_inds,...
                         'roi_set_filename',roi_set_filenames{1}) 
%% Generate diff image stack
stack_mode = 'diff'; % or 'bsline'
img_stack_name = sprintf('%s_%s_%s_%s_img_stack',exp_date,reporter,dish,...
                         stack_mode); 
makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),...
                      conditions,exp_settings,'img_stack_name',img_stack_name,...
                      'img_mode',stack_mode)  
%% Glutamate normalization
glut_img_name = 'glut_5mM';
plot_settings.condition = 'glut';
plot_settings.x_lim = [];
plot_settings.y_lim = [];
plot_settings.show_diff_image = [3]; 
plot_settings.save_fig = 2; 
glut_exp_settings = ExperimentSettings(150,100,50,'frames',2);
mean_wind = []; 
[norm_out,ss_dFF0,glut_exp_settings] = analyzeGlutNormTrial(glut_img_name,...
                                        glut_exp_settings,roi_set_filename,...
                                        plot_settings,mean_wind,out,...
                                        'check_settings',1);
%% Plot glutamate normalized summary figures
plot_inds = [1,2];
glut_summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                           ['norm_figs_',roi_set_filenames{1}]);       
plotDefaultSummaryStats(norm_out.peaks_deltaF_F0_all,norm_out.poststim_ints_all,...
                        norm_out.peak_times_all,norm_out.baselines_all,[],...
                        norm_out.rel_times_cond_starts,conditions,exp_date,...
                        reporter,dish,plot_settings,...
                        'summary_fig_dir',glut_summary_fig_dir,'plot_inds',plot_inds,...
                         'roi_set_filename',roi_set_filenames{1}) 
%% Plot glutamate normalized traces
plot_settings.plot_func = 'deltaF_F0';
plot_settings.x_lim = [-baseline_wind, stim_wind];
plot_settings.y_lim = [];
cond_inds = [];
plotExperimentTracesOverlaidGrid(norm_out,plot_settings.plot_func,...
                                'fig_dir',glut_summary_fig_dir,...                                
                                'save_fig',1,...
                                'y_lim',plot_settings.y_lim,...
                                'x_lim',plot_settings.x_lim,'cond_inds',cond_inds);