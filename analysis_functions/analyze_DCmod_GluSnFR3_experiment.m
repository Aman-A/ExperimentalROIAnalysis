function analyze_DCmod_GluSnFR3_experiment(exp_date,reporter,dish,roiset_filename,...
                    conditions,cond_names,sort_amp_ind,save_analysis_figs,varargin)
%% Analyze responses to train during DC stimulation at different amplitudes
% Assumes experimental paradigm in which single DC amplitude is applied
% within trial
if nargin == 0
    exp_date = '20220907';
    reporter = 'GluSnFR3_SynmRuby';
    dish = 'dish1';
    roiset_filename = 'RoiSet_auto_control_pos16_1';    
    conditions = {'control_30mAB_-3mAY','control_30mAB_-2mAY','control_30mAB_-1mAY',...
        'control_30mAB_0mAY','control_30mAB_1mAY','control_30mAB_2mAY',...
        'control_30mAB_3mAY'};
    cond_names = {'-3mA','-2mA','-1mA','0mA','1mA','2mA','3mA'};
    % conditions = {'control_30mAB_0mAY','control_30mAB_1mAY','control_30mAB_2mAY',...
    %                 'control_30mAB_3mAY'}; 
    % cond_names = {'0mA','1mA','2mA','3mA'};
    % conditions = {'control_30mAB_0mAY','control_30mAB_-1mAY','control_30mAB_2mAY',...
    %                 'control_30mAB_-3mAY'}; 
    % cond_names = {'0mA','-1mA','-2mA','-3mA'};
    sort_amp_ind = 5;
    save_analysis_figs = 0;
end
in.roi_func_mode = 'separate';
in.cols = lines(length(cond_names));
in = sl.in.processVarargin(in,varargin);

data_fold = getDataFold();
cont_ind = strcmp(cond_names,'0mA');
cols = in.cols; 
%% Load data
exp_fold = fullfile(data_fold,exp_date,reporter,dish);
data_file = sprintf('%s_%s_%s_%s_%s.mat',exp_date,reporter,dish,in.roi_func_mode,...
                                    roiset_filename);
out = load(fullfile(exp_fold,data_file));
%%
analysis_fig_fold = fullfile(exp_fold,'analysis');
[~,~,cond_inds] = intersect(conditions,out.conditions,'stable');
exp_settings = out.exp_settings(1); 
deltaF_F0_all = out.deltaF_F0_all(cond_inds);
deltaF_F0_aligned_all = out.deltaF_F0_aligned_all(cond_inds);
num_rois = out.rois_all{1}{1}.num_rois;
% get mean response across all ROIs, stimuli, and trials for each condition
mean_deltaF_F0_aligned = cell2mat(cellfun(@(x) mean(x,[2 3 4]),...
                            deltaF_F0_aligned_all,'UniformOutput',0));
mean_deltaF_F0_aligned_wROIs = cellfun(@(x) mean(x,[3 4]),...
                            deltaF_F0_aligned_all,'UniformOutput',0);
std_deltaF_F0_aligned = cell2mat(cellfun(@(x) std(x,0,2),...
                            mean_deltaF_F0_aligned_wROIs ,'UniformOutput',0));
sem_deltaF_F0_aligned = std_deltaF_F0_aligned/sqrt(num_rois);
% sem_deltaF_F0_aligned = std_deltaF_F0_aligned;
t = exp_settings.getTimeVector(size(deltaF_F0_all{1},1));
ta = exp_settings.getTimeVector(size(mean_deltaF_F0_aligned,1));
ta = ta - ta(exp_settings.baseline_wind+1);
fig = figure; 
fig.Position(3:4) = [1134 339];
% plot(ta,mean_deltaF_F0_aligned);
for i = 1:size(mean_deltaF_F0_aligned,2)
    subplot(1,size(mean_deltaF_F0_aligned,2),i);
    shadedErrorBar(ta,mean_deltaF_F0_aligned(:,i),sem_deltaF_F0_aligned(:,i),...
                   'lineProps',{'Color',cols(i,:)});
    title(cond_names{i})
    % legend(cond_names,'Box','off')
    xlabel('time (ms)'); ylabel('\Delta F/F_{0}');
    box off; grid on;
    xlim([ta(1) ta(end)]);
    sgtitle(sprintf('mean +/- SEM (%g ROIs)',num_rois))
    ylim([-0.05 0.6]);
end
if save_analysis_figs
    printFig(fig,analysis_fig_fold,sprintf('mean_deltaF_F0_traces_cond%g-%g',cond_inds(1),cond_inds(end)));
end
%% Analyze ROI specific modulation
peaks = out.peaks_deltaF_F0_all(cond_inds);
% [num_rois x num_conds]
mean_peaks_rois = cell2mat(cellfun(@(x) squeeze(mean(x,[1 3]))',peaks,...
                                'UniformOutput',0));
% std across stimuli
std_peaks_rois = cell2mat(cellfun(@(x) squeeze(std(x,0,[1 3]))',peaks,...
                                'UniformOutput',0));
