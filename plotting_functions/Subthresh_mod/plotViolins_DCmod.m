function [med_before,med_during,med_after] = plotViolins_DCmod(peaks_before,...
                                            peaks_during,peaks_after,varargin)
%PLOTVIOLINS_DCMOD ... 
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
in.y_mode = 'lin'; % 'lin' for linear, 'loglinlog' for log-linear-log
in.y_grid_on = 0; 
in.linlimit = 0.1; % linear between +/- linlimit, log outside
in.width = 0.1; 
in.plot_pts = 1; 
in.pt_markerSize = 1; 
in.plot_means = 1; 
in.norm_to_before = 0; 
in.mean_rois = 0; % take mean across peaks within ROI
in.plot_diffs = 0; 
in.per_diff = 0; 
in.plot_after = 1; 
in.plot_conds = []; % conditions (e.g., amplitudes or pulse durations)
in.y_lim = [];
in.save_fig = 0; 
in.fig_fold = '.';
in.fig_name_prefix = 'peaks_violin';
in.plot_xlabel = 'Current (mA)';
in.include_ylabel = 1;
in.convert_to_per = 0; 
in.remove_neg_vals = 0; 
in.connect_medians = 0; 
in.before_color = 0.4*[1 1 1];
in.during_color = [1 0 0];
in.after_color = [0 0 1]; 
in.font_name = 'Arial';
in.font_size = 18; 
in = sl.in.processVarargin(in,varargin);
if ~iscell(peaks_before)
    % convert to 1 x num_amps cell array
    peaks_before = mat2cell(peaks_before,size(peaks_before,1),ones(1,size(peaks_before,2)));
    peaks_during = mat2cell(peaks_during,size(peaks_during,1),ones(1,size(peaks_during,2)));
    if in.plot_after
        peaks_after = mat2cell(peaks_after,size(peaks_after,1),ones(1,size(peaks_after,2)));
    end
end

y_unit = ''; % default unitless
if in.norm_to_before   
    % Normalize to mean of peaks before DC
    peaks_before = cellfun(@(x,y) x./mean(y,2,'omitnan'),peaks_before,peaks_before,'UniformOutput',0);
    peaks_during = cellfun(@(x,y) x./mean(y,2,'omitnan'),peaks_during,peaks_before,'UniformOutput',0);
    if in.plot_after
        peaks_after = cellfun(@(x,y) x./mean(y,2,'omitnan'),peaks_after,peaks_before,'UniformOutput',0);
    end    
    y_unit = ' (norm.)';
elseif in.convert_to_per
    peaks_before = cellfun(@(x) x*100,peaks_before,'UniformOutput',0);
    peaks_during = cellfun(@(x) x*100,peaks_during,'UniformOutput',0);    
    if in.plot_after
        peaks_after = cellfun(@(x) x*100,peaks_after,'UniformOutput',0);
    end
    y_unit = ' (%)';
end
if in.plot_diffs && in.per_diff
    y_unit = ' (%)';
end
if in.plot_means % take mean of all peaks within ROI
    peaks_before = cellfun(@(x) mean(x,2,'omitnan'),peaks_before,'UniformOutput',0);
    peaks_during = cellfun(@(x) mean(x,2,'omitnan'),peaks_during,'UniformOutput',0);
    if in.plot_after
        peaks_after = cellfun(@(x) mean(x,2,'omitnan'),peaks_after,'UniformOutput',0);
    end
end
num_conds = length(peaks_before);

if in.plot_diffs
    if in.plot_after
        x_shift = [-0.2 -0.2 0.2];
    else
        x_shift = [0 0];
    end
    x_vals = 1:num_conds;
else
    if in.plot_after
        x_shift = [-0.25 0 0.25];
        x_vals = 1:num_conds;
    else
        % x_vals = [-0.2 0.2];
        x_shift = [-0.15 0.15];
        x_vals = 0:0.8:(0.8*(num_conds-1));
        % x_vals = 1:num_conds;
    end
end
if (isnumeric(in.during_color) && size(in.during_color,1) == 1)
    in.during_color = repmat({in.during_color},1,num_conds);
end
fig = gcf;
med_before = zeros(1,num_conds);
med_during = zeros(1,num_conds);
if in.plot_after
    med_after = zeros(1,num_conds);
