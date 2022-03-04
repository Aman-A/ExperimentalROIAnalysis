%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = getDataFold();
exp_date= '20211005';
reporter = 'GluSnFR3';
dish = 'dish1';
div = 15; 
condition = 'control'; % 'control', '5nM_DTX', '50nM_DTX'
roiset_filename = 'RoiSet_pos0';
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

% Plot settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.condition = condition;
ps.show_diff_image = [3]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'combine'; % 'combine' or 'separate'
ps.save_processed_data = 1;
ps.load_processed_data = 0;
ps.save_fig = 0;
if strcmp(ps.roi_func_mode,'combine')
    ps.y_lim = [-0.2 1.4];
else
    ps.y_lim = [];
end
ps.x_lim = [-baseline_wind,stim_wind*2]; 
ps.recenterROIs = 0;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0'
ps.transform_type = 'displace'; % 'none' or 'displace'
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,...
                                          'burst','control.fits'); 
ps.show_roi_labels = 1;  
ps.close_img_after_save = 0;
%%
ps.condition = 'control'; % 'control', '50nM_DTX'
img_name = 'control'; 
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%% Plot multiple trials, same condition
ps.condition = 'control'; % 'control', '50nM_DTX'
img_names = {}; % use all images in condition folder
trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
%% Plot multiple trials, multiple conditions       
conditions = {'control','10nM_DTX'}; 
ps.save_fig = 1;
ps.plot_func = 'deltaF_F0';
ps.show_diff_image = [3];      
ps.roi_func_mode = 'separate'; % 'combine' or 'separate'
if strcmp(ps.roi_func_mode,'combine')
    ps.y_lim = [-0.2 1.4];
else
    ps.y_lim = [];
end
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, stim_wind];
else
    ps.x_lim = [-0.2 stim_vals(end) + stim_wind];
end
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
out = plotTrials_multipleConditions(conditions,ps,exp_settings,...
                                    roiset_filename); 
% set(0,'DefaultFigureVisible','on')
%% Re-plot traces overlaid
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
            ['figs_',out.roiset_filename_no_ext,'_' out.plot_settings.roi_func_mode]);       
ps.plot_func = 'deltaF_F0';
ps.x_lim = [-0.2 0.4]; 
ps.y_lim = [];
cond_inds = [];
plotExperimentTracesOverlaidGrid(out,ps.plot_func,...
                                'fig_dir',summary_fig_dir,...                                
                                'save_fig',1,...
                                'y_lim',ps.y_lim,...
                                'x_lim',ps.x_lim,'cond_inds',cond_inds);
%% Plot summary data
plot_inds = [1,2,3,4,5];
plotExpDefaultSummaryStats(out,out.plot_settings,'plot_inds',plot_inds,...
                         'roi_set_filename',roiset_filename,'save_fig',1) 
%% Generate diff image stack
stack_mode = 'diff'; % or 'bsline'
img_stack_name = sprintf('%s_%s_%s_%s_img_stack',exp_date,reporter,dish,...
                         stack_mode); 
makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),...
                      conditions,exp_settings,'img_stack_name',img_stack_name,...
                      'img_mode',stack_mode)  
%% Glutamate normalization
glut_img_name = 'glut_5mM';
ps.condition = 'glut';
ps.x_lim = [];
ps.y_lim = [];
ps.show_diff_image = [3]; 
ps.save_fig = 2; 
glut_exp_settings = ExperimentSettings(150,100,50,'frames',2);
mean_wind = []; 
[norm_out,ss_dFF0,glut_exp_settings] = analyzeGlutNormTrial(glut_img_name,...
                                        glut_exp_settings,roiset_filename,...
                                        ps,mean_wind,out,...
                                        'check_settings',1);
%% Plot glutamate normalized summary figures
plot_inds = [1,2];
glut_summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                           ['norm_figs_',roiset_filename '_' norm_out.plot_settings.roi_func_mode]);             
plotExpDefaultSummaryStats(norm_out,norm_out.plot_settings,'plot_inds',plot_inds,...
                         'summary_fig_dir',glut_summary_fig_dir,...
                         'roi_set_filename',roiset_filename,'save_fig',1) 
%% Plot glutamate normalized traces
ps.plot_func = 'deltaF_F0';
ps.x_lim = [-baseline_wind, stim_wind];
ps.y_lim = [];
cond_inds = [];
plotExperimentTracesOverlaidGrid(norm_out,ps.plot_func,...
                                'fig_dir',glut_summary_fig_dir,...                                
                                'save_fig',1,...
                                'y_lim',ps.y_lim,...
                                'x_lim',ps.x_lim,'cond_inds',cond_inds);