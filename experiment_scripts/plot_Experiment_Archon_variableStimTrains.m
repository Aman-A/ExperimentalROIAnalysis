%% Plot Archon responses to different frequency trains, multiple trains applied within single trials
% Overlay single trials on same figure by running with different img_name
data_fold = getDataFold();
exp_date= '20220412';
reporter = 'Archon';
dish = 'dish1';
div = 14; 
condition = '50Hz'; % 'control', '5nM_DTX', '50nM_DTX'
% roiset_filename = [2 98 2 96]*.5;
roiset_filename = 'RoiSet_pos7';
num_stim = 2; 
del = 0.5; % sec 
train_interval = 0.5; % 1.25 sec - time after start of each stim train to start next train
freqs_all = [4, 10, 20, 50]; % Hz
stim_wind = 0.02; % window
baseline_wind = 0.015; % frames before stim/s to take baseline
num_trains = 25;
sampling_rate = 2000; % sampling rate (frames/sec)
units = 'sec'; % specify units 'frames' or 'sec' 
num_freqs = length(freqs_all);
exp_settings(num_freqs,1) = ExperimentSettings;
durs = zeros(num_freqs,1);
doric_dels = zeros(num_freqs,1); 
for i = 1:num_freqs    
    durs(i) = num_stim/freqs_all(i);     
    doric_dels(i) = train_interval - durs(i); 
    stim_vals = defineStimTrains(del,freqs_all(i),durs(i),num_trains,train_interval);
    exp_settings(i) = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
end
% Plot settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.condition = condition;
ps.show_diff_image = [4]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'combine'; % 'combine' or 'separate'
ps.save_processed_data = 1;
ps.load_processed_data = 0;
ps.save_fig = 1;
if strcmp(ps.roi_func_mode,'combine')
    ps.y_lim = [-0.04 0.1];
else
    ps.y_lim = [];
end
ps.x_lim = [del-baseline_wind,2]; 
ps.recenterROIs = 0;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0'
ps.transform_type = 'none'; % 'none' or 'displace'
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,...
                               'burst','controlQ.fits'); 
ps.show_roi_labels = 1;  
ps.close_img_after_save = 1;
ps.bin_size = 1; 
ps.rem_pbleach = 0;
ps.fwhm_spline_interp = 0;
% makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),{'control'},exp_settings);
%%
freq_plot = 50;
ps.condition = sprintf('%gHz',freq_plot); % 'control', '50nM_DTX'
img_name = 'trial'; 
trace_fig = figure; 
trace_axis = gca;
ps.x_lim = [-0.2 1];
% ps.x_lim = [del-baseline_wind,del+durs(freqs == freq_plot)+0.5]; 
datai = plotTrial(img_name,exp_settings(freqs_all == freq_plot),roiset_filename,...
                   trace_axis,ps);
%% Plot multiple trials, same condition
freq_plot = 20; 
ps.condition = sprintf('%gHz',freq_plot); % 'control', '50nM_DTX'
ps.show_diff_image = [4]; 
img_names = {}; % use all images in condition folder
ps.x_lim = [-0.2 1];
trials_data = plotTrials(img_names,exp_settings(freqs_all == freq_plot),roiset_filename,ps);
%% Plot multiple trials, multiple conditions        

freqs = [4, 10, 20, 50]; % Hz
[~,freq_inds] = intersect(freqs_all,freqs); 
conditions = arrayfun(@(x) sprintf('%gHz',x),freqs,'UniformOutput',0);
ps.save_fig = 1;
ps.plot_func = 'deltaF_F0';
ps.show_diff_image = [4];      
ps.roi_func_mode = 'combine'; % 'combine' or 'separate'
if strcmp(ps.roi_func_mode,'combine')
    ps.y_lim = [-0.05 0.15];
else
    ps.y_lim = [];
end
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, stim_wind];
else
    ps.x_lim = [-0.015 1.25];