end
for i = 1:num_conds    
    % Remove nans
    peaks_beforei = peaks_before{i}(~isnan(peaks_before{i}));
    peaks_duringi = peaks_during{i}(~isnan(peaks_during{i}));    
    if in.plot_after
        peaks_afteri = peaks_after{i}(~isnan(peaks_after{i}));
    end
    
    if in.remove_neg_vals
        peaks_beforei = peaks_beforei(peaks_beforei>=0);
        peaks_duringi = peaks_duringi(peaks_duringi>=0);
        if in.plot_after
            peaks_afteri = peaks_afteri(peaks_afteri>=0);
        end
    end
    if in.plot_diffs  % in.plot_means should be 1    
        peaks_duringi = peaks_duringi - peaks_beforei;
        if in.plot_after
            peaks_afteri = peaks_afteri - peaks_beforei;              
        end
        if in.per_diff
            peaks_duringi = 100*peaks_duringi./peaks_beforei;
            if in.plot_after
                peaks_afteri = 100*peaks_afteri./peaks_beforei;
            end
        end
    end
    med_before(i) = median(peaks_beforei);
    med_during(i) = median(peaks_duringi);
    if in.plot_after
        med_after(i) = median(peaks_afteri);
    end
    if ~(in.norm_to_before && in.plot_means) && ~in.plot_diffs
        % if in.plot_pts
        %     plotSpread(peaks_beforei,'xValues',i+x_vals(1),...
        %                 'distributionColors',0.8*ones(1,3),'markerSize',...
        %                 in.pt_markerSize); hold on;
        % end
        hV1 = Violin(peaks_beforei,x_vals(i)+x_shift(1),'ViolinColor',in.before_color,'Width',in.width,...
                   'BoxColor',in.before_color,'BoxWidth',in.width,...
                   'ShowData',logical(in.plot_pts),'ShowNotches',false,...
                   'DataMarkerSize',in.pt_markerSize,'MedianMarkerSize',16); hold on; 
        if strcmp(in.y_mode,'loglinlog')
            apply_loglinlog_Violin(hV1,in.linlimit);
        end
    end
    hV2 = Violin(peaks_duringi,x_vals(i)+x_shift(2),'ViolinColor',in.during_color{i},'Width',in.width,...
                   'BoxColor',in.during_color{i},'BoxWidth',in.width,...
                   'ShowData',logical(in.plot_pts),'ShowNotches',false,...
                   'DataMarkerSize',in.pt_markerSize,'MedianMarkerSize',16); hold on; 
    if strcmp(in.y_mode,'loglinlog')
        apply_loglinlog_Violin(hV2,in.linlimit);
    end
    if in.plot_after
        hV3 = Violin(peaks_afteri,x_vals(i)+x_shift(3),'ViolinColor',in.after_color,'Width',in.width,...
                   'BoxColor',in.after_color,'BoxWidth',in.width,...
                   'ShowData',logical(in.plot_pts),'ShowNotches',false,...
                   'DataMarkerSize',in.pt_markerSize,'MedianMarkerSize',16); 
        if strcmp(in.y_mode,'loglinlog')
            apply_loglinlog_Violin(hV3,in.linlimit);
        end
    end    
end
ax = gca;
box(ax,'off');
ax.XTick = x_vals;
if ~isempty(in.plot_conds)
    ax.XTickLabel = in.plot_conds;
    xlabel(in.plot_xlabel);
end
ax.XLim = [ax.XTick(1) + x_shift(1) - in.width*2,ax.XTick(end) + x_shift(end) + in.width*2];
% if ~in.plot_diffs
%     ax.YLim(1) = 0; 
% end
if isempty(in.y_lim)
    y_lim = ax.YLim;
else
    y_lim = in.y_lim;
    ax.YLim = y_lim; 
end
if strcmp(in.y_mode,'loglinlog')
    if isempty(in.y_lim)
        y_lim = 10.^(y_lim);        
    end
    set_ytick_loglinlog(y_lim,y_lim(2),in.linlimit,ax);     
end
if in.plot_diffs
    ylabel(ax,sprintf('Change in peak \\Delta F/F_{0}%s',y_unit))
    plot(ax.XLim,[0 0],'k--','LineWidth',1);
    ax.Children = [ax.Children(2:end);ax.Children(1)]; % put at back
else
    if in.include_ylabel
        if in.plot_means
            ylabel(ax,sprintf('Mean peak \\Delta F/F_{0}%s',y_unit))
        else
            ylabel(ax,sprintf('Peak \\Delta F/F_{0}%s',y_unit))
        end
    end
end
if in.connect_medians
    if strcmp(in.y_mode,'loglinlog')
        med_before = loglinlogtransform(med_before,in.linlimit);
        med_during = loglinlogtransform(med_during,in.linlimit);
        if in.plot_after
            med_after = loglinlogtransform(med_after,in.linlimit);
        end
    end
    if ~(in.norm_to_before && in.plot_means) && ~in.plot_diffs
        plot((1:num_conds)+x_shift(1),med_before,'k');
    end
    if iscell(in.during_color)
        plot((1:num_conds)+x_shift(2),med_during,'Color','k');
    else
        plot((1:num_conds)+x_shift(2),med_during,'Color',in.during_color);
    end
    if in.plot_after
        if iscell(in.during_color)
         plot((1:num_conds)+x_shift(3),med_after,'Color',0.4*[1 1 1]);
        else
            plot((1:num_conds)+x_shift(3),med_after,'Color',in.after_color);
        end
    end
end
if strcmp(in.y_mode,'log')
    ax.YScale = 'log';
    if in.convert_to_per
        ax.YTickLabel = numericVec2chars(ax.YTick,'%g');
    end
    if in.y_grid_on
        ax.YGrid = 'on';
    end
    % ax.YMinorGrid = 'off';
end
if ~in.plot_after
    med_after = []; 
end
ax.FontName = in.font_name;
ax.FontSize =  in.font_size;
ax.YColor = 'k';
ax.XColor = 'k';
% ax.LineWidth = 1;
if in.save_fig
    fig_name = sprintf('%s_%gROIs_after%g_mean%g_norm%g_diff%g_perdiff_%g_%s',...
                        in.fig_name_prefix,size(peaks_before{1},1),in.plot_after,...
                        in.plot_means,in.norm_to_before,in.plot_diffs,...
                        in.per_diff,in.y_mode);
    printFig(fig,in.fig_fold,fig_name,'formats',{'fig','png'},...
             'resolutions',{'','-r800',''});
end