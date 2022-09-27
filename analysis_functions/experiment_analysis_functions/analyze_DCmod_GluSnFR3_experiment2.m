function analyze_DCmod_GluSnFR3_experiment2(exp_date,reporter,dish,roiset_filename,...
                    cond_inds,cond_names,sort_amp_ind,save_figs,varargin)
%% Analyze responses to train during DC stimulation at different amplitudes
% Assumes experimental paradigm in DC stim is applied during second train
% of APs within trial (off then on)
if nargin == 0
    exp_date = '20220926';
    reporter = 'GluSnFR3_SynmRuby';
    dish = 'dish3';
    roiset_filename = 'RoiSet_auto_control_3';    
%     cond_inds = []; 
    cond_inds = [1:4,8,7,6,5];
    amps = [-2, -1, -0.5, -0.1, 0.1, 0.5, 1, 2];
    cond_names = arrayfun(@(x) sprintf('%g mA',x),amps,'UniformOutput',0);
    % conditions = {'control_30mAB_0mAY','control_30mAB_1mAY','control_30mAB_2mAY',...
    %                 'control_30mAB_3mAY'}; 
    % cond_names = {'0mA','1mA','2mA','3mA'};
    % conditions = {'control_30mAB_0mAY','control_30mAB_-1mAY','control_30mAB_2mAY',...
    %                 'control_30mAB_-3mAY'}; 
    % cond_names = {'0mA','-1mA','-2mA','-3mA'};
    sort_amp_ind = 5; % amplitude to sort ROIs by
    save_figs = 1;
end
in.plot_figs = [1]; % Select analysis figures to plot
                      % 1 - mean across ROIs
                      % 2 - mean within ROIs
                      % 3 - plot responses within specific ROI in single figure                      
in.plot_roi_ind = 6; % for 3 - index of ROI to plot
in.stim_cols = {'k','r'}; % 'Off','On'
in.norm_to_cont = 1; % normalize responses to control (DC off) within trial/ROI
in.dc_stim_del = 10.5; % sec
in.dc_stim_dur = 10; % sec
in.data_file_suffix = 'train';
in.roi_func_mode = 'separate';
in.cols = lines(length(cond_names));
% plot settings
in.fig_size = [0.97 0.88]; % in 'normalized' units
in = sl.in.processVarargin(in,varargin);

data_fold = getDataFold();
cont_ind = strcmp(cond_names,'0mA');
cols = in.cols; 
%% Load data
exp_fold = fullfile(data_fold,exp_date,reporter,dish);
data_file = sprintf('%s_%s_%s_%s_%s',exp_date,reporter,dish,in.roi_func_mode,...
                                    roiset_filename);
if ~isempty(in.data_file_suffix)
    data_file = [data_file '_' in.data_file_suffix];
end
out = load(fullfile(exp_fold,[data_file '.mat']));
%%
% analysis_fig_fold = fullfile(exp_fold,'analysis');
analysis_fig_fold = fullfile(exp_fold,['figs_' roiset_filename]);
if ~isempty(cond_inds)
    conditions = out.conditions(cond_inds);
else
    conditions = out.conditions; 
    cond_inds = 1:length(conditions);
end
exp_settings = out.exp_settings(1); 
num_trains = exp_settings.num_trains; 
num_stim = exp_settings.num_stim;
baseline_wind_sec = exp_settings.convert2Time(exp_settings.baseline_wind);
deltaF_F0_all = out.deltaF_F0_all(cond_inds);
% deltaF_F0_aligned_all = out.deltaF_F0_aligned_all(cond_inds);
% get responses aligned within train
deltaF_F0_aligned2 = out.deltaF_F0_aligned2_all(cond_inds); 
num_rois = out.rois_all{1}{1}.num_rois;
% Mean traces within ROI, averaged within train across trials
mean_dF_F0_rois = cellfun(@(x) squeeze(mean(x,[4 5])),deltaF_F0_aligned2,...
            'UniformOutput',0); % average across stim within trains and trials
std_dF_F0_rois = cellfun(@(x) squeeze(std(x,0,[4 5])),deltaF_F0_aligned2,...
            'UniformOutput',0); % std across stim within trains and trials
sem_dF_F0_rois = cellfun(@(x) x/sqrt(num_stim),std_dF_F0_rois,'UniformOutput',0);
mean_dF_F0_rois_norm0 = cellfun(@(x) x./max(x(:,:,1),[],1),...
                                mean_dF_F0_rois,'UniformOutput',0);
std_dF_F0_rois_norm0 = cellfun(@(x,y) x./max(y(:,:,1),[],1),...
                                std_dF_F0_rois,mean_dF_F0_rois,'UniformOutput',0);
sem_dF_F0_rois_norm0 = cellfun(@(x) x/sqrt(num_stim),std_dF_F0_rois_norm0,'UniformOutput',0);
% mean_dF_F0_rois = cellfun(@(x) squeeze(mean(x(:,:,:,:,1),[4 5])),deltaF_F0_aligned2,'UniformOutput',0); % average across stim within trains
% Average raw dF/F0 traces across ROIs
mean_dF_F0 = cellfun(@(x) squeeze(mean(x,2)),mean_dF_F0_rois,...
                'UniformOutput',0); % average across ROIs
