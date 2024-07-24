function [mean_train,var_train,varargout] = plotSubthreshModPeakTrains(subthresh_data,...
                                                            plot_mode,varargin)
%PLOTSUBTHRESHMODPEAKTRAINS ... 
%  
%   Inputs 
%   ------ 
%   subthresh_data : struct
%                   output of extractSubthreshModResponses.m
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.cond_name = '';
in.save_fig = 0; 
in.fig_name = 'peak_vs_APnum';
in.fig_name2 = 'peak_vs_APnum_slopes_bar';
in.fig_fold = '.';
in.include_inds = []; 
in.line_cols = []; 
in.plot_cond_inds = []; 
in.cond_labels = {};
in.leg_pos = [0.8890    0.6753    0.0912    0.2192];
in.add_regress = 0; % add regression lines and plot for all conditions
in = sl.in.processVarargin(in,varargin);

if isempty(in.include_inds) % include all    
    if contains(plot_mode,'cell')        
        inds = 1:length(subthresh_data.num_rois); 
    else
        inds = 1:sum(subthresh_data.num_rois); 
    end
    N = length(inds); 
else
    inds = in.include_inds;
    if islogical(inds)
        N = sum(inds); 
    else
        N = length(inds);
    end
end
if isempty(in.line_cols)
    line_cols = lines(N);
else
    line_cols = in.line_cols; 
end

num_stim = size(subthresh_data.mean_peaks_before_mat_tr,2);
if isfield(subthresh_data,'mean_peaks_after_cell_tr_norm')
    include_after = 1;
    num_trains = 3;
else
    include_after = 0;
    num_trains = 2; 
end
if strcmp(plot_mode,'abs')
    % mean across rois (unnormalized)
    mean_peaks_before_mat_tr_rois  = squeeze(mean(subthresh_data.mean_peaks_before_mat_tr(inds,:,:),1,'omitnan'));
    mean_peaks_during_mat_tr_rois  = squeeze(mean(subthresh_data.mean_peaks_during_mat_tr(inds,:,:),1,'omitnan'));    
    % sem across rois
    sem_peaks_before_mat_tr_rois = squeeze(std(subthresh_data.mean_peaks_before_mat_tr(inds,:,:),0,1,'omitnan'))/sqrt(N);
    sem_peaks_during_mat_tr_rois = squeeze(std(subthresh_data.mean_peaks_during_mat_tr(inds,:,:),0,1,'omitnan'))/sqrt(N);   
    % organize in cell arrays
    mean_train = {mean_peaks_before_mat_tr_rois; % unnormalized
        mean_peaks_during_mat_tr_rois};
    var_train = {sem_peaks_before_mat_tr_rois;
        sem_peaks_during_mat_tr_rois};
    if include_after
        mean_peaks_after_mat_tr_rois  = squeeze(mean(subthresh_data.mean_peaks_after_mat_tr(inds,:,:),1,'omitnan'));
        sem_peaks_after_mat_tr_rois = squeeze(std(subthresh_data.mean_peaks_after_mat_tr(inds,:,:),0,1,'omitnan'))/sqrt(N);    
        mean_train = [mean_train;mean_peaks_after_mat_tr_rois];
        var_train = [var_train;sem_peaks_after_mat_tr_rois];
    end
elseif strcmp(plot_mode,'normroi')
    % mean and std/sem across ROIs (normalized)
    mean_peaks_before_mat_tr_norm_rois = squeeze(mean(subthresh_data.mean_peaks_before_mat_tr_norm(inds,:,:),1,'omitnan'));
    mean_peaks_during_mat_tr_norm_rois = squeeze(mean(subthresh_data.mean_peaks_during_mat_tr_norm(inds,:,:),1,'omitnan'));    
    % sem across ROIs (normalized)
    sem_peaks_before_mat_tr_norm_rois = squeeze(std(subthresh_data.mean_peaks_before_mat_tr_norm(inds,:,:),0,1,'omitnan'))/sqrt(N);
    sem_peaks_during_mat_tr_norm_rois = squeeze(std(subthresh_data.mean_peaks_during_mat_tr_norm(inds,:,:),0,1,'omitnan'))/sqrt(N);    
    % organize in cell arrays
    mean_train = {mean_peaks_before_mat_tr_norm_rois; % normalized within ROI
        mean_peaks_during_mat_tr_norm_rois};
    var_train = {sem_peaks_before_mat_tr_norm_rois;
        sem_peaks_during_mat_tr_norm_rois};
    if include_after
        mean_peaks_after_mat_tr_norm_rois = squeeze(mean(subthresh_data.mean_peaks_after_mat_tr_norm(inds,:,:),1,'omitnan'));
        sem_peaks_after_mat_tr_norm_rois = squeeze(std(subthresh_data.mean_peaks_after_mat_tr_norm(inds,:,:),0,1,'omitnan'))/sqrt(N);
        mean_train = [mean_train;mean_peaks_after_mat_tr_norm_rois];
        var_train = [var_train;sem_peaks_after_mat_tr_norm_rois];
    end
