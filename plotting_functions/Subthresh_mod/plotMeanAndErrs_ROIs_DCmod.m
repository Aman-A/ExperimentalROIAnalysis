function plotMeanAndErrs_ROIs_DCmod(peaks_before,peaks_during,peaks_after,...
                                varargin)
%PLOTMEANCIS_ROIS_DCMOD ... NOTE: UNFINISHED
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
% TODO: DEAL WITH INCLUSION OF AFTER (MAYBE PUT ON SEPARATE FIGURE?) AND
% SHOWING SIG MOD AFTER
in.err_bar = 'ci'; % 'ci' 95% conf intervals, 'sem', or 'std'
in.sig_mod_during = [];
in.sig_mod_after = []; 
in.sig_marker = '*';
in.sig_color = 'g'; 
in.sig_marker_size = 8; 
in.M = 1e3; % number of boostrap samples, set to 0 to use empirical CIs
in.plot_diffs = 0; 
in.per_diff = 0; % 0 - abs difference, 1 - percent difference
in.plot_after = 1; 
in.mean_marker_size = 3;
in.save_fig = 0; 
in.fig_fold = '.';
in.dish_inds = []; 
in.ax_titles = {}; 
in.cell_lines_on = 0; 
in.num_rois_per_dish = []; 
in = sl.in.processVarargin(in,varargin);

num_amps = length(peaks_before);
num_rois = size(peaks_before{1},1);
roi_inds = (1:num_rois)';
ci_before = nan(num_rois,num_amps,2);
ci_during = nan(num_rois,num_amps,2);
ci_after = nan(num_rois,num_amps,2);
if in.plot_after
    x_vals = [-0.25 0 0.25];
else
    x_vals = [-0.2 0.2];
end
if isempty(peaks_after) || all(isnan(peaks_after{1}),'all')
    include_after = 0; 
else
    include_after = 1; 
end
if in.cell_lines_on && ~isempty(in.num_rois_per_dish)
    dish_roi_borders = [0,cumsum(in.num_rois_per_dish)+0.5];
