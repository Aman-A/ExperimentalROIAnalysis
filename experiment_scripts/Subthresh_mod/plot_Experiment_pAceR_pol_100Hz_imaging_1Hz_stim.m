%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240130';
reporter = 'pAceR_GluSnFR3';
dish = 'dish1';
div = 14;

% roiset_filename = [2 154 2 510];
roiset_filename = 'RoiSet_pc_pos7_branches.zip';

num_stim = 10; % number desired APs 20 or 100
stim_pulse_dur = 0.5; % pulse duration (sec)
stim_freq = 1; % Hz
stim_delay = 0; % sec % 3 or 5 sec delay
% stim_delay = 0.2; 
stim_duration = (num_stim+1)/stim_freq;
sampling_rate = 100; % sampling rate of camera (frames/sec) - exp time 0.0004815
stim_vals = defineStimTrain(stim_delay,stim_freq,stim_duration); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.7; % window
baseline_wind = 0.2; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate,'stim_pulse_dur',...
                                  stim_pulse_dur); % automatically converts to frames
total_time = stim_vals(end) + stim_wind;
num_frames = ceil(total_time*sampling_rate);
fprintf('Set stim delay to %g sec, duration to %g sec, interval to %g sec\n',...
        stim_delay,stim_duration,1/stim_freq); 
fprintf('F = %.1f Hz, record for %g frames (%.2f sec)\n',...
        sampling_rate, num_frames,total_time); 
% Optional settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
% ps.condition = condition;
ps.show_diff_image = [4]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate';
ps.save_processed_data = 1;
ps.load_processed_data = 0;
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0' 'deltaF_F0_aligned'
% ps.plot_func = 'deltaF_F0'; % 'deltaF_F0' 'deltaF_F0_aligned'
if strcmp(ps.plot_func,'deltaF_F0')
   ps.x_lim = [stim_delay stim_delay+stim_duration];
   ps.y_lim = [];
else
    ps.x_lim = [-baseline_wind,stim_wind];
    ps.y_lim = [];
end
ps.recenterROIs = 0;
ps.show_roi_labels = 1;
ps.close_img_after_save = 0; 
% ps.bin_size = 2;
ps.offset_factor = 0.04; 
ps.peak_mode = [15 50];
% ps.peak_mode = 'min';
ps.diff_image_cmap = 'bluewhitered';
ps.filt_width = 1; 
ps.rem_pbleach = 1;
ps.motion_correct = 0; 
ps.overlay_trials = 0; 
ps.indicator_dir = 1;
ps.roi_func_sbar_len = 0.01; 
ps.offset_factor = 0.01; 
ps.analysis_funcs = {'peaks','peak_times'};
% makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),{'pol_1Hz_500ms_1mAG'},exp_settings,'img_stack_name','diffimagesV','indicator_dir',-1,'filt_width',1,'peak_mode',[15 50]);
% makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),conditions,exp_settings,'img_stack_name','diffimagesV','indicator_dir',-1,'filt_width',1,'peak_mode',[15 50]);
%%
ps.condition = 'pol_1Hz_500ms_2mAG';
img_name = [ps.condition '.fits'];
% ps.condition = 'test_pol';
% img_name = 'trial.fits';
trace_fig = figure; 
ps.roi_func_fig_units = 'inches'; 
ps.roi_func_fig_size = [9.8 6.33]; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%%
img_names = {};
trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
%% Save summary data from all train trials as experiment output file
ps.show_diff_image = [4]; % can include [1,2,3, 4]
ps.load_processed_data = 1;
ps.save_fig = 2; 
ps.plot_func = 'deltaF_F0_aligned';
ps.roi_func_mode = 'separate';
ps.offset_factor = 0.02; 
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  
amps = [-2,-1.5,-1,-0.5,0.5,1,1.5,2];
conditions = arrayfun(@(x) sprintf('pol_1Hz_500ms_%gmAG',x),amps,'UniformOutput',0);