std_dF_F0 = cellfun(@(x) squeeze(std(x,0,2)),mean_dF_F0_rois,...
                'UniformOutput',0); % std across ROIs
sem_dF_F0 = cellfun(@(x) x/sqrt(num_rois),std_dF_F0,'UniformOutput',0);
% Average traces normalized within trial across ROIs
mean_dF_F0_norm0 = cellfun(@(x) squeeze(mean(x,2)),mean_dF_F0_rois_norm0,...
                'UniformOutput',0); % average across ROIs
std_dF_F0_norm0 = cellfun(@(x) squeeze(std(x,0,2)),mean_dF_F0_rois_norm0,...
                'UniformOutput',0); % std across ROIs
sem_dF_F0_norm0 = cellfun(@(x) x/sqrt(num_rois),std_dF_F0_norm0,'UniformOutput',0);
% sem_deltaF_F0_aligned = std_deltaF_F0_aligned;
t = exp_settings.getTimeVector(size(deltaF_F0_all{1},1));
ta = exp_settings.getTimeVector(size(mean_dF_F0{1},1));
ta = ta - ta(exp_settings.baseline_wind+1);
% Peaks
peaks = out.peaks_deltaF_F0_all(cond_inds);
if in.norm_to_cont
    trace_ylabel_str = 'Mean \Delta F/F_{0} (norm.)';
else
    trace_ylabel_str = 'Mean \Delta F/F_{0}';
end
%% Plot mean stim averaged response across ROIs and trials
if any(in.plot_figs == 1)
    fig = figure('Units','normalized');
    fig.Position = [0.047 0.05 in.fig_size]; 
    for roi_i = 1:length(conditions)
        ax = subplot(2,4,roi_i);        
        if in.norm_to_cont
            tracesi = mean_dF_F0_norm0{roi_i};
    %         stdi = std_dF_F0_norm0{i}; 
            semi = sem_dF_F0_norm0{roi_i}; 
        else
            tracesi = mean_dF_F0{roi_i};
    %         stdi = std_dF_F0{i};        
            semi = sem_dF_F0{roi_i}; 
        end
        for condj = 1:size(mean_dF_F0{roi_i},2)
    %        shadedErrorBar(ta,mean_dF_F0{i}(:,j),std_dF_F0{i}(:,j),'lineProps',stim_cols(j));
           shadedErrorBar(ta,tracesi(:,condj),semi(:,condj),'lineProps',in.stim_cols(condj));
        end
    %     plot(ta,mean_dF_F0{i}); 
        box off; grid on;       
        if roi_i > 4
            xlabel('time (sec)');
        end
        if roi_i == 1 || roi_i == 5
            ylabel(trace_ylabel_str)
        end
        title(strrep(conditions{roi_i},'_',' '));
        xlim([-baseline_wind_sec,ta(end)]);
        ax.YLim(1) = -0.05; 
        if roi_i == length(conditions)
            legend('DC off','DC on','Box','off');
        end
    end
    sgtitle('Mean response across ROIs with and without DC stimulus (+/- SEM)')
    if save_figs
        fig_name = sprintf('meanF_all_DCamp_norm%g',in.norm_to_cont);
        printFig(fig,analysis_fig_fold,fig_name);
    end
end
%% Plot mean stim averaged response across trials within each ROI
if any(in.plot_figs == 2)
    Nax = num_rois; 
    [Nrows,Ncols] = getSubplotDimensions(Nax); 
    for condj = 1:length(cond_inds) % loop over conditions (stim amps)
        fig = figure('Units','normalized');
        fig.Position = [0.001 0.03 in.fig_size];        
        for roi_i = 1:Nax % loop over ROIs for each subplot
            ax = subplot(Nrows,Ncols,roi_i);        
            % get traces
            if in.norm_to_cont
                tracesij = squeeze(mean_dF_F0_rois_norm0{condj}(:,roi_i,:));
    %             stdij = squeeze(std_dF_F0_rois_norm0{condj}(:,roi_i,:));
                stdij = squeeze(sem_dF_F0_rois_norm0{condj}(:,roi_i,:));
            else
                tracesij = squeeze(mean_dF_F0_rois{condj}(:,roi_i,:));
    %             stdij = squeeze(std_dF_F0_rois{condj}(:,roi_i,:));
                stdij = squeeze(sem_dF_F0_rois{condj}(:,roi_i,:));
            end
    %         p = plot(ta,tracesi); box off; grid on;
            for k = 1:size(tracesij,2)
                shadedErrorBar(ta,tracesij(:,k),stdij(:,k),'lineProps',in.stim_cols(k));
            end
    %         set(p,{'color'},stim_cols);
            title(sprintf('%g',roi_i));
            if floor(roi_i/Nrows) == Nrows
                xlabel('time (sec)');
            end
            if mod(roi_i,Ncols) == 1 && mod(roi_i,Nrows) == round(Nrows/2)
                ylabel(trace_ylabel_str)
            end
             xlim([-baseline_wind_sec,ta(end)]);
