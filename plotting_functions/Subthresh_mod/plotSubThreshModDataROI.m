function plotSubThreshModDataROI(roi_ind,peaks_before,peaks_during,peaks_after,...
                                dF_al2_before,dF_al2_during,dF_al2_after,...
                                amps,exp_settings,varargin)
in.mode = 1; % 1 - shaded error bar, 2 - mean and all individual trials
in.stim_cols = {'k','r','b'};
in.stim_cols2 = {[0 0 0 0.2];[1 0 0 0.1]};    
in.plot_after = 0; 
in.trace_plot_axes_on = 0;
in.sbar_xlen = 0.05; % sec
in.sbar_ylen = 0.05; % deltaF/F
in.save_figs = 0;
in.fig_fold = 'figs';
in = sl.in.processVarargin(in,varargin);
% num_stim x num_amps
peaks_beforei = cell2mat(cellfun(@(x) x(roi_ind,:)',peaks_before,'UniformOutput',0));
peaks_duringi = cell2mat(cellfun(@(x) x(roi_ind,:)',peaks_during,'UniformOutput',0));
mean_peaks_beforei = 100*mean(peaks_beforei,1,'omitnan');
mean_peaks_duringi = 100*mean(peaks_duringi,1,'omitnan');
num_stim = sum(~isnan(peaks_beforei),1);

% dF/F traces averaged across stim
dF_al2_beforei = cellfun(@(x) squeeze(x(:,roi_ind,:)),dF_al2_before,'UniformOutput',0);
dF_al2_duringi = cellfun(@(x) squeeze(x(:,roi_ind,:)),dF_al2_during,'UniformOutput',0);
% mean traces
mean_dF_al2_beforei = cell2mat(cellfun(@(x) mean(x,2,'omitnan'),dF_al2_beforei,'UniformOutput',0));
mean_dF_al2_duringi = cell2mat(cellfun(@(x) mean(x,2,'omitnan'),dF_al2_duringi,'UniformOutput',0));
% std
std_dF_al2_beforei = cell2mat(cellfun(@(x) std(x,0,2,'omitnan'),dF_al2_beforei,'UniformOutput',0));
std_dF_al2_duringi = cell2mat(cellfun(@(x) std(x,0,2,'omitnan'),dF_al2_duringi,'UniformOutput',0));

ta = exp_settings.getTimeVector(size(mean_dF_al2_beforei,1));
ta = ta-ta(exp_settings.baseline_wind(1)+1);
if isempty(peaks_after)
    include_after = 0;
else
    include_after = 1; 
end
if include_after
    peaks_afteri = cell2mat(cellfun(@(x) x(roi_ind,:)',peaks_after,'UniformOutput',0));
    mean_peaks_after = mean(peaks_afteri,1,'omitnan');
    dF_al2_afteri = cellfun(@(x) squeeze(x(:,roi_ind,:)),dF_al2_after,'UniformOutput',0);    
    mean_dF_al2_afteri = cell2mat(cellfun(@(x) mean(x,2),dF_al2_afteri,'UniformOutput',0));
    std_dF_al2_afteri = cell2mat(cellfun(@(x) std(x,0,2),dF_al2_afteri,'UniformOutput',0));
end

%% Plot mean traces
num_amps = length(amps);
axes_all = cell(1,num_amps);
fig = figure('Units','normalized'); 
fig.Position = [0.05 0.6 0.9 0.25];
for i = 1:num_amps
    ax = subplot(1,num_amps,i);    
    axes_all{i} = ax; 
    if in.mode == 1           
        shadedErrorBar(ta,mean_dF_al2_beforei(:,i),std_dF_al2_beforei(:,i),'lineProps',in.stim_cols{1}); 
        hold on;
        shadedErrorBar(ta,mean_dF_al2_duringi(:,i),std_dF_al2_duringi(:,i),'lineProps',in.stim_cols{2});
        if include_after && in.plot_after
            shadedErrorBar(ta,mean_dF_al2_afteri(:,i),std_dF_al2_afteri(:,i),'lineProps',in.stim_cols{3});
        end
    else
        plot(ta,dF_al2_beforei{i},'LineWidth',0.25,'Color',in.stim_cols2{1});
        hold on;
        plot(ta,dF_al2_duringi{i},'LineWidth',0.25,'Color',in.stim_cols2{2});
        l1 = plot(ta,mean_dF_al2_beforei(:,i),'LineWidth',2,'Color',in.stim_cols{1});
        l2 = plot(ta,mean_dF_al2_duringi(:,i),'LineWidth',2,'Color',in.stim_cols{2});
    end   
    title(sprintf('%g mA',amps(i)));    
    xlabel('time (sec)');
    ax.XLim = [-0.05 0.2];
    if i == num_amps
        if include_after && in.plot_after
            legend('Before','During','After','Location','NorthEastOutside')
        else
            if in.mode == 1
                legend('Before','During')
            else                
                legend([l1,l2],'Before','During')
            end
        end
    end    
    if in.trace_plot_axes_on
       box off; 
    else
        ax.Visible = 'off';
    end
end
sgtitle(sprintf('ROI %g',roi_ind),'FontSize',16);
setAxesUniformLim(fig,'YLim')
if ~in.trace_plot_axes_on    
    ax = axes_all{1};
    x0 = ax.XLim(1) + 0.05*range(ax.XLim);
    x1 = x0 + in.sbar_xlen;
    y1 = ax.YLim(2) - 0.05*range(ax.YLim);
    y0 = y1 - in.sbar_ylen;
    plot(ax,[x0 x0 x1],[y0 y1 y1],'k','LineWidth',2);
end
if in.save_figs
    printFig(fig,in.fig_fold,sprintf('mean_dF_traces_ROI%g_mode%g',roi_ind,in.mode));
end
end