if regexp(ps.plot_func,'aligned')
    ps.roi_func_fig_size = [19.8 19.18];
    ps.x_lim = [-baseline_wind, stim_wind];
%     ps.x_lim = [-baseline_wind, 1.4];    
%     ps.y_lim = [-0.05 0.7]; 
%     ps.y_lim = [-0.05 0.165];
    ps.y_lim = []; 
else
    ps.x_lim = [-0.2 stim_vals(end) + stim_wind];
    ps.y_lim = [];
end

summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                            ['figs_',roiset_filename_no_ext '_pol_' ps.roi_func_mode]);
summary_datafile = sprintf('%s_%s_%s_%s_%s_pol',exp_date,reporter,dish,ps.roi_func_mode,...
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
ps.x_lim = [-0.1 0.7];
cond_inds = [];
norm_peak_ind = 0; 
align_to = 'none';
% align_to = 'max'; 
fig_size = [42.5 22.4];
cols = flipud([ 0.6445         0    0.1484 % for 8
            0.8398    0.1875    0.1523
            0.9531    0.4258    0.2617
            0.9883    0.6797    0.3789
            0.6680    0.8477    0.9102
            0.4531    0.6758    0.8164
            0.2695    0.4570    0.7031
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
%% Check linearity of response
fit_inds = [1:8];
dF_ss_wind = [30 50]; % out.peak_mode
% dF_ss_wind = [22 24];
roi_ind = 2; 
dF_all = cell2mat(cellfun(@(x) x(:,roi_ind),out.mean_deltaF_F0_aligned_all,'UniformOutput',0));
dF_ss = ps.indicator_dir*mean(dF_all(dF_ss_wind(1):dF_ss_wind(2),:),1)';
fit_amps = amps(fit_inds);
fit_dF_ss = dF_ss(fit_inds);
fig = figure; 
plot(fit_amps,fit_dF_ss*100,'ko');
xlabel('Current (mA)');
ylabel('-\Delta F/F_{0} (%)')
box off; grid on;
[b,~,~,~,stats] = regress(fit_dF_ss,[ones(length(fit_amps),1),fit_amps']);
Rsq = stats(1); p = stats(3); 
hold on;
plot(fit_amps,(b(1) + b(2)*fit_amps)*100,'r')
title(sprintf('R^{2} = %.3f, p = %.5f,\n slope = %.1f %%/mA, intercept = %.3f mA',...
     Rsq,p,b(2)*100,b(1)))
hold on; 
printFig(fig,'.',sprintf('ss_polarization_vs_current_linearity_%gamps',length(fit_inds)))
%% quadratic
fig = figure; 
plot(amps,dF_ss*100,'ko');
xlabel('Current (mA)');
ylabel('Steady state \Delta F/F_{0} (%)')
box off; grid on;
pos_amps = amps(amps>0)';
neg_amps = amps(amps<0)';
[b1,~,~,~,stats1] = regress(dF_ss(amps>0),[ones(length(pos_amps),1),pos_amps,pos_amps.^2]);
[b2,~,~,~,stats2] = regress(dF_ss(amps<0),[ones(length(neg_amps),1),neg_amps,neg_amps.^2]);
Rsq1 = stats1(1); p1 = stats1(3); 
Rsq2 = stats1(1); p2 = stats1(3); 
hold on;
pos_amps_fit = linspace(0,max(pos_amps),100);
neg_amps_fit = linspace(0,min(neg_amps),100);
plot(pos_amps_fit,(b1(1) + b1(2)*pos_amps_fit + b1(3)*pos_amps_fit.^2)*100,'r')
plot(neg_amps_fit,(b2(1) + b2(2)*neg_amps_fit + b2(3)*neg_amps_fit.^2)*100,'b')
title(sprintf('Pos: R^{2} = %.3f, p = %.5f,\n Neg: R^{2} = %.3f, p = %.3f',...
     Rsq1,p1,Rsq2,p2))
printFig(fig,'.','ss_polarization_vs_current_quad')