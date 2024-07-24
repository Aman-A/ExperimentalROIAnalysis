function stats = plotFracModulated(peaks_before,peaks_during,...
                            peaks_after,varargin)
%PLOTFRACMODULATED ... 
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
% TODO: HANDLE NANs
in.alpha = 0.05;
in.adjust_fdr = 0; % 1 to adjust for false discovery rate of 5% across all tests
in.fdr_rate = 0.05; 
in.plot_after = 0; 
in.plot_test = 'ranksum'; % kstest2, ranksum, or ttest2
in.sig_mod_during = [];
in.sig_mod_after = []; 
in.bar_cols = [0.6,0.6,0.6;0.4023    0.6602    0.8086;0.9336    0.5391    0.3828];
in.bar_mode = 1;    
in.save_fig = 0;
in.x_labels = []; 
in.fig_fold = '.';
in.title_on = 1;
in.add_val_labels = 0;
in = sl.in.processVarargin(in,varargin);
%%
mean_peaks_before = cell2mat(cellfun(@(x) mean(x,2,'omitnan'),peaks_before,'UniformOutput',0));
mean_peaks_during = cell2mat(cellfun(@(x) mean(x,2,'omitnan'),peaks_during,'UniformOutput',0));
mean_peaks_during_diff = mean_peaks_during - mean_peaks_before; 
include_rows = all(~isnan(mean_peaks_before),2);
if any(~include_rows)
    fprintf('Removing %g points with missing data\n',sum(~include_rows));    
    mean_peaks_during_diff = mean_peaks_during_diff(include_rows,:);    
end
if isempty(peaks_after)    
    include_after = 0; 
else    
    mean_peaks_after = cell2mat(cellfun(@(x) mean(x,2,'omitnan'),peaks_after,'UniformOutput',0));
    mean_peaks_after_diff = mean_peaks_after - mean_peaks_before; 
    include_after = 1; 
    mean_peaks_after_diff = mean_peaks_after_diff(include_rows,:);    
end
%%
num_amps = length(peaks_before);
num_rois = size(peaks_before{1},1);
if isempty(in.sig_mod_during)    
    is_normal = nan(num_rois,num_amps);
    % KS test
    h_during = nan(num_rois,num_amps);
    p_during = nan(num_rois,num_amps);    
    % Wilcoxon rank sum (mann whitney u-test) non-parametric,
    % independent "t-test"
    h_during2 = nan(num_rois,num_amps);
    p_during2 = nan(num_rois,num_amps);    
    zvals_during = nan(num_rois,num_amps);    
    % t-test
    h_during3 = nan(num_rois,num_amps);
    p_during3 = nan(num_rois,num_amps);       
    % after
    h_after = nan(num_rois,num_amps);
    p_after = nan(num_rois,num_amps);    
    h_after2 = nan(num_rois,num_amps);
    p_after2 = nan(num_rois,num_amps);
    zvals_after = nan(num_rois,num_amps);
    h_after3 = nan(num_rois,num_amps);
    p_after3 = nan(num_rois,num_amps);    
    for i = 1:num_amps
        peaks_beforei = peaks_before{i}; 
        peaks_duringi = peaks_during{i}; 
        if include_after
            peaks_afteri = peaks_after{i};   
        end
        for j = 1:num_rois
            if ~all(isnan(peaks_beforei(j,:)))
                peaks_beforeij = peaks_beforei(j,:);
                peaks_duringij = peaks_duringi(j,:);
                
                % KS test on peaks before stim
                is_normal(j,i) = ~kstest(peaks_beforeij); % 1 if comes from normal distribution
                % KS test effect of stim
                [h_during(j,i),p_during(j,i)] = kstest2(peaks_beforeij,peaks_duringij,'Alpha',in.alpha);
                
                % Wilcoxon ranksum test/U-test on peaks during/after vs. before
                [p_during2(j,i),h_during2(j,i),stats_during] = ranksum(peaks_duringij,peaks_beforeij,'Alpha',in.alpha); % wilcoxon signed rank                
                zvals_during(j,i) = stats_during.zval;                
                % 2-way independent t-test
                [h_during3(j,i),p_during3(j,i)] = ttest2(peaks_duringij,peaks_beforeij,'Alpha',in.alpha); % wilcoxon paired
                if include_after
                    peaks_afterij = peaks_afteri(j,:);
                    [h_after(j,i),p_after(j,i)] = kstest2(peaks_beforeij,peaks_afterij,'Alpha',in.alpha);
                    [p_after2(j,i),h_after2(j,i),stats_after] = ranksum(peaks_afterij,peaks_beforeij,'Alpha',in.alpha); % wilcoxon signed rank
                    zvals_after(j,i) = stats_after.zval;
                    [h_after3(j,i),p_after3(j,i)] = ttest2(peaks_afterij,peaks_beforeij,'Alpha',in.alpha); % wilcoxon paired
                end
            end
        end        
    end
    if in.adjust_fdr
        [h_during,~,~,p_during] = fdr_bh(p_during,in.fdr_rate,'pdep','no');
        [h_during2,~,~,p_during2] = fdr_bh(p_during2,in.fdr_rate,'pdep','no');
        [h_during3,~,~,p_during3] = fdr_bh(p_during3,in.fdr_rate,'pdep','no');
        if include_after
            [h_after,~,~,p_after] = fdr_bh(p_after,in.fdr_rate,'pdep','no');
            [h_after2,~,~,p_after2] = fdr_bh(p_after2,in.fdr_rate,'pdep','no');
            [h_after3,~,~,p_after3] = fdr_bh(p_after3,in.fdr_rate,'pdep','no');
        end
        fprintf('Adjusted for false discovery rate of %g %%\n',100*in.fdr_rate)
    end    
    if strcmp(in.plot_test,'kstest2')
        in.sig_mod_during = h_during;
        in.sig_mod_after = h_after;
    elseif strcmp(in.plot_test,'ranksum')
        in.sig_mod_during = h_during2;
        in.sig_mod_after = h_after2;
    elseif strcmp(in.plot_test,'ttest2')
        in.sig_mod_during = h_during3;
        in.sig_mod_after = h_after3;
    end
    stats = struct(); 
    stats.is_normal = is_normal;
    stats.h_during = h_during;
    stats.p_during = p_during;
    stats.h_after = h_after;
    stats.p_after = p_after;
    stats.h_during2 = h_during2;
    stats.p_during2 = p_during2;
    stats.h_after2 = h_after2;
    stats.p_after2 = p_after2;
    stats.zvals_during = zvals_during;
    stats.zvals_after = zvals_after;
    stats.h_during3 = h_during3;
    stats.p_during3 = p_during3;
    stats.h_after3 = h_after3;
    stats.p_after3 = p_after3;        
