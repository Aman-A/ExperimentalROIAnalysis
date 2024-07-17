%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240710';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish1';
div = 15; 

supra_amp = 3; 
% roiset_filename = 'RoiSet_auto_pos0.mat';
roiset_filename = 'RoiSet_pc_pos0.zip';

num_stim = 20; 
num_trains = 2; 
del = 0.5; % sec 
freq = 2; % Hz
dur = (num_stim)/freq; 
stim_vals = defineStimTrains(del,freq,dur,num_trains,num_stim/freq); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.4; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 100; % sampling rate (frames/sec)
stim_pulse_durs2_all = [10,0.25,0.1,0.02,0.001];
stim_vals2_all = [10.25,arrayfun(@(x) defineStimTrain(10.5 - x,freq,10),...
                                    stim_pulse_durs2_all(2:end),'UniformOutput',0)]; 
exp_settings = ExperimentSettings(); 
for i = 1:length(stim_pulse_durs2_all)
    stim_pulse_dur2 = stim_pulse_durs2_all(i);
    stim_vals2 = stim_vals2_all{i};
    exp_settings(i) = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                      units,sampling_rate,'stim_vals2',stim_vals2,...
                                      'stim_pulse_dur2',stim_pulse_dur2); % automatically converts to frames
end
% Optional settings
ps = plotTrialSettings();
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div;
ps.show_diff_image = [4]; % can include [1,2,3,4]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate'; % combine or separate
ps.save_processed_data = 1;
ps.load_processed_data = 0; 
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0' 'deltaF_F0_aligned2'
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, baseline_wind+stim_wind*num_trains];
else
    ps.x_lim = [0.1 stim_vals(end) + stim_wind];
end
ps.recenterROIs = 0;
ps.transform_type = 'none'; % 'none' or 'displace'         
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,...
    sprintf('%gmABi_50VpmG_10s/%gmABi_50VpmG_10s.fits',supra_amp,supra_amp)); 
ps.show_roi_labels = 1; 
ps.close_img_after_save = 0;   
ps.roi_func_fig_size = [19.8 22]; 
ps.overlay_trials = 0; 
ps.offset_factor = 0.4;
ps.analyze_traces = 'deltaF_F0_aligned2';
ps.motion_correct = 0;
ps.rem_pbleach = 0; 
ps.roi_func_sbar_len = 0.5;
ps.analysis_funcs = {'peaks','peak_times','poststim_ints','decay_fit'};
ps.spike_window = 0.08;
ps.blank_frame_inds = 1;
%%
supra_amp = 3; 
pulse_ind = 1; 
ps.condition = sprintf('%gmABi_50VpmG_%gs',...
            supra_amp,stim_pulse_durs2_all(pulse_ind));
img_name = [ps.condition '.fits'];
trace_fig = figure('Units','normalized'); trace_fig.Position(1:2) = [1 0.32]; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings(pulse_ind),roiset_filename,...
                   trace_axis,ps);

mean_dF2 = mean(datai.func_output.deltaF_F0_aligned2,4); % average within ROI
peaks_all = max(mean_dF2(exp_settings(1).baseline_wind+1:exp_settings(1).baseline_wind+8,:,:),[],1);
mean_peaks_before = peaks_all(1,:,1);
mean_peaks_during = peaks_all(1,:,2);
mean_dF2_normb = mean_dF2./mean_peaks_before;
mean_dF2_normb_mean = squeeze(mean(mean_dF2_normb,2));
per_change = 100*(mean_peaks_during - mean_peaks_before)./mean_peaks_before;
include_rois_thresh = 0.06;
include_rois = mean_peaks_before > include_rois_thresh; 
% include_rois = 35:38; 
mean_per_change = mean(per_change);
std_per_change = std(per_change,0);
sem_per_change = std_per_change/sqrt(datai.rois.num_rois);

fig = figure('Position',[530 710 1310 590]); 
subplot(1,3,1)
plot(datai.func_output.ta2,...
            squeeze(mean(datai.func_output.deltaF_F0_aligned2,[2 4])))
box off; title(img_name,'Interpreter','none'); 
xlabel('time (sec)'); ylabel('\Delta F/F_{0}'); 
legend('Before','During E','Box','off')
subplot(1,3,2)
plot(datai.func_output.ta2,mean_dF2_normb_mean./max(mean_dF2_normb_mean(:,1)));
% plot(datai.func_output.ta2,...
%             squeeze(mean(datai.func_output.deltaF_F0_aligned2(:,include_rois,:,:),[2 4])))
% title(sprintf('ROIs > %.2f',include_rois_thresh),'Interpreter','none'); 
title('Norm to before within ROI')
box off; 
xlabel('time (sec)'); ylabel('\Delta F/F_{0} (norm.)'); 
subplot(1,3,3)
plot([1 2],[mean_peaks_before;mean_peaks_during],'-o');
xlim([0.5 2.5]);
ax = gca; ax.XTick = [1 2];
ax.XTickLabel = {'Before','During'};
box off; 
title(sprintf('Per change (mean +/- std): %.2f +/- %.2f',...
        mean_per_change,std_per_change))

