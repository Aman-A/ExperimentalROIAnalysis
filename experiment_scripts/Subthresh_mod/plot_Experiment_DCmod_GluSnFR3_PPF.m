%% Experiment measuring effect of subthreshold pre-pulse on single AP vG-pH 
% responses
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '241022';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish2';
div = 21; 

% roiset_filename = 'RoiSet_auto_pos2.mat';
roiset_filename = 'RoiSet_pc_pos0.zip';

supra_amp = 2.8; % mA - bipolar stimulus amp

sampling_rate = 100; % sampling rate (frames/sec)
stim_wind = 0.4; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
% suprathreshold stimuli
del1 = 2.5; % delay for start of single pulse (first stimulus)
del2 = 7.5; % delay for start of paired pulse (second set of stimuli)
pp_isi = 0.05; % paired pulse interstim interval
stim_vals = [del1,del2,del2+pp_isi];
stim_pulse_dur = 0.001; % sec - pulse duration
exp_settings_subEoff = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                    units,sampling_rate,'stim_pulse_dur',stim_pulse_dur);
% subthreshold stimuli
sub_del1 = 0.5; % sec - first subthreshold pulse
sub_del2 = 5.5; % sec - second subthreshold pulse
stim_vals2 = [sub_del1,sub_del2];
stim_pulse_dur2 = 2.1; % sec
exp_settings_subEon = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                    units,sampling_rate,'stim_pulse_dur',stim_pulse_dur,...
                                    'stim_vals2',stim_vals2,'stim_pulse_dur2',stim_pulse_dur2);
exp_settings_all = [exp_settings_subEoff,exp_settings_subEon];
% Optional settings
ps = plotTrialSettings();
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div;
ps.show_diff_image = [3]; % can include [1,2,3,4]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate'; % combine or separate
ps.save_processed_data = 1;
ps.load_processed_data = 0; 
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0' 'deltaF_F0_aligned'
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, 1.4];
else
    ps.x_lim = [0 8];
%     ps.x_lim = [-baseline_wind stim_vals(end)-stim_vals(1) + stim_wind];
end
ps.recenterROIs = 0;
ps.transform_type = 'none'; % 'none' or 'displace'         
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,...
                        sprintf('%gmABi_2s_50VpmG_0ms_interv',supra_amp),...
                        sprintf('%gmABi_2s_50VpmG_0ms_interv_1.fits',supra_amp)); 
ps.show_roi_labels = 1;  
ps.close_img_after_save = 0;   
ps.roi_func_fig_size = [19.8 22]; 
% ps.roi_func_fig_size = [30 13];
ps.overlay_trials = 0; 
ps.analyze_traces = 'deltaF_F0_aligned';
ps.motion_correct = 0;
ps.rem_pbleach = 0; 
ps.offset_factor = 0.4;
ps.roi_func_sbar_len = 0.5; 
ps.analysis_funcs = {'peaks','peak_times','poststim_ints'};
ps.blank_frame_inds = 1;
%%
cond_ind = 1; 
ps.condition = sprintf('%gmABi_PPF_0VpmG',supra_amp);
img_name = [ps.condition '_1.fits'];
trace_fig = figure('Units','normalized'); trace_fig.Position(1:2) = [1 0.4]; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings_all(cond_ind),roiset_filename,...
                   trace_axis,ps);
% snr = max(datai.func_output.deltaF_F0(exp_settings_all(cond_ind).stim_vals(1):end))/std(datai.func_output.deltaF_F0(exp_settings_all(cond_ind).baseline_wind_inds),0);
% fprintf('1AP SNR = %.3f\n',snr)
%% Plot trials within each condition
ps.condition = '0mA_100ms'; % 'control', '5nM_DTX', '50nM_DTX'
% img_names = '20mAB_50AP_25Hz_0mAG_3.fits'; % use all images in condition folder
img_names = {};

% roiset_filenames = {'RoiSet_pc.zip','RoiSet_pc.zip','RoiSet_pc.zip'};

trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
%% Save summary data from all train trials as experiment output file
ps.show_diff_image = []; % can include [1,2,3, 4]
ps.load_processed_data = 1;
ps.save_fig = 0; % 1 - save trials overlaid, 2- save individual trials as separate files
ps.plot_func = 'none';
ps.roi_func_mode = 'combine';
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  


