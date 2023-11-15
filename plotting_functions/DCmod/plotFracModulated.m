function plotFracModulated(mean_peaks_before,mean_peaks_during,...
                            mean_peaks_after,varargin)
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
in.sig_mod_during = [];
in.sig_mod_after = []; 
in.bar_cols = [0.6,0.6,0.6;0.4023    0.6602    0.8086;0.9336    0.5391    0.3828];
in.bar_mode = 2;    
in.save_fig = 0;
in.amp_labels = []; 
in.fig_fold = '.';
in = sl.in.processVarargin(in,varargin);
mean_peaks_during_diff = mean_peaks_during - mean_peaks_before; 
mean_peaks_after_diff = mean_peaks_after - mean_peaks_before; 
num_rois = sum(~isnan(mean_peaks_during),1);
if isempty(in.sig_mod_during)
    %  TODO: use SEM comparison method
else
    % nan_inds = isnan(mean_peaks_during_diff);    
    % in.sig_mod_during(nan_inds) = 0;
    % in.sig_mod_after(nan_inds) = 0;
    peak_inc_rois = mean_peaks_during_diff > 0 & in.sig_mod_during;
    peak_dec_rois = mean_peaks_during_diff < 0 & in.sig_mod_during;
    per_inc_rois = squeeze(100*sum(peak_inc_rois,1,'omitnan')./num_rois)';
    per_dec_rois = squeeze(100*sum(peak_dec_rois,1,'omitnan')./num_rois)';
    per_nochange_rois = 100 - per_inc_rois - per_dec_rois;
    % 0 - no change, 1 decrease, 2 increase
end
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
ax.XTick = 1:size(mean_peaks_before,2);
if ~isempty(in.amp_labels)
    ax.XTickLabel = in.amp_labels;
end
legend({'No change','Decrease','Increase'},'Box','off','Location','bestoutside');
ylabel('% ROIs');
box off;
title(sprintf('Proportion of %g ROIs modulated by DC',max(num_rois)))
if in.save_fig
    printFig(fig,in.fig_fold,['per_change_rois_bar' num2str(in.bar_mode)]);
end

end