%% Plot trials within each condition
pulse_ind = 2; 
ps.condition = sprintf('control_2mABi_1mAG_%gs',stim_pulse_durs2_all(pulse_ind));
img_names = {}; % use all images in condition folder
trials_data = plotTrials(img_names,exp_settings(pulse_ind),roiset_filename,ps);
%% Save summary data from all train trials as experiment output file
ps.show_diff_image = [4]; % can include [1,2,3, 4]
ps.load_processed_data = 0;
ps.save_fig = 2; 
ps.plot_func = 'deltaF_F0';
ps.roi_func_mode = 'separate';

roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                            ps.registration_rec);  

data_suffix = 'train';
pws = [stim_pulse_durs2_all];
amps = [50*ones(1,length(unique(pws)))];
conditions = arrayfun(@(x,y) sprintf('%gmABi_%gVpmG_%gs',supra_amp,x,y),amps,pws,'UniformOutput',0);

if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, 1.4];    
    ps.y_lim = []; 
else
    ps.x_lim = [0.1 stim_vals(end) + stim_wind];
    ps.y_lim = [];
end

summary_fig_fold = fullfile(data_fold,exp_date,reporter,dish,...
                            ['figs_',roiset_filename_no_ext '_' data_suffix]);
summary_datafile = sprintf('%s_%s_%s_%s_%s_%s',exp_date,reporter,dish,ps.roi_func_mode,...
                                    roiset_filename_no_ext,data_suffix);
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
out = plotTrials_multipleConditions(conditions,ps,[exp_settings],...
                                    roiset_filename,...                               
                                   'summary_fig_dir',summary_fig_fold,...
                                   'summary_datafile',summary_datafile,...
                                   'plot_overlaid',0);
% set(0,'DefaultFigureVisible','on') % to avoid window taking screen focus
%%
cond_inds = []; 
pws = [stim_pulse_durs2_all];
amps = [50*ones(1,length(unique(pws)))];
cond_names = arrayfun(@(x,y) sprintf('%gmA_%gs',x,y),amps,pws,'UniformOutput',0);
sort_amp_ind = 1;
save_figs = 1;
norm_to_cont = 0;
plot_roi_ind = 1; 
plot_figs = [1,2,5:7]; % Select analysis figures to plot
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

if exist('out','var')
    analyze_DCmod_GluSnFR3_experiment2(out,...
                        cond_inds,cond_names,sort_amp_ind,save_figs,...
                        'plot_figs',plot_figs,'plot_roi_ind',plot_roi_ind,...
                        'norm_to_cont',norm_to_cont,'data_file_suffix',data_suffix,...
                        'data_fold',data_fold,'analysis_fig_fold',...
                        summary_fig_fold);
else
    data_params.exp_date = exp_date;
    data_params.reporter = reporter;
    data_params.dish = dish; 
    data_params.roiset_filename = roiset_filename_no_ext; 
    analyze_DCmod_GluSnFR3_experiment2(data_params,...
                        cond_inds,cond_names,sort_amp_ind,save_figs,...
                        'plot_figs',plot_figs,'plot_roi_ind',plot_roi_ind,...
                        'norm_to_cont',norm_to_cont,'data_file_suffix',data_suffix,...
                        'data_fold',data_fold,'analysis_fig_fold',...
                        summary_fig_fold);
end
%%
pw_labels = [sprintf('%g s',pws(1)),numericVec2chars(pws(2:end)*1e3,'%g ms')];
% mean across APs within train and trials
mean_dF_rois = cellfun(@(x) mean(x,[4 5]),out.deltaF_F0_aligned2_all,'UniformOutput',0); % mean within ROis