elseif strcmp(plot_mode,'cell')
    % train within cell
    mean_peaks_before_mat_tr_cell  = squeeze(mean(subthresh_data.mean_peaks_before_cell_tr(inds,:,:),1,'omitnan'));
    mean_peaks_during_mat_tr_cell  = squeeze(mean(subthresh_data.mean_peaks_during_cell_tr(inds,:,:),1,'omitnan'));    
    % sem across cell
    sem_peaks_before_mat_tr_cell = squeeze(std(subthresh_data.mean_peaks_before_cell_tr(inds,:,:),0,1,'omitnan'))/sqrt(N);
    sem_peaks_during_mat_tr_cell = squeeze(std(subthresh_data.mean_peaks_during_cell_tr(inds,:,:),0,1,'omitnan'))/sqrt(N);    
    mean_train = {mean_peaks_before_mat_tr_cell;
        mean_peaks_during_mat_tr_cell};
    var_train = {sem_peaks_before_mat_tr_cell;
        sem_peaks_during_mat_tr_cell};
    if include_after
        mean_peaks_after_mat_tr_cell  = squeeze(mean(subthresh_data.mean_peaks_after_cell_tr(inds,:,:),1,'omitnan'));
        sem_peaks_after_mat_tr_cell = squeeze(std(subthresh_data.mean_peaks_after_cell_tr(inds,:,:),0,1,'omitnan'))/sqrt(N);
        mean_train = [mean_train;mean_peaks_after_mat_tr_cell];
        var_train = [var_train;sem_peaks_after_mat_tr_cell];    
    end
elseif strcmp(plot_mode,'cell_normroi')
    % train within cell after normalizing within ROI to mean before
    mean_peaks_before_mat_tr_cell_norm  = squeeze(mean(subthresh_data.mean_peaks_before_cell_tr_norm(inds,:,:),1,'omitnan'));
    mean_peaks_during_mat_tr_cell_norm  = squeeze(mean(subthresh_data.mean_peaks_during_cell_tr_norm(inds,:,:),1,'omitnan'));    
    % sem across cell
    sem_peaks_before_mat_tr_cell_norm = squeeze(std(subthresh_data.mean_peaks_before_cell_tr_norm(inds,:,:),0,1,'omitnan'))/sqrt(N);
    sem_peaks_during_mat_tr_cell_norm = squeeze(std(subthresh_data.mean_peaks_during_cell_tr_norm(inds,:,:),0,1,'omitnan'))/sqrt(N);    
    % organize into cell arrays
    mean_train = {mean_peaks_before_mat_tr_cell_norm; % normalized within ROI
        mean_peaks_during_mat_tr_cell_norm};
    var_train = {sem_peaks_before_mat_tr_cell_norm;
        sem_peaks_during_mat_tr_cell_norm};
    if include_after
        mean_peaks_after_mat_tr_cell_norm  = squeeze(mean(subthresh_data.mean_peaks_after_cell_tr_norm(inds,:,:),1,'omitnan'));
        sem_peaks_after_mat_tr_cell_norm = squeeze(std(subthresh_data.mean_peaks_after_cell_tr_norm(inds,:,:),0,1,'omitnan'))/sqrt(N);
        mean_train = [mean_train;mean_peaks_after_mat_tr_cell_norm];
        var_train = [var_train;sem_peaks_after_mat_tr_cell_norm];
    end
elseif strcmp(plot_mode,'cell_sep') % plot cell traces separately
    mean_train = {subthresh_data.mean_peaks_before_cell_tr(inds,:,:);
        subthresh_data.mean_peaks_during_cell_tr(inds,:,:)};
    var_train = {};
    if include_after
        mean_train = [mean_train;subthresh_data.mean_peaks_after_cell_tr(inds,:,:)];
    end
elseif strcmp(plot_mode,'cell_normroi_sep') % plot cell traces separately
    mean_train = {subthresh_data.mean_peaks_before_cell_tr_norm(inds,:,:);
        subthresh_data.mean_peaks_during_cell_tr_norm(inds,:,:)};
    var_train = {};
    if include_after
        mean_train = [mean_train;subthresh_data.mean_peaks_after_cell_tr_norm(inds,:,:)];
    end
end
%% Plot
fig = gcf;
num_conds_all = size(subthresh_data.peaks_before_mat,3);
if isempty(in.plot_cond_inds)
    plot_cond_inds = 1:num_conds_all;
else
    plot_cond_inds = in.plot_cond_inds;
