function plotTracesOverlaid(t,traces,varargin)
%PLOTTRACESOVERLAID ... 
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
in.cols = lines(size(traces,2)); 
in.x_lim = []; % main limits
in.y_lim = []; 
in.x_lim2 = []; % inset limits
in.y_lim2 = []; 
in.inset_pos = [0.4 0.4 0.5 0.5];
in.x_sbar_len1 = 0.5;
in.y_sbar_len1 = 0.2; 
in.x_sbar_len2 = 0.005;
in.y_sbar_len2 = 0.2; 
in.units = 'sec';
in.plot_peak_times = 0;
in = sl.in.processVarargin(in,varargin);
cols = mat2cell(in.cols,ones(1,size(traces,2)),3);
lhands = plot(t,traces); 
ax = gca;
hold(ax,'on'); 
box(ax,'off'); 
if ~isempty(in.x_lim)
    ax.XLim = in.x_lim;
end
if ~isempty(in.y_lim)
    ax.YLim = in.y_lim; 
end
set(lhands,{'color'},cols);
if ~isempty(in.x_sbar_len1) && in.x_sbar_len1 > 0    
    x0 = ax.XLim(1) + diff(ax.XLim)*0.01;
    x1 = x0 + in.x_sbar_len1; 
%     y1 = ax.YLim(2)*0.92; 
    y1 = max(traces,[],'all')*1.05;
    y0 = y1 - in.y_sbar_len1;
    plot(ax,[x0 x0 x1],[y0 y1 y1],'-k','LineWidth',2); 
end
axis(ax,'off');
if ~isempty(in.inset_pos)
    ax2 = axes('Position',in.inset_pos);    
    lhands = plot(ax2,t,traces); 
    hold(ax2,'on'); 
    box(ax2,'off')
    set(lhands,{'color'},cols);
    
    if ~isempty(in.x_lim)
        ax2.XLim = in.x_lim2;
    end
    if ~isempty(in.y_lim)
        ax2.YLim = in.y_lim2;
    end        
    if ~isempty(in.x_sbar_len2) && in.x_sbar_len2 > 0
        x0 = ax2.XLim(1) + diff(ax2.XLim)*0.05;
        x1 = x0 + in.x_sbar_len2;
%         y1 = ax2.YLim(2)*0.95;
        y1 = max(traces,[],'all')*1.05;
        y0 = y1 - in.y_sbar_len2;
        plot(ax2,[x0 x0 x1],[y0 y1 y1],'-k','LineWidth',2);
    end
    if in.plot_peak_times
        for i = 1:size(traces,2)
           [peak,peak_ind] = max(traces(:,i)); 
           plot(ax2,t(peak_ind)*[1 1],ax2.YLim,'--','Color',cols{i},...
               'LineWidth',0.5);
        end
    end
    axis(ax2,'off'); 
end
xlabel(ax,sprintf('time (%s)',in.units)); 
end