mean_dF = cellfun(@(x) squeeze(mean(x,2)),mean_dF_rois,'UniformOutput',0); % mean across ROIs
peaks_mean_all = cell2mat(cellfun(@(x) max(x,[],1),mean_dF,'UniformOutput',0)');
peak_change_all = 100*(peaks_mean_all(:,2:end) - peaks_mean_all(:,1))./peaks_mean_all(:,1);

% Plot - averaged across ROIs before extracting peaks
fig = figure; 
b = bar(peak_change_all,'FaceColor',0.8*[1 1 1],'EdgeColor','k');
box off; 
ax = gca;
ax.XTick = 1:length(pw_labels);
ax.XTickLabel = pw_labels;
ax.YLabel.String = 'Peak change (%)';
ylim([0 55]);
ax.YGrid = 'on';
if save_figs
    printFig(fig,summary_fig_fold,'mean_peak_change')
end
%% Plot - average within ROIs
peaks_rois = cellfun(@(x) squeeze(max(x,[],1)),mean_dF_rois,'UniformOutput',0);
peaks_rois_per_change = cell2mat(cellfun(@(x) 100*(x(:,2:end)-x(:,1))./x(:,1),peaks_rois,'UniformOutput',0));
mean_peaks_rois_per_change = mean(peaks_rois_per_change,1);
std_peaks_rois_per_change = std(peaks_rois_per_change,0,1);
sem_peaks_rois_per_change = std_peaks_rois_per_change/sqrt(out.rois_all{1}{1}.num_rois);

% Plot - averaged across ROIs before extracting peaks
fig = figure; 
b = bar(mean_peaks_rois_per_change,'FaceColor',0.8*[1 1 1],'EdgeColor','k',...
        'FaceAlpha',1);
hold on;
errorbar(mean_peaks_rois_per_change,sem_peaks_rois_per_change,'ko')
box off; 
ax = gca;
ax.XTick = 1:length(pw_labels);
ax.XTickLabel = pw_labels;
ax.YLabel.String = 'Peak change (%)';
ylim([0 55]);
ax.YGrid = 'on';
if save_figs
    printFig(fig,summary_fig_fold,'peak_change_mean_sem_rois')
end
%% Plot peaks averaged across ROIs over time
% mean across ROIs and trials
% num_frames x num_trains x num_stim
mean_dF_rois_train = cellfun(@(x) squeeze(mean(x(:,:,:,:,2),[2 5])),out.deltaF_F0_aligned2_all,...
                                'UniformOutput',0); 
peaks_rois_train = cellfun(@(x) squeeze(max(x,[],1)),mean_dF_rois_train,...
                            'UniformOutput',0);
peaks_rois_train_nmean = cellfun(@(x) x/mean(x(1,:)),peaks_rois_train,...
                            'UniformOutput',0);
plot_peaks_str = 'norm_mean'; % 'abs' or 'norm_mean'

if strcmp(plot_peaks_str,'norm_mean')
    plot_peaks = peaks_rois_train_nmean;
    ylabel_str = {'Peak GluSnFR3 \Delta F/F_{0}','(norm. mean before)'};
    mean_ys_before = ones(1,length(pws));    
    fig_name = 'peak_vs_time_norm_mean_before';
    yax_lims = [0.5 1.7];
else
    plot_peaks = cellfun(@(x) x*100,peaks_rois_train,'UniformOutput',0);
    ylabel_str = 'Peak GluSnFR3 \Delta F/F_{0} (%)';
    mean_ys_before = cellfun(@(x) 100*mean(x(1,:)),peaks_rois_train,'UniformOutput',1);
    fig_name = 'peak_vs_time_abs';
    yax_lims = [0 12];
    % yax_lims = [];
end
mean_ys_during = cellfun(@(x) mean(x(2,:)),plot_peaks,'UniformOutput',1);

fig = figure('Units','inches'); 
% fig.Position(3:4) = [7.7 8.2]; % 5 x 1 fig
fig.Position(3:4) = [18 4]; % 1 x 5 fig
for i = 1:length(pws)    
    subplot(1,length(pws),i);
    plot(1:exp_settings(1).num_stim,plot_peaks{i}(1,:),'-ko'); % before
    hold on;
    plot(exp_settings(1).num_stim + 1:2*exp_settings(1).num_stim,...
            plot_peaks{i}(2,:),'-ro'); % during
    plot([1 exp_settings(1).num_stim],mean_ys_before(i)*[1 1],'--',...
        'Color',0.4*[1 1 1])
    plot([1+exp_settings(1).num_stim,2*exp_settings(1).num_stim],...
        mean_ys_during(i)*[1 1],'--','Color',[1 0 0])
    if i == 1
        ylabel(ylabel_str);
    end
    box off;
    if ~isempty(yax_lims)
        ylim(yax_lims);
    end
    title(pw_labels{i});
    xlabel('AP (#)')
end
if isempty(yax_lims)
    setAxesUniformLim(fig,'YLim');
end
if save_figs
    printFig(fig,summary_fig_fold,fig_name)
end