else    
    % nan_inds = isnan(mean_peaks_during_diff);    
    % in.sig_mod_during(nan_inds) = 0;
    % in.sig_mod_after(nan_inds) = 0;        
    stats = []; 
end
in.sig_mod_during = in.sig_mod_during(include_rows,:);
if include_after
    in.sig_mod_after = in.sig_mod_after(include_rows,:);
end
% Modulation during
% 0 - no change, 1 decrease, 2 increase
peak_inc_rois = mean_peaks_during_diff > 0 & in.sig_mod_during;
peak_dec_rois = mean_peaks_during_diff < 0 & in.sig_mod_during;
per_inc_rois = squeeze(100*sum(peak_inc_rois,1,'omitnan')./num_rois)';
per_dec_rois = squeeze(100*sum(peak_dec_rois,1,'omitnan')./num_rois)';
per_nochange_rois = 100 - per_inc_rois - per_dec_rois;
stats.peak_inc_rois = peak_inc_rois;
stats.peak_dec_rois = peak_dec_rois;
% Modulation after
if include_after
    peak_inc_rois_after = mean_peaks_after_diff > 0 & in.sig_mod_after;
    peak_dec_rois_after = mean_peaks_after_diff < 0 & in.sig_mod_after;
    per_inc_rois_after = squeeze(100*sum(peak_inc_rois_after,1,'omitnan')./num_rois)';
    per_dec_rois_after = squeeze(100*sum(peak_dec_rois_after,1,'omitnan')./num_rois)';
    per_nochange_rois_after = 100 - per_inc_rois_after - per_dec_rois_after;
    stats.peak_inc_rois_after = peak_inc_rois_after;
    stats.peak_dec_rois_after = peak_dec_rois_after;
end
%% Plot
fig = gcf;
if in.bar_mode == 1 % stacked bars
    b = bar([per_nochange_rois,per_dec_rois,per_inc_rois],'stacked');
else
    b = bar([per_nochange_rois,per_dec_rois,per_inc_rois]);
end
for i = 1:size(in.bar_cols,1)
    b(i).FaceColor = in.bar_cols(i,:);
end
ax = gca;
ax.XTick = 1:size(mean_peaks_during_diff,2);
if ~isempty(in.x_labels)
    ax.XTickLabel = in.x_labels;
end
legend({'No change','Decreased','Increased'},'Box','off',...
        'Location','northoutside','Orientation','horizontal');
ylabel('% synapses');
box off;
if in.title_on
    title(sprintf('Proportion of %g ROIs modulated by DC',max(num_rois)))
end
if in.add_val_labels && in.bar_mode == 1
    xt = ax.XTick;     
    % yd = reshape([b.YData],2,[])';     
    yd = reshape([b.YData],num_amps,[])';     
    barbase = cumsum([zeros(1,size(yd,2)); yd(1:end-1,:)],1);
    basepos = yd/2 + barbase;
    for i = 1:size(yd,2)
        val_labels = numericVec2chars(yd(:,i),'%.0f%%');
        val_labels(yd(:,i) < 4) = {''};
        text(xt(i)*ones(size(basepos(:,i))), basepos(:,i), val_labels, ...
            'HorizontalAlignment','center','FontName','Arial','FontSize',18)
    end
end
ax.YLim = [0 105];
if in.save_fig
    printFig(fig,in.fig_fold,sprintf('per_change_rois_bar%g_%s',in.bar_mode,in.plot_test));
end
if include_after && in.plot_after
    fig = gcf;
    if in.bar_mode == 1 % stacked bars
        b = bar([per_nochange_rois_after,per_dec_rois_after,per_inc_rois_after],'stacked');
    else
        b = bar([per_nochange_rois_after,per_dec_rois_after,per_inc_rois_after]);
    end
    for i = 1:size(in.bar_cols,1)
        b(i).FaceColor = in.bar_cols(i,:);
    end
    ax = gca;
    ax.XTick = 1:size(mean_peaks_after,2);
    if ~isempty(in.x_labels)
        ax.XTickLabel = in.x_labels;
    end
    legend({'No change','Decrease','Increase'},'Box','off','Location','bestoutside');
    ylabel('% ROIs');
    box off;
    title(sprintf('Proportion of %g ROIs modulated after DC',max(num_rois)))
    if in.save_fig
        printFig(fig,in.fig_fold,sprintf('per_change_rois_after_bar%g_%s',in.bar_mode,in.plot_test));
    end
end
end