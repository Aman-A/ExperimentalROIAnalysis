%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
data_fold = fullfile(getDataFold(),'AP_prop_polarization_experiments');
exp_date= '221111';
reporter = 'Archon';
dish = 'dish4';
div = 17; 
roiset_filename = 'RoiSet_pc_pos0_dend';
% roiset_filename = 'RoiSet_pc_pos5_bouts_resp';

num_stim = 25; % number desired APs 20 or 100
stim_pulse_dur = 0.1; % pulse duration (sec)
stim_freq = 5; % Hz
stim_delay = 0; % sec % 3 or 5 sec delay
stim_duration = num_stim/stim_freq;
total_time = stim_duration + stim_delay;
sampling_rate = 2000; % sampling rate of camera (frames/sec) - exp time 0.0004815
stim_vals = defineStimTrain(stim_delay,stim_freq,stim_duration); % frames - 1 sec delay (100 Hz sampling time)
stim_wind = 0.2; % window
baseline_wind = 0.05; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate,'stim_pulse_dur',stim_pulse_dur); % automatically converts to frames
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
ps.show_diff_image = []; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'combine';
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0_aligned' 'deltaF_F0'
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
ps.offset_factor = 0;
ps.peak_mode = [10 200]; % frames to average (5 to 100 ms)
ps.diff_image_cmap = 'bluewhitered';
ps.rem_pbleach = 1;
ps.motion_correct = 0; 
ps.overlay_trials = 0;
%%
ps.condition = '25stim_5Hz_pos0_dend';
img_name = 'trial_100ms_-7mAB.fits';
trace_fig = figure;
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%% Get AP peaks
AP_window = [50e-3 200e-3]; 
means = datai.func_output.mean; % mean signal within each roi
[tAP, mean_APs_all, deltaF_F0_all, peak_frames_all] = ...
    extractAPsFromTrain(means,exp_settings,'method',1,...
    'save_fig',1,'fig_dir',[ps.condition filesep 'figs_' roiset_filename],...
    'fig_basename',[img_name,'_APs'],'AP_window',AP_window,'biphasic_mode',0); 
%%
ps.condition = '25stim_5Hz_pos0_dend';
trials_data = plotTrials({},exp_settings,roiset_filename,...
                        ps);
%%
analysis_fold = fullfile(data_fold,exp_date,reporter,dish,'analysis/');
save_analysis_figs = 1;
mean_deltaF_F0_aligned = squeeze(mean(trials_data.deltaF_F0_aligned,3)); 
n_ss_frames = exp_settings.convert2Frames(0.1*stim_pulse_dur);
ss_window = exp_settings.baseline_wind + exp_settings.stim_pulse_dur - n_ss_frames:exp_settings.baseline_wind + exp_settings.stim_pulse_dur;
mean_ss = mean(mean_deltaF_F0_aligned(ss_window,:),1)';
peaks = squeeze(mean(trials_data.analysis.peaks,1));
t = exp_settings.getTimeVector(size(mean_deltaF_F0_aligned,1));
t = t-t(exp_settings.baseline_wind + 1);
img_names = trials_data.img_names';
delims = regexp(img_names,'_');
delims2 = regexp(img_names,'mA');
durs = cellfun(@(x,y) str2double(x(y(1)+1:y(2)-3)),img_names,delims,'UniformOutput',1);
amps = cellfun(@(x,y,z) str2double(x(y(2)+1:z(1)-1)),img_names,delims,delims2,'UniformOutput',1); % mA
elec_col = cellfun(@(x,y) x(y(1)+2),img_names,delims2,'UniformOutput',0);
theta = zeros(length(img_names),1);
theta(amps>0 & strcmp(elec_col,'G')) = 180; 
theta(amps>0 & strcmp(elec_col,'B')) = 270;
theta(amps<0 & strcmp(elec_col,'B')) = 90;
[amps,sort_inds] = sort(amps);
img_names = img_names(sort_inds);
durs = durs(sort_inds);
elec_col = elec_col(sort_inds); 
theta = theta(sort_inds); 
mean_deltaF_F0_aligned = mean_deltaF_F0_aligned(:,sort_inds);
mean_ss = mean_ss(sort_inds);
% Load AP

ap_condition = '25AP_5Hz_pos0_dend';
ap_img_name = 'pos0_dend_15mAG';
ap_data = load(fullfile(data_fold,exp_date,reporter,dish,ap_condition,...
                sprintf('%s-combine-%s-data.mat',ap_img_name,roiset_filename)));
meanAP = mean(ap_data.func_output.deltaF_F0_aligned,[2 3]);
peakAP = max(meanAP);
tAP = ap_data.settings.getTimeVector(length(meanAP)); tAP = tAP-tAP(ap_data.settings.baseline_wind+1);
%% Get time constants
t_dec = t(t >= 0.1); 
t_dec = t_dec - t_dec(1); 
F_dec = mean_deltaF_F0_aligned(t >= 0.1,:);
hyper_pol_inds = F_dec(1,:) < 0;
F_dec(:,hyper_pol_inds) = -1*F_dec(:,hyper_pol_inds);
decay_fit = fitExpDecay(t_dec,F_dec,1);