nstim = cell2mat(cellfun(@(x) prod(size(x,[1 3])),peaks,'UniformOutput',0));
sem_peaks_rois = std_peaks_rois./sqrt(nstim);
% modulation
per_change_rois = 100*(mean_peaks_rois(:,~cont_ind)-mean_peaks_rois(:,cont_ind))./mean_peaks_rois(:,cont_ind);
per_change_std_rois = 100*(std_peaks_rois(:,~cont_ind)-std_peaks_rois(:,cont_ind))./std_peaks_rois(:,cont_ind);
per_change_sem_rois = per_change_std_rois./sqrt(nstim(~cont_ind));
% normalized
mean_peaks_rois_norm = mean_peaks_rois./mean_peaks_rois(:,cont_ind);
sem_peaks_rois_norm = sem_peaks_rois./mean_peaks_rois(:,cont_ind);
% sort 
% [~,sort_inds] = sort(mean_peaks_rois(:,end));
[~,sort_inds] = sort(per_change_rois(:,sort_amp_ind),'descend');
roi_inds = 1:num_rois; 
roi_inds1 = roi_inds(sort_inds);
mean_peaks_rois = mean_peaks_rois(sort_inds,:);
std_peaks_rois = std_peaks_rois(sort_inds,:);
sem_peaks_rois = sem_peaks_rois(sort_inds,:);
per_change_rois = per_change_rois(sort_inds,:);
per_change_std_rois = per_change_std_rois(sort_inds,:);
per_change_sem_rois = per_change_sem_rois(sort_inds,:);
mean_peaks_rois_norm = mean_peaks_rois_norm(sort_inds,:);
sem_peaks_rois_norm = sem_peaks_rois_norm(sort_inds,:);
% Plot peaks
fig = figure('Position',[680 680 1140 370]);
e = errorbar(mean_peaks_rois,sem_peaks_rois,'o');
for i = 1:length(e)
    e(i).Color = cols(length(e)+1-i,:);
end
xlabel('ROI index');
ylabel('Mean peak \Delta F/F_{0} ')
box off; grid on;
legend(cond_names,'Box','off')
title('Mean +/- SEM (60 stimuli per ROI, sorted by % change)')
ax = gca;
ax.XTick = 1:num_rois;
ax.XTickLabel = roi_inds1; 
if save_analysis_figs
    printFig(fig,analysis_fig_fold,'mean_peaks_rois');
end
% Plot norm peaks
fig = figure('Position',[680 680 1140 370]);
e = errorbar(mean_peaks_rois_norm,sem_peaks_rois_norm,'o');
for i = 1:length(e)
    e(i).Color = cols(length(e)+1-i,:);
end
xlabel('ROI index');
ylabel('Mean peak \Delta F/F_{0} (norm.)')
box off; grid on;
legend(cond_names,'Box','off')
title('Mean +/- SEM (60 stimuli per ROI, sorted by % change)')
ax = gca;
ax.XTick = 1:num_rois;
ax.XTickLabel = roi_inds1; 
if save_analysis_figs
    printFig(fig,analysis_fig_fold,'mean_peaks_rois_norm');
end
% Plot modulation
fig = figure('Position',[680 680 1140 370]);
% plot(per_change,'o');
e = errorbar(per_change_rois,per_change_sem_rois,'o');
ylim([-100 250]);
xlabel('ROI index');
ylabel('Mean % change in peak vs. 0 mA');
box off; 
ax = gca;
ax.XTick = 1:num_rois;
ax.XTickLabel = roi_inds1; 
legend(cond_names(~cont_ind),'Box','off')
grid on;
cols_not_cont = cols(~cont_ind,:); %not control colors
for i = 1:length(e)
    e(i).Color = cols_not_cont(length(e)+1-i,:);
end
if save_analysis_figs
    printFig(fig,analysis_fig_fold,'mean_peaks_per_change');
end
%% Plot box plot of mean peaks normalized within ROIs to 0 mA 
mean_peaks_rois_norm_cell = mat2cell(mean_peaks_rois_norm,size(mean_peaks_rois_norm,1),ones(1,size(mean_peaks_rois_norm,2)));
plotSummaryStats(mean_peaks_rois_norm_cell,[],cond_names,'Mean peak \Delta F/F_{0}','norm.',...
                 'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                 'save_fig',save_analysis_figs,'fig_dir',analysis_fig_fold);

%% Bar plot of frac. modulation
% peak_inc_rois = mean_peaks_rois_norm(:,2:end) > 1 + sem_peaks_rois_norm(:,1);
% peak_dec_rois = mean_peaks_rois_norm(:,2:end) < 1 - sem_peaks_rois_norm(:,1);
bar_mode = 2;
peak_inc_rois = mean_peaks_rois_norm(:,~cont_ind) - sem_peaks_rois_norm(:,~cont_ind) > 1 + sem_peaks_rois_norm(:,cont_ind);
peak_dec_rois = mean_peaks_rois_norm(:,~cont_ind) + sem_peaks_rois_norm(:,~cont_ind) < 1 - sem_peaks_rois_norm(:,cont_ind);
per_inc_rois = 100*sum(peak_inc_rois)/num_rois;
per_dec_rois = 100*sum(peak_dec_rois)/num_rois; 
per_nochange_rois = 100 - per_inc_rois - per_dec_rois; 
fig = figure; 
if bar_mode == 1
    b = bar([per_nochange_rois;per_dec_rois;per_inc_rois]','stacked');
else
    b = bar([per_nochange_rois;per_dec_rois;per_inc_rois]');
end
% b(1).FaceColor = cols(2,:);
% b(2).FaceColor = cols(3,:);
ax = gca;
ax.XTick = 1:length(cond_names(~cont_ind));
ax.XTickLabel = cond_names(~cont_ind); 
legend({'No change','Decrease','Increase'},'Box','off','Location','bestoutside');
% ax.XTick = 1:3; 
% ax.XTickLabel = {'No change','Decrease','Increase'};
% legend('1 mA','3 mA');
ylabel('% ROIs');
box off; 
if save_analysis_figs
    printFig(fig,analysis_fig_fold,['per_change_rois_bar' num2str(bar_mode)]);
end
end