%              ax.YLim(1) = -0.5;            
        end
        sgtitle(strrep(out.conditions{condj},'_',' '));
        drawnow; 
        if save_figs
            fig_name = sprintf('meanF_ROIs_%gmA_DCamp_norm%g',amps(condj),in.norm_to_cont);
            printFig(fig,analysis_fig_fold,fig_name);
        end
    end
end
%% Plot traces of specific ROI in all conditions
if any(in.plot_figs == 3)    
    if in.norm_to_cont
        yax_lims = [];
    else
        yax_lims = [-0.1 1];                 
    end
    stim_cols2 = {[0 0 0 0.2];[1 0 0 0.1]};    
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 0.97 0.88];    
    for i = 1:length(cond_inds)         
        % plot mean trace
        mean_tracesi = squeeze(mean_dF_F0_rois{i}(:,in.plot_roi_ind,:)); % [ off, on]
        % all responses 
        tracesi = cell(1,2); 
        for j = 1:2
            trij = squeeze(deltaF_F0_aligned2{i}(:,in.plot_roi_ind,j,:,:));
            tracesi{j} = reshape(trij,size(trij,1),prod(size(trij,[2 3])));        
        end
        if in.norm_to_cont
            norm_factor = max(mean_tracesi(:,1),[],1);
            mean_tracesi = mean_tracesi/norm_factor;
            tracesi = cellfun(@(x) x/norm_factor,tracesi,'UniformOutput',0); 
        end
        ax = subplot(2,4,i);
        for j = 1:2
            p = plot(ta,tracesi{j},'LineWidth',0.25,'Color',stim_cols2{j});
            hold on;
        end
        p2 = plot(ta,mean_tracesi,'LineWidth',2);
        set(p2,{'color'},in.stim_cols');
        box off; grid on;
        title(strrep(conditions{i},'_',' '));
        if i > 4
            xlabel('time (sec)');
        end
        if i == 1 || i == 5
            ylabel(trace_ylabel_str)
        end
        if i == length(cond_inds)
            legend(p2,'DC off','DC on','Box','off');
        end
        if ~isempty(yax_lims)
            ax.YLim = yax_lims;
        end
    end
    sgtitle(sprintf('Mean and individual responses (%g APs) in ROI %g',...
            length(exp_settings(1).stim_vals(:)),in.plot_roi_ind))
    if save_figs
        fig_name = sprintf('meanF_all_DCamp_norm%g_roi%g',in.norm_to_cont,...
                in.plot_roi_ind);
        printFig(fig,analysis_fig_fold,fig_name);
    end
end
%% Analyze ROI specific modulation
if any(in.plot_figs == 4)
    
end

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
for roi_i = 1:length(e)
    e(roi_i).Color = cols(length(e)+1-roi_i,:);
end
xlabel('ROI index');
ylabel('Mean peak \Delta F/F_{0} ')
box off; grid on;
legend(cond_names,'Box','off')
title('Mean +/- SEM (60 stimuli per ROI, sorted by % change)')
ax = gca;
ax.XTick = 1:num_rois;
ax.XTickLabel = roi_inds1; 
if save_figs
    printFig(fig,analysis_fig_fold,'mean_peaks_rois');
end
% Plot norm peaks
fig = figure('Position',[680 680 1140 370]);
e = errorbar(mean_peaks_rois_norm,sem_peaks_rois_norm,'o');
for roi_i = 1:length(e)
    e(roi_i).Color = cols(length(e)+1-roi_i,:);
end
xlabel('ROI index');
ylabel('Mean peak \Delta F/F_{0} (norm.)')
box off; grid on;
legend(cond_names,'Box','off')
title('Mean +/- SEM (60 stimuli per ROI, sorted by % change)')
ax = gca;
ax.XTick = 1:num_rois;
ax.XTickLabel = roi_inds1; 
if save_figs
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
for roi_i = 1:length(e)
    e(roi_i).Color = cols_not_cont(length(e)+1-roi_i,:);
end
if save_figs
    printFig(fig,analysis_fig_fold,'mean_peaks_per_change');
end
%% Plot box plot of mean peaks normalized within ROIs to 0 mA 
mean_peaks_rois_norm_cell = mat2cell(mean_peaks_rois_norm,size(mean_peaks_rois_norm,1),ones(1,size(mean_peaks_rois_norm,2)));
plotSummaryStats(mean_peaks_rois_norm_cell,[],cond_names,'Mean peak \Delta F/F_{0}','norm.',...
                 'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                 'save_fig',save_figs,'fig_dir',analysis_fig_fold);

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
if save_figs
    printFig(fig,analysis_fig_fold,['per_change_rois_bar' num2str(bar_mode)]);
end
end