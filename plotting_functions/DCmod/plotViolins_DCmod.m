function plotViolins_DCmod(peaks_before,peaks_during,peaks_after,varargin)
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
in.linlimit = 0.1; % linear between +/- linlimit, log outside
in.width = 0.1; 
in.plot_pts = 1; 
in.pt_markerSize = 1; 
in.plot_means = 1; 
in.norm_to_before = 0; 
in.plot_diffs = 0; 
in.per_diff = 0; 
in.plot_after = 1; 
in.plot_amps = []; 
in.num_dishes_per_amp = []; 
in.y_lim = [];
in.save_fig = 0; 
in.fig_fold = '.';
in.convert_to_per = 0; 
in.remove_neg_vals = 0; 
in.connect_medians = 0; 
in = sl.in.processVarargin(in,varargin);
if ~iscell(peaks_before)
    % convert to 1 x num_amps cell array
    peaks_before = mat2cell(peaks_before,size(peaks_before,1),ones(1,size(peaks_before,2)));
    peaks_during = mat2cell(peaks_during,size(peaks_during,1),ones(1,size(peaks_during,2)));
    peaks_after = mat2cell(peaks_after,size(peaks_after,1),ones(1,size(peaks_after,2)));
end
y_unit = ''; % default unitless
if in.norm_to_before   
    % Normalize to mean of peaks before DC
    peaks_during = cellfun(@(x,y) x./mean(y,2,'omitnan'),peaks_during,peaks_before,'UniformOutput',0);
    peaks_after = cellfun(@(x,y) x./mean(y,2,'omitnan'),peaks_after,peaks_before,'UniformOutput',0);
    peaks_before = cellfun(@(x,y) x./mean(y,2,'omitnan'),peaks_before,peaks_before,'UniformOutput',0);
    y_unit = ' (norm.)';
elseif in.convert_to_per
    peaks_before = cellfun(@(x) x*100,peaks_before,'UniformOutput',0);
    peaks_during = cellfun(@(x) x*100,peaks_during,'UniformOutput',0);    
    peaks_after = cellfun(@(x) x*100,peaks_after,'UniformOutput',0);
    y_unit = ' (%)';
end
if in.plot_diffs && in.per_diff
    y_unit = ' (%)';
end
if in.plot_means % take mean of all peaks within ROI
    peaks_before = cellfun(@(x) mean(x,2,'omitnan'),peaks_before,'UniformOutput',0);
    peaks_during = cellfun(@(x) mean(x,2,'omitnan'),peaks_during,'UniformOutput',0);
    peaks_after = cellfun(@(x) mean(x,2,'omitnan'),peaks_after,'UniformOutput',0);
end
if in.plot_after
    x_vals = [-0.25 0 0.25];
else
    x_vals = [-0.2 0.2];
end
fig = gcf;
num_amps = length(peaks_before);
med_before = zeros(1,num_amps);
med_during = zeros(1,num_amps);
med_after = zeros(1,num_amps);
for i = 1:num_amps    
    % Remove nans
    peaks_beforei = peaks_before{i}(~isnan(peaks_before{i}));
    peaks_duringi = peaks_during{i}(~isnan(peaks_during{i}));    
    peaks_afteri = peaks_after{i}(~isnan(peaks_after{i}));
    
    if in.remove_neg_vals
        peaks_beforei = peaks_beforei(peaks_beforei>=0);
        peaks_duringi = peaks_duringi(peaks_duringi>=0);
        peaks_afteri = peaks_afteri(peaks_afteri>=0);
    end
    if in.plot_diffs  % in.plot_means should be 1    
        peaks_duringi = peaks_duringi - peaks_beforei;
        peaks_afteri = peaks_afteri - peaks_beforei;              
        if in.per_diff
            peaks_duringi = 100*peaks_duringi./peaks_beforei;
            peaks_afteri = 100*peaks_afteri./peaks_beforei;
        end
    end
    med_before(i) = median(peaks_beforei);
    med_during(i) = median(peaks_duringi);
    med_after(i) = median(peaks_afteri);
    if ~(in.norm_to_before && in.plot_means) && ~in.plot_diffs
        % if in.plot_pts
        %     plotSpread(peaks_beforei,'xValues',i+x_vals(1),...
        %                 'distributionColors',0.8*ones(1,3),'markerSize',...
        %                 in.pt_markerSize); hold on;
        % end
        hV1 = Violin(peaks_beforei,i+x_vals(1),'ViolinColor',0.4*[1 1 1],'Width',in.width,...
                   'BoxColor',0.4*[1 1 1],'BoxWidth',in.width,...
                   'ShowData',logical(in.plot_pts),'ShowNotches',false,...
                   'DataMarkerSize',in.pt_markerSize); hold on; 
        if strcmp(in.y_mode,'loglinlog')
            apply_loglinlog_Violin(hV1,in.linlimit);
        end
    end
    hV2 = Violin(peaks_duringi,i+x_vals(2),'ViolinColor',[1 0 0],'Width',in.width,...
                   'BoxColor',[1 0 0],'BoxWidth',in.width,...
                   'ShowData',logical(in.plot_pts),'ShowNotches',false,...
                   'DataMarkerSize',in.pt_markerSize); hold on; 
    if strcmp(in.y_mode,'loglinlog')
        apply_loglinlog_Violin(hV2,in.linlimit);
    end
    if in.plot_after
        hV3 = Violin(peaks_afteri,i+x_vals(3),'ViolinColor',[0 0 1],'Width',in.width,...
                   'BoxColor',[0 0 1],'BoxWidth',in.width,...
                   'ShowData',logical(in.plot_pts),'ShowNotches',false,...
                   'DataMarkerSize',in.pt_markerSize); 
        if strcmp(in.y_mode,'loglinlog')
            apply_loglinlog_Violin(hV3,in.linlimit);
        end
    end    
end
ax = gca;
box(ax,'off');
ax.XTick = 1:num_amps;
if ~isempty(in.plot_amps)
    ax.XTickLabel = in.plot_amps;
    xlabel('Current (mA)');
end
ax.XLim = [ax.XTick(1) + x_vals(1) - in.width,ax.XTick(end) + x_vals(end) + in.width];
% if ~in.plot_diffs
%     ax.YLim(1) = 0; 
% end
if isempty(in.y_lim)
    y_lim = ax.YLim;
else
    y_lim = in.y_lim;
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
    if in.plot_means
        ylabel(ax,sprintf('Mean peak \\Delta F/F_{0}%s',y_unit))
    else
        ylabel(ax,sprintf('Peak \\Delta F/F_{0}%s',y_unit))
    end
end
if in.connect_medians
    if strcmp(in.y_mode,'loglinlog')
        med_before = loglinlogtransform(med_before,in.linlimit);
        med_during = loglinlogtransform(med_during,in.linlimit);
        med_after = loglinlogtransform(med_after,in.linlimit);
    end
    if ~(in.norm_to_before && in.plot_means) && ~in.plot_diffs
        plot((1:num_amps)+x_vals(1),med_before,'k');
    end
    plot((1:num_amps)+x_vals(2),med_during,'r');
    plot((1:num_amps)+x_vals(3),med_after,'b');
end
if in.save_fig
    fig_name = sprintf('peaks_violin_%gROIs_mean%g_norm%g_diff%g,%s',size(peaks_before{1},1),...
                        in.plot_means,in.norm_to_before,in.plot_diffs,in.y_mode);
    printFig(fig,in.fig_fold,fig_name);
end