data_suff = '4mABi';
amps = [0,50];
conditions = arrayfun(@(x) sprintf('%gmABi_PPF_%gVpmG',supra_amp,x),...
                                    amps,'UniformOutput',0);


if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind stim_wind];
    ps.y_lim = []; 
else
    ps.x_lim = [0 8];
    ps.y_lim = [];
end

summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                            ['figs_',roiset_filename_no_ext '_' data_suff]);
summary_datafile = sprintf('%s_%s_%s_%s_%s_%s',exp_date,reporter,dish,ps.roi_func_mode,...
                                    roiset_filename_no_ext,data_suff);
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
out = plotTrials_multipleConditions(conditions,ps,exp_settings_all,...
                                    roiset_filename,...                               
                                   'summary_fig_dir',summary_fig_dir,...
                                   'summary_datafile',summary_datafile,...
                                   'plot_overlaid',1);
% set(0,'DefaultFigureVisible','on') % to avoid window taking screen focus
%%
keep_trials = [1:20]; 
dF_aligned_all = out.deltaF_F0_aligned_all; % {[nt x nrois x nstim x ntrials],..}
mean_dF_trials = cellfun(@(x) mean(x(:,:,:,keep_trials),4),...
                    dF_aligned_all,'UniformOutput',0);
mean_dF_trials = cell2mat(reshape(mean_dF_trials,1,1,1,length(mean_dF_trials))); % nt x nrois x nstim (1 AP vs 2 AP) x nconditions (DC off or on)
mean_dF_trials = mean_dF_trials(:,:,1:2,:); % just use single and first of paired pulse
% normalize to 0 mA within sets of 3 sweeps (most recent control sweep)
stim_frame = exp_settings_all(1).baseline_wind + 1;
peaks_dF = max(mean_dF_trials(stim_frame:end,:,:,:),[],1);
mean_dF_norm_trial = mean_dF_trials./peaks_dF(1,:,1,:); % normalize to stim 1 within condition
peaks_dF_norm = peaks_dF./peaks_dF(1,:,1,:);
% Paired pulse ratio (PPR) with DC off and on in all ROIs
pprs = squeeze(peaks_dF_norm(:,:,2,:)); % num_rois x stim_amp (off or on)
if size(peaks_dF_norm,2) == 1
    pprs = pprs';
end
mean_pprs = mean(pprs,1); std_pprs = std(pprs,0,1);
mean_dF = squeeze(mean(mean_dF_trials,2));
std_dF = squeeze(std(mean_dF_trials,0,2));
peaks_mean_dF = squeeze(max(mean_dF(stim_frame:end,:,:),[],1)); % num_stim x stim_amp (off or on)
pprs_mean_dF = peaks_mean_dF(2,:)./peaks_mean_dF(1,:);
mean_dF_norm = squeeze(mean(mean_dF_norm_trial,2));
std_dF_norm = squeeze(std(mean_dF_norm_trial,0,2));
peaks_mean_dF_norm = squeeze(max(mean_dF_norm(stim_frame:end,:,:),[],1)); % num_stim x stim_amp (off or on)
pprs_mean_dF_norm = peaks_mean_dF_norm(2,:)./peaks_mean_dF_norm(1,:);
num_rois = size(mean_dF_trials,2);
ta = exp_settings_all(1).getTimeVector(size(mean_dF_trials,1));
ta = ta - ta(stim_frame); 
stim_cols = {'k', 'r'};

% Plot raw
fig = figure('Units','inches'); 
fig.Position = [4.5625       2.0312       11.812       6.6042]; 
for i = 1:size(mean_dF,3)
    ax = subplot(1,size(mean_dF,3),i);
    for j = 1:size(mean_dF,2)
%         plot(ta,mean_dF_norm(:,j,i),'Color',stim_cols{i}); 
        shadedErrorBar(ta+(j-1)*(0.1 + range(ta)),100*mean_dF(:,j,i),...
                        100*std_dF(:,j,i)/sqrt(num_rois),'lineProps',...
                    {'Color',stim_cols{i}});
        hold on;        
    end
    box off;     
    if i == 1        
        ylabel('\DeltaF/F_{0} (%)')
    end
    xlabel('time (sec)');
end
setAxesUniformLim(fig,'YLim');
printFig(fig,'.',sprintf('mean_deltaF_aligned_%s',data_suff));