%     ps.x_lim = [-0.015,0.28];
end
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         ps.transform_type,...
                                        ps.registration_rec);  
summary_datafile = sprintf('%s_%s_%s_%s_%s_ppulse',ps.exp_date,...
                                    'Archon',ps.dish,...
                                    ps.roi_func_mode,...
                                    roiset_filename_no_ext);
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
            ['figs_',roiset_filename_no_ext,'_' ps.roi_func_mode '_ppulse']);                                 
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
out = plotTrials_multipleConditions(conditions,ps,exp_settings(freq_inds),...
                                    roiset_filename,...
                                    'summary_datafile',summary_datafile,...
                                    'summary_fig_dir',summary_fig_dir); 
% set(0,'DefaultFigureVisible','on')
%% Re-plot traces overlaid     
ps.plot_func = 'deltaF_F0';
ps.x_lim = [-0.015 1.25]; 
ps.y_lim = [];
cond_inds = [];
plotExperimentTracesOverlaidGrid(out,ps.plot_func,...
                                'fig_dir',summary_fig_dir,...                                
                                'save_fig',1,...
                                'y_lim',ps.y_lim,...
                                'x_lim',ps.x_lim,'cond_inds',cond_inds,...
                                'align_to','max','norm_peak_ind',-1);
%% Analyze width
% [ cond x num_stim] fwhm from individual trials
mean_fwhm1 = 1e3*cell2mat(cellfun(@(x) mean(x',2,'omitnan')',out.fwhm,'UniformOutput',0)'); % average across trains 
std_fwhm1 = 1e3*cell2mat(cellfun(@(x) std(x',0,2,'omitnan')',out.fwhm,'UniformOutput',0)'); %  across trains 
sem_fwhm1 = std_fwhm1/size(out.fwhm{1},2); 
mean_nfwhm1 = mean_fwhm1./mean_fwhm1(:,1); 
std_nfwhm1 = std_fwhm1./mean_fwhm1(:,1); 
sem_nfwhm1 = sem_fwhm1./mean_fwhm1(:,1);
mean_fwhm2 = cell2mat(out.mean_fwhm'); 
mean_nfwhm2 = mean_fwhm2./mean_fwhm2(:,1); 
hs = zeros(1,length(out.conditions));
p_vec = zeros(1,length(out.conditions));
for i = 1:length(out.conditions)
    [hs(i),p_vec(i)] = ttest(out.fwhm{i}(1,:)',out.fwhm{i}(2,:)');
end
hs(hs==0) = nan;
fig = figure('Units','inches');
fig.Position(3:4) = [10 4]; 
% ax = subplot(2,1,1);
b = bar(mean_fwhm1,'FaceColor','b'); hold on;
title('FWHM calculated individually (mean +/- STD)')
for i = 1:length(out.conditions) % error bars
   errorbar(i + [b(:).XOffset],mean_fwhm1(i,:),std_fwhm1(1,:),'-k'); 
end
box off; 
ax = gca;
ax.XTickLabel = {};
ylabel('nFWHM (ms)'); 
% ylim([0.6 1.8])
ax.XTick = 1:size(mean_fwhm1,1);
ax.XTickLabel = out.conditions; 
plot(1:length(out.conditions),hs*ax.YLim(2)*0.98,'r*')
if ps.save_fig
    printFig(fig,summary_fig_dir,'nfwhm');
end
% ax2 = subplot(2,1,2);
% b2 = bar(mean_nfwhm2,'FaceColor','b'); 
% title('FWHM calculated on averaged traces')
% box off; 
% hold on;
% for i = 1:length(out.conditions)
%     for j = 1:size(out.fwhm{i},2)
%         plot(i+[b(:).XOffset],out.fwhm{i}(:,j)/mean(out.fwhm{i}(1,:)),'Color',0.6*[1 1 1]);
%     end
% end
% ylim([0.7 1.3]);  
% ax2.XTick = 1:size(mean_nfwhm1,1);
% ax2.XTickLabel = conditions; 
% ylabel('nFWHM ratio'); 
isi_all = 1e3./freqs; % ms
% isi_all = 1e3./freqs_all; % ms
fig = figure('Units','inches');
fig.Position(3:4) = [10 4];
plot(isi_all,mean_nfwhm2(:,2),'-ko'); 
box off; 
xlabel('Inter-spike interval (ms)'); 
ylabel('nFWHM ratio'); 
% ylim([0.9 1.1])
ax = gca;
ax.XTick = sort(unique([ax.XTick,isi_all(2:end)]));
if ps.save_fig
    printFig(fig,summary_fig_dir,'nfwhm_ratio');
end
%% Plot summary data
plot_inds = [1,3,4,7];
plotExpDefaultSummaryStats(out,out.plot_settings,'plot_inds',plot_inds,...
                           'roi_set_filename',roiset_filename,'save_fig',1,...
                           'summary_fig_dir',summary_fig_dir)
%% Generate diff image stack
stack_mode = 'diff'; % or 'bsline'
img_stack_name = sprintf('%s_%s_%s_%s_img_stack',exp_date,reporter,dish,...
                         stack_mode); 
makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),...
                      conditions,exp_settings,'img_stack_name',img_stack_name,...
                      'img_mode',stack_mode)  
%% Analyze width
% [ cond x num_stim] fwhm from individual trials
mean_fwhm1 = 1e3*cell2mat(cellfun(@(x) mean(x,2,'omitnan')',out.fwhm,'UniformOutput',0)'); % average across trains 
std_fwhm1 = 1e3*cell2mat(cellfun(@(x) std(x,0,2,'omitnan')',out.fwhm,'UniformOutput',0)'); %  across trains 
sem_fwhm1 = std_fwhm1/size(out.fwhm{1},2); 
mean_nfwhm1 = mean_fwhm1./mean_fwhm1(:,1); 
std_nfwhm1 = std_fwhm1./mean_fwhm1(:,1); 
sem_nfwhm1 = sem_fwhm1./mean_fwhm1(:,1);
mean_fwhm2 = cell2mat(out.mean_fwhm'); 
mean_nfwhm2 = mean_fwhm2./mean_fwhm2(:,1); 
hs = zeros(1,length(out.conditions));
p_vec = zeros(1,length(out.conditions));
for i = 1:length(out.conditions)
    [hs(i),p_vec(i)] = ttest(out.fwhm{i}(1,:)',out.fwhm{i}(2,:)');
end
hs(hs==0) = nan;
fig = figure('Units','inches');
fig.Position(3:4) = [10 4]; 
% ax = subplot(2,1,1);
b = bar(mean_fwhm1,'FaceColor','b'); hold on;
title('FWHM calculated individually (mean +/- STD)')
for i = 1:length(out.conditions) % error bars
   errorbar(i + [b(:).XOffset],mean_fwhm1(i,:),std_fwhm1(1,:),'-k'); 
end
box off; 
ax = gca;
ax.XTickLabel = {};
ylabel('nFWHM (ms)'); 
% ylim([0.6 1.8])
ax.XTick = 1:size(mean_fwhm1,1);
ax.XTickLabel = out.conditions; 
plot(1:length(out.conditions),hs*ax.YLim(2)*0.98,'r*')
if ps.save_fig
    printFig(fig,summary_fig_dir,'nfwhm');
end
% ax2 = subplot(2,1,2);
% b2 = bar(mean_nfwhm2,'FaceColor','b'); 
% title('FWHM calculated on averaged traces')
% box off; 
% hold on;
% for i = 1:length(out.conditions)
%     for j = 1:size(out.fwhm{i},2)
%         plot(i+[b(:).XOffset],out.fwhm{i}(:,j)/mean(out.fwhm{i}(1,:)),'Color',0.6*[1 1 1]);
%     end
% end
% ylim([0.7 1.3]);  
% ax2.XTick = 1:size(mean_nfwhm1,1);
% ax2.XTickLabel = conditions; 
% ylabel('nFWHM ratio'); 

isi_all = 1e3./freqs_all; % ms
fig = figure('Units','inches');
fig.Position(3:4) = [10 4];
plot(isi_all,mean_nfwhm2(:,2),'-ko'); 
box off; 
xlabel('Inter-spike interval (ms)'); 
ylabel('nFWHM ratio'); 
% ylim([0.9 1.1])
ax = gca;
ax.XTick = sort(unique([ax.XTick,isi_all(2:end)]));
if ps.save_fig
    printFig(fig,summary_fig_dir,'nfwhm_ratio');
end
%% Analyze experiment
data_filename = '20220322_Archon_dish4_combine_RoiSet_pos7';
save_fig = 1;
fit_spline = 0;
fs = 100e3; % Hz - spline sampling rate
%% Analyze Archon AP widths
out = load([data_filename,'.mat']); % Load data
fig = figure; 
fig.Units = 'inches';
fig.Position = [3.6 6 12 3.5];
for i = 1:length(out.conditions)
    deltaF_F0_aligned = out.deltaF_F0_aligned_all{i};
    mean_APs_trials = mean(deltaF_F0_aligned,4);    
    t = out.exp_settings(i).getTimeVector(size(mean_APs_trials,1));  
    stim_index = out.exp_settings(1).baseline_wind + 1;     
    fwhm = zeros(size(mean_APs_trials,[2 3]));
    n_traces = prod(size(mean_APs_trials,[2 3])); 
    if fit_spline
       ts = 0:(1/fs):t(end); 
       mean_APs_trials2 = zeros(length(ts),n_traces); 
       for n = 1:n_traces
           mean_APs_trials2(:,n) = spline(t,mean_APs_trials(:,n),ts);
       end
       stim_time = out.exp_settings(i).convert2Time(stim_index);
       [~,min_ind] = min(abs(ts - stim_time)); 
       stim_index = ts(min_ind); 
       t = ts;
       mean_APs_trials = mean_APs_trials2; 
    end
    
    for n = 1:n_traces
        try
            fwhm(n) = spikeWidth(t,mean_APs_trials(:,n),stim_index,0.5)*1e3;
        catch
            fwhm(n) = nan;
        end
    end
    mean_nfwhm = fwhm./fwhm(:,1); 
    mean_nfwhm_ind = mean(out.fwhm{i},3);
    std_nfwhm_ind = std(out.fwhm{i},0,3)/mean_nfwhm_ind(:,1);
    mean_nfwhm_ind = mean_nfwhm_ind/mean_nfwhm_ind(:,1); 
    peaks = squeeze(max(mean_APs_trials,[],1));
    norm_peaks = peaks/peaks(1); 
    subplot(2,length(out.conditions),i); 
    b = bar(mean_nfwhm,'FaceColor',0.6*[1 1 1]); hold on;
    e = errorbar(mean_nfwhm_ind,std_nfwhm_ind,'-k'); 
    box off; 
    ylim([0.5 1.5]); 
    ax = gca;
    ax.XTick = 1:length(out.exp_settings(i).stim_vals);
    ylabel('nFWHM'); 
    p = anova1(squeeze(out.fwhm{i})',[],'off'); 
    title(sprintf('%s - p = %.2f',out.conditions{i},p));    
    subplot(2,length(out.conditions),i+length(out.conditions)); 
    plot(norm_peaks,'-ko'); ylim([0.80 1.2]); 
%     b = bar(norm_peaks,'FaceColor',0.6*[1 1 1]); hold on;
    box off; 
    ylabel('Peak (norm.)'); 
    ax = gca;
    ax.XTick = 1:length(out.exp_settings(i).stim_vals);
end
if save_fig
    fig_name = [data_filename '_nFWHM_vs_freq_spline_' num2str(fit_spline)];
   printFig(fig,'.',fig_name); 
end

