function plotHists_DCmod(peaks_before,peaks_during,peaks_after,varargin)
%PLOTHISTS_DCMOD ... 
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.hist_norm = 'cdf';
in.nbins = 100; 
in.plot_means = 1; 
in.norm_to_before = 0; 
in.plot_diffs = 0; 
in.plot_after = 1; 
in.ax_titles = {}; 
in.num_dishes_per_amp = []; 
in.save_fig = 0; 
in.fig_fold = '.';
in = sl.in.processVarargin(in,varargin);

if in.norm_to_before   
    % Normalize to mean of peaks before DC
    peaks_during = cellfun(@(x,y) x./mean(y,2,'omitnan'),peaks_during,peaks_before,'UniformOutput',0);
    peaks_after = cellfun(@(x,y) x./mean(y,2,'omitnan'),peaks_after,peaks_before,'UniformOutput',0);
    peaks_before = cellfun(@(x,y) x./mean(y,2,'omitnan'),peaks_before,peaks_before,'UniformOutput',0);
end
if in.plot_means % take mean of all peaks within ROI
    peaks_before = cellfun(@(x) mean(x,2,'omitnan'),peaks_before,'UniformOutput',0);
    peaks_during = cellfun(@(x) mean(x,2,'omitnan'),peaks_during,'UniformOutput',0);
    peaks_after = cellfun(@(x) mean(x,2,'omitnan'),peaks_after,'UniformOutput',0);
end
fig = gcf;
num_amps = length(peaks_before);
for i = 1:num_amps
    ax = subplot(1,num_amps,i);
    % Remove nans
    peaks_beforei = peaks_before{i}(~isnan(peaks_before{i}));
    peaks_duringi = peaks_during{i}(~isnan(peaks_during{i}));    
    peaks_afteri = peaks_after{i}(~isnan(peaks_after{i}));
    
    if in.plot_diffs
        peaks_duringi_diff = peaks_duringi - peaks_beforei;
        peaks_afteri_diff = peaks_afteri - peaks_beforei;
        if in.plot_after
            min_pkij = min([peaks_duringi_diff,peaks_afteri_diff],[],'all','omitnan');
            max_pkij = max([peaks_duringi_diff,peaks_afteri_diff],[],'all','omitnan');
        else
            min_pkij = min(peaks_duringi_diff,[],'all','omitnan');
            max_pkij = max(peaks_duringi_diff,[],'all','omitnan');
        end
        edges = linspace(min_pkij,max_pkij,in.nbins);
        Nd = histcounts(peaks_duringi_diff,edges,'Normalization',in.hist_norm);
        Na = histcounts(peaks_afteri_diff,edges,'Normalization',in.hist_norm);
    else
        if in.plot_after
            max_pkij = max([peaks_beforei,peaks_duringi,peaks_afteri],[],'all','omitnan');
        else
            max_pkij = max([peaks_beforei,peaks_duringi],[],'all','omitnan');
        end
        edges = linspace(0,max_pkij,in.nbins);
        Nb = histcounts(peaks_beforei,edges,'Normalization',in.hist_norm);
        Nd = histcounts(peaks_duringi,edges,'Normalization',in.hist_norm);
        Na = histcounts(peaks_afteri,edges,'Normalization',in.hist_norm);        
    end
    x = edges(1:end-1) + (edges(2)-edges(1))/2;        
    if ~(in.norm_to_before && in.plot_means) && ~in.plot_diffs
        plot(x,Nb,'k'); hold on;
    end
    plot(x,Nd,'r'); hold on;
    if in.plot_after
        plot(x,Na,'b');
    end
    box(ax,'off'); 
    if ~isempty(in.ax_titles)
        title(in.ax_titles{i});        
    end
    if in.plot_diffs
        xlabel('Change in peak \Delta F/F_{0}')
    else
        if in.norm_to_before            
            xlabel('Peak \Delta F/F_{0} (norm.)');
            ax.XLim = [0 3];
        else
            xlabel('Peak \Delta F/F_{0}');
            ax.XLim = [0 0.4];
        end    
    end
    if strcmp(in.hist_norm,'cdf')
        ax.YLim = [0 1];
        plot(ax.XLim,[0.5 0.5],'--','Color',0.6*[1 1 1]);
        if in.norm_to_before
            plot([1 1],[0 1],'--','Color',0.6*[1 1 1]);
        end
    end    
    if ~isempty(in.num_dishes_per_amp)
        text(ax,ax.XLim(1)+0.2*range(ax.XLim),0.2,sprintf('n = %g boutons\n%g dishes',...
            sum(~all(isnan(peaks_before{i}),2),1),in.num_dishes_per_amp(i)),...
            'FontName','Arial','FontSize',14)
    end
end
if ~strcmp(in.hist_norm,'cdf')
    setAxesUniformLim(fig,'YLim');
end
if in.save_fig
    fig_name = sprintf('peaks_%s_%gROIs_mean%g_norm%g',in.hist_norm,...
                        size(peaks_before{1},1),in.plot_means,in.norm_to_before);
    printFig(fig,in.fig_fold,fig_name);
end
end