% Plot norm to 1st AP (norm to mean trace)
fig = figure('Units','inches'); 
fig.Position = [4.5625       2.0312       11.812       6.6042]; 
for i = 1:size(mean_dF,3)
    ax = subplot(1,size(mean_dF,3),i);
    for j = 1:size(mean_dF,2)
%         plot(ta,mean_dF_norm(:,j,i),'Color',stim_cols{i}); 
        shadedErrorBar(ta+(j-1)*(0.1 + range(ta)),mean_dF(:,j,i)/max(mean_dF(stim_frame:end,1,i)),...
                        std_dF(:,j,i)/(max(mean_dF(stim_frame:end,1,i))*sqrt(num_rois)),'lineProps',...
                    {'Color',stim_cols{i}});
        hold on;        
    end
    box off;     
    if i == 1        
        ylabel('\DeltaF/F_{0} (norm. to 1st AP)')
    end
    xlabel('time (sec)');
    plot(ax.XLim,[1 1],'--','Color',0.4*[1 1 1]); 
    ppri = max(mean_dF(stim_frame:end,j,i)/max(mean_dF(stim_frame:end,1,i)));
    plot(ax.XLim,ppri*[1 1],'--','Color',stim_cols{2}); 
    title(sprintf('%g V/m: PPR = %.2f',amps(i),ppri))
end
setAxesUniformLim(fig,'YLim');
printFig(fig,'.',sprintf('mean_deltaF_aligned_norm_%s',data_suff));
% Plot norm to 1st AP (within ROI)
% fig = figure('Units','inches'); 
% fig.Position = [4.5625       2.0312       11.812       6.6042]; 
% for i = 1:size(mean_dF_norm,3)
%     ax = subplot(1,size(mean_dF_norm,3),i);
%     for j = 1:size(mean_dF_norm,2)
% %         plot(ta,mean_dF_norm(:,j,i),'Color',stim_cols{i}); 
%         shadedErrorBar(ta+(j-1)*(0.1 + range(ta)),mean_dF_norm(:,j,i),...
%                         std_dF_norm(:,j,i)/sqrt(num_rois),'lineProps',...
%                         {'Color',stim_cols{i}});
%         hold on;        
%     end
%     box off; 
%      if i == 1       
%         ylabel('\DeltaF/F_{0} (norm. to 1st AP)')
%     end
%     xlabel('time (sec)');
% %     plot(ax.XLim,[1 1],'--','Color',0.4*[1 1 1]);
% end
% setAxesUniformLim(fig,'YLim');


%% Mean peak +/- STD (across trials)
peaks_dF = squeeze(peaks_dF);
peaks_dF_norm = squeeze(peaks_dF_norm); 
x_vals = [1 2;4 5];
fig = figure('Units','inches'); fig.Position = [1 1 9.5 5.67];
ax = subplot(1,2,1);
for i = 1:length(stim_cols)
    plotBarPlot_ErrBars_Points(peaks_dF(:,:,i),...
        'bar_labels','',...
        'connect_pts',1,'bar_cols',stim_cols{i},'pt_cols',0.4*[1 1 1],'bar_alphas',0.2,...
        'x_vals',x_vals(i,:));
    hold on;
end
ylabel('Peak \Delta F/F_{0}');
ax.XTick = sort(x_vals(:));
ax.XTickLabel = {'1 AP','2 AP','1 AP','2 AP'};
% ax.XTick = [1.5 4.5]; 
% ax.XTickLabel = {'DC off','DC on'}; 
ax = subplot(1,2,2);
plotBarPlot_ErrBars_Points(pprs,...
    'bar_labels',{'DC off','DC on'},'connect_pts',1,'bar_cols',stim_cols,...
    'pt_cols',0.4*[1 1 1],'bar_alphas',0.2,'x_vals',x_vals(1,:));
ylabel('PPR');
[p,h] = signrank(pprs(:,1),pprs(:,2));
hold on;
if h
   fprintf('PPR sig diff (Wilcoxon sign rank): p = %.2f\n',p)
else
   fprintf('PPR not sig diff (Wilcoxon sign rank): p = %.2f\n',p)
  plot(x_vals(1,:),ax.YLim(2)*[1 1],'k');
  text(mean(x_vals(1,:)),ax.YLim(2)*1.05,'n.s.','FontSize',16,...
        'FontName','Arial','HorizontalAlignment','center')
end
printFig(fig,'.',sprintf('peaks_ppr_bar_%s',data_suff));