end
num_conds = length(plot_cond_inds);
for j = 1:num_conds
    jj = plot_cond_inds(j); 
    ax = subplot(1,num_conds,j);
    % e1 = errorbar(1:num_stim,mean_train{1}(:,i),...
    %                     var_train{1}(:,i),'-k');
    % hold on;
    % e2 = errorbar((num_stim+1):2*num_stim,mean_train{2}(:,i),...
    %                     var_train{2}(:,i),'-r');
    % e3 = errorbar((2*num_stim+1):3*num_stim,mean_train{3}(:,i),...
    %                     var_train{3}(:,i),'-b');
    if contains(plot_mode,'sep')
        e1 = plot(ax,1:num_stim,squeeze(mean_train{1}(:,:,jj)));
        hold on;
        e2 = plot(ax,(num_stim+1):2*num_stim,squeeze(mean_train{2}(:,:,jj)));
        if include_after
            e3 = plot(ax,(2*num_stim+1):3*num_stim,squeeze(mean_train{3}(:,:,jj)));
        end
        for n = 1:N
            e1(n).Color = line_cols(n,:);
            e2(n).Color = line_cols(n,:);
            if include_after
                e3(n).Color = line_cols(n,:);
            end
        end
    else
        e1 = shadedErrorBar(1:num_stim,mean_train{1}(:,jj),...
            var_train{1}(:,jj),'lineProps','k');
        hold on;
        e2 = shadedErrorBar((num_stim+1):2*num_stim,mean_train{2}(:,jj),...
            var_train{2}(:,jj),'lineProps','r');
        if include_after
            e3 = shadedErrorBar((2*num_stim+1):3*num_stim,mean_train{3}(:,jj),...
                var_train{3}(:,jj),'lineProps','b');
        end
    end
    box(ax,'off');
    if j == 1
        if contains(plot_mode,'normroi')
            ylabel(ax,'Peak (norm. to mean before)')
        else
            ylabel(ax,'Mean peak \Delta F/F_{0}')
        end
    end
    title(ax,in.cond_labels{jj});
    xlabel(ax,'AP number');
    
    if ~contains(plot_mode,'sep')
        plot(ax,[0 num_trains*num_stim],mean(mean_train{1}(:,jj),'all')*[1 1],'--','Color',0.4*[1 1 1]);
        if j == length(plot_cond_inds)
            if include_after
                legend([e1.patch,e2.patch,e3.patch],'Before','During','After',...
                    'Position',in.leg_pos,'AutoUpdate','off');
            else
                legend([e1.patch,e2.patch],'Before','During',...
                    'Position',in.leg_pos,'AutoUpdate','off');
            end
        end        
    else
        plot(ax,[0 num_trains*num_stim],mean(mean_train{1}(:,:,jj),'all')*[1 1],'--','Color',0.4*[1 1 1]);
    end
end
setAxesUniformLim(fig,'YLim');       
if ~isempty(in.cond_name)
    sgtitle(strrep(in.cond_name,'_',' '),'FontName',ax.FontName,'FontSize',ax.FontSize);
end
%% Add regression analysis
if in.add_regress
    % fit to regression
    regress_slopes = zeros(2,num_conds);
    regress_ints = zeros(2,num_conds);
    regress_Rsqs = zeros(2,num_conds);
    regress_pvals = zeros(2,num_conds);
    for i = 1:2
        xfit = ((1 + num_stim*(i-1)):i*num_stim)';
        for j = 1:num_conds
            yij = mean_train{i}(:,j);
            [b,~,~,~,stats] = regress(yij,[ones(size(xfit)) xfit]); % 
            regress_ints(i,j) = b(1);
            regress_slopes(i,j) = b(2);
            regress_Rsqs(i,j) = stats(1); 
            regress_pvals(i,j) = stats(3); 
            ax = subplot(1,num_conds,j);
            hold(ax,'on');        
            plot(xfit,xfit*b(2) + b(1),'-k','LineWidth',2)        
        end
    end
    varargout = {regress_slopes,regress_ints,regress_Rsqs,regress_pvals};
    fig2 = figure; 
    b = bar(regress_slopes','hist');
    b(1).FaceColor = 0.4*[1 1 1];
    b(2).FaceColor = 'r'; 
    b(1).FaceAlpha = 0.4;
    b(2).FaceAlpha = 0.4;
    ax = gca;
    ax.XTick = 1:num_conds;
    ax.XTickLabel = in.cond_labels;
    box off; hold on;
    ax.XLim = [0.5 num_conds-0.5];
    plot(ax.XLim,[0 0],'k-')
    ylabel('Slope')
    xlabel('Pulse duration');    
else
    varargout = {};
end
if in.save_fig
    printFig(fig,in.fig_fold,in.fig_name)

    printFig(fig2,in.fig_fold,in.fig_name2);
end
end