%%
% Horz 
plot_inds = find(strcmp(elec_col,'G'));
fig = figure; 
plot(t*1e3,mean_deltaF_F0_aligned(:,plot_inds)); 
hold on;
plot(tAP*1e3,meanAP,'k');
box off;
legend([numericVec2chars(amps(plot_inds),'%g mA'); 'AP'],'Box','off')
xlabel('time (ms)'); ylabel('Mean \Delta F/F_{0}')
ylim([-0.2 0.18])
if save_analysis_figs
    printFig(fig,analysis_fold,'horz_pol_traces_dend');
end
% Vert
plot_inds = find(strcmp(elec_col,'B'));
fig = figure; 
plot(t*1e3,mean_deltaF_F0_aligned(:,plot_inds));
hold on;
plot(tAP*1e3,meanAP,'k');
box off;
legend([numericVec2chars(amps(plot_inds),'%g mA'); 'AP'],'Box','off')
xlabel('time (ms)'); ylabel('Mean \Delta F/F_{0}')
ylim([-0.2 0.18])
if save_analysis_figs
    printFig(fig,analysis_fold,'vert_pol_traces_dend');
end
%% Extract traces at same intensity, all directions and plot with fit
plot_amp = 14;
plot_inds = find(abs(amps) == plot_amp & durs == 100);
fig = figure('Position',[476 544 1175 336]); 
subplot(1,2,1)
plot(t*1e3,mean_deltaF_F0_aligned(:,plot_inds));
box off;
legend(numericVec2chars(theta(plot_inds),'%g °'),'Box','off')
title(sprintf('%g mA',plot_amp));
tau_inds = decay_fit.taud1(plot_inds)*1e3;
rsq_inds = decay_fit.rsquare(plot_inds);
xlabel('time (ms)'); ylabel('Mean \Delta F/F_{0}')
subplot(1,2,2); 
plot(t_dec*1e3,F_dec(:,plot_inds));
hold on; box off;
for i = 1:length(plot_inds)
    plot(decay_fit.t_fits{plot_inds(i)}*1e3,decay_fit.fitobjs{plot_inds(i)}(decay_fit.t_fits{plot_inds(i)}),'--k');
end
xlabel('time (ms)'); 
leg_str = [numericVec2chars(tau_inds,'\\tau_{d} = %.2f ms')',numericVec2chars(rsq_inds,' R^{2} = %.3f')'];
legend(strcat(leg_str(:,1),leg_str(:,2)),'Box','off','Location','best')
if save_analysis_figs
    printFig(fig,analysis_fold,sprintf('decay_fit_%gmA_pol_traces_dend',plot_amp));
end
%%
un_amps = unique(abs(amps)); 
fig = figure('Position',[303 493 1260 415]); 
subplot(1,2,1)
for i = 1:length(un_amps)
    ampi = un_amps(i); 
    polarplot((pi/180)*theta(abs(amps) == ampi),abs(mean_ss(abs(amps)==ampi)),'o'); hold on;
%     polarplot((pi/180)*theta(abs(amps) == ampi),abs(mean_ss(abs(amps)==ampi))/peakAP,'o'); hold on;
end
legend(numericVec2chars(un_amps,'%g mA'),'Box','off')
% ylabel('Steady state mean \Delta F/F_{0} (norm. to AP peak)')
% fig = figure;
cols = lines(2); 
leg_strs = cell(2,1);
subplot(1,2,2)
for i = 0:1
    th_inds = abs(abs(cos(theta*pi/180))-i) < eps & durs == 100;
    plot(amps(th_inds),mean_ss(th_inds),'o','Color',cols(i+1,:)); hold on;
%     plot(amps(th_inds),mean_ss(th_inds)/peakAP,'o'); hold on;
    X = [ones(size(amps(th_inds))),amps(th_inds)];
    y = mean_ss(th_inds);
    [b,bint,r,rint,stats] = regress(y,X);
    rsq = stats(1); p = stats(3); 
    beta = b(2)/std(X(:,2),0,1); 
    plot([min(amps(th_inds)),max(amps(th_inds))],...
        b(2)*[min(amps(th_inds)),max(amps(th_inds))]+b(1),'-','Color',cols(i+1,:));
    leg_strs{i+1} = sprintf('R^{2} = %.2f, slope = %.1f %%/mA, p = %.2f',...
                            rsq,b(2)*100,p);
    if ~isnan(p) && p > 0.05
        fprintf('WARNING: p = %f\n',p)
    end
end
box off;
legend('Vertical',leg_strs{1},'Horizontal',leg_strs{2},...
        'Box','off','Location','NorthWest')
xlabel('Current intensity (mA)');
ylabel('Steady state of mean \Delta F/F_{0}')
% ylabel('Steady state of mean \Delta F/F_{0} (norm. to AP peak)')
if save_analysis_figs
    printFig(fig,analysis_fold,'ss_pol_vs_amp_dend');
end
