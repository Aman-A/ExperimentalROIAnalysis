function plotTracesOverlaidGrid_ROIs(t,traces,roi_inds,varargin)
%PLOTTRACESOVERLAID_ROIS Plots grid of aligned traces from each ROI
%  
%   Inputs 
%   ------ 
%   t : num_timepoints x 1 vector
%   traces : num_timepoints x num_events matrix
%   roi_inds : num_events x 1 vector
%              Each element has index of ROI for corresponding event (column) 
%              in traces 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.peaks = []; 
in.xaxis_label = 'time (sec)'; 
in.yaxis_label = '\Delta F/F_{0}';
in.y_lim = []; 
in.title = ''; 
in = sl.in.processVarargin(in,varargin); 
rois_plot_inds = unique(roi_inds,'stable');
num_rois_plot = length(rois_plot_inds);
[Nrows,Ncols] = getSubplotDimensions(num_rois_plot);
if isempty(in.peaks) % calc peaks on full trace (simple approach)
    event_peaks = cell(1,num_rois_plot);
    for i = 1:num_rois_plot
        ii = roi_inds(i); 
        event_peaks{i} = max(traces(:,roi_inds == ii),[],1)';
    end
    event_peaks_lin = cell2mat(event_peaks');
else
    event_peaks = in.peaks; 
    event_peaks_lin = cell2mat(event_peaks'); 
end
for i = 1:num_rois_plot
    ax = subplot(Nrows,Ncols,i);
    ii = rois_plot_inds(i);        
    plot(t,traces(:,roi_inds==ii)); hold on;
    plot(t,mean(traces(:,roi_inds==ii),2,'omitnan'),'k','LineWidth',2);
    title(sprintf('%g: Peak %.2f +/- %.2f (n = %g)',ii,...
        mean(event_peaks{ii}),...
        std(event_peaks{ii},0),...
        size(traces(:,roi_inds==ii),2)));
    if i >= ((Nrows-1)*Ncols)
        xlabel(ax,in.xaxis_label);
    end
    if (mod(i,Ncols) == 1 || num_rois_plot == 1)
        ylabel(in.yaxis_label);
    end
    box(ax,'off');
    if ~isempty(in.y_lim)
        ylim(in.y_lim)
    else
%         if ~isempty(in.peaks) % use peaks to set uniform y limis
%             ylim([-max(event_peaks_lin)*0.5 1.05*max(event_peaks_lin)])
%         end
    end
    xlim([t(1),t(end)]);
end
sgtitle(in.title,'Interpreter','none');