end
fig = gcf;
for i=1:num_amps
    % 
    peaks_beforei = peaks_before{i};
    peaks_duringi = peaks_during{i};
    if include_after
        peaks_afteri = peaks_after{i};
    end
    % Means
    mean_peaks_beforei = mean(peaks_beforei,2,'omitnan');
    mean_peaks_duringi = mean(peaks_duringi,2,'omitnan');
    if include_after
        mean_peaks_afteri = mean(peaks_afteri,2,'omitnan');
    end
    if in.plot_diffs % 
        mean_peaks_duringi = mean_peaks_duringi-mean_peaks_beforei;
        if include_after
            mean_peaks_afteri = mean_peaks_afteri-mean_peaks_beforei;        
        end
        if in.per_diff
            mean_peaks_duringi = 100*mean_peaks_duringi./mean_peaks_beforei;
            if include_after
                mean_peaks_afteri = 100*mean_peaks_afteri./mean_peaks_beforei;
            end
            ylabel_str = 'Mean change in peak \Delta F/F_{0} (%)';
        else
            ylabel_str = 'Mean change in peak \Delta F/F_{0}';
        end
    else
        ylabel_str = 'Mean peak \Delta F/F_{0}';
    end
    if in.M > 0  % bootstrapped CIs    
        for j = 1:num_rois
            if ~all(isnan(peaks_before{i}(j,:)))
                peaks_beforeij = peaks_beforei(j,~isnan(peaks_beforei(j,:)));
                peaks_duringij = peaks_duringi(j,~isnan(peaks_duringi(j,:)));
                if include_after
                    peaks_afterij = peaks_afteri(j,~isnan(peaks_afteri(j,:)));  
                end
                if in.plot_diffs % 95% CI of difference of means
                    if in.per_diff % percent differences
                        ci_during(j,i,:) = bootci(in.M,@(x,y) 100*(mean(x)-mean(y))/mean(y),...
                                        peaks_duringij',peaks_beforeij');
                        if include_after
                            ci_after(j,i,:) = bootci(in.M,@(x,y) 100*(mean(x)-mean(y))/mean(y),...
                                            peaks_afterij',peaks_beforeij');
                        end
                    else % abs differences
                        ci_during(j,i,:) = bootci(in.M,@(x,y) mean(x)-mean(y),...
                                        peaks_duringij',peaks_beforeij');
                        if include_after
                            ci_after(j,i,:) = bootci(in.M,@(x,y) mean(x)-mean(y),...
                                            peaks_afterij',peaks_beforeij');
                        end
                    end
                else
                    if include_after
                        peak_cij = bootci(in.M,@mean,...
                            [peaks_beforeij',peaks_duringij',peaks_afterij']);
                        ci_after(j,i,:) = peak_cij(:,3);
                    else
                        peak_cij = bootci(in.M,@mean,...
                            [peaks_beforeij',peaks_duringij']);                        
                    end
                    ci_before(j,i,:) = peak_cij(:,1);
                    ci_during(j,i,:) = peak_cij(:,2);                    
                end                
            end
        end
    else

    end
    ax = subplot(num_amps,1,i);
    hold(ax,'on');
    if ~in.plot_diffs
        errorbar(roi_inds + x_vals(1),mean_peaks_beforei,...
                mean_peaks_beforei-squeeze(ci_before(:,i,1)),squeeze(ci_before(:,i,2))-mean_peaks_beforei,...
                'LineStyle','none','Marker','o','Color','k',...
                'MarkerFaceColor','k','CapSize',0,'MarkerSize',in.mean_marker_size)        
    else
        plot([0,num_rois+1],[0 0],'Color',0.4*[1 1 1],'LineWidth',0.5);
    end    
    if isempty(in.sig_mod_during)
        errorbar(roi_inds + x_vals(2),mean_peaks_duringi,...
                mean_peaks_duringi-squeeze(ci_during(:,i,1)),...
                squeeze(ci_during(:,i,2)),...
                'LineStyle','none','Marker','o','Color','r',...
                'MarkerFaceColor','r','CapSize',0,'MarkerSize',in.mean_marker_size)
    else
        mod_duringi = logical(in.sig_mod_during(:,i));
        errorbar(roi_inds(~mod_duringi) + x_vals(2),mean_peaks_duringi(~mod_duringi),...
                mean_peaks_duringi(~mod_duringi)-squeeze(ci_during(~mod_duringi,i,1)),...
                squeeze(ci_during(~mod_duringi,i,2)),...
                'LineStyle','none','Marker','o','Color','k',...
                'MarkerFaceColor','r','CapSize',0,'MarkerSize',in.mean_marker_size);
        hold on;
        errorbar(roi_inds(mod_duringi) + x_vals(2),mean_peaks_duringi(mod_duringi),...
                mean_peaks_duringi(mod_duringi)-squeeze(ci_during(mod_duringi,i,1)),...
                squeeze(ci_during(mod_duringi,i,2)),...
                'LineStyle','none','Marker',in.sig_marker,'Color',in.sig_color,...
                'MarkerFaceColor','r','CapSize',0,'MarkerSize',in.mean_marker_size)
    end
    if in.plot_after && include_after
        errorbar(roi_inds + x_vals(2),mean_peaks_afteri,...
                squeeze(ci_after(:,i,1)),squeeze(ci_before(:,i,2)),...
                'LineStyle','none','Marker','o','Color','b',...
                'MarkerFaceColor','b','CapSize',0,'MarkerSize',in.mean_marker_size)
    end
    box(ax,'off')
    if i == round(num_amps/2) || num_amps == 2
        ylabel(ax,ylabel_str);
    end
    if ~isempty(in.ax_titles{i})
        title(ax,in.ax_titles{i});
    end
    ax.XLim = [0.5,num_rois+0.5];    
end
xlabel(ax,'Synapse number');
setAxesUniformLim(fig,'YLim');
if in.cell_lines_on && ~isempty(in.num_rois_per_dish)
    for k = 1:length(fig.Children)
        ax = fig.Children(k);
        for i = 1:num_amps
            for j = 1:(length(dish_roi_borders)-1)           
                plot(ax,dish_roi_borders(j+1)*[1 1],ax.YLim,'k-');                    
            end
        end
    end
end
if in.save_fig
    if in.plot_diffs
        fig_name = sprintf('peaks_%s_%gROIs_per_diff%g',in.err_bar,num_rois,...
                            in.per_diff);
    else
        fig_name = sprintf('peaks_%s_%gROIs',in.err_bar,num_rois);
    end
    printFig(fig,in.fig_fold,fig_name);
end
