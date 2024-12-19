function setAxesUniformLim(fig,x_or_y_lim,ax_lims,ax_inds)
%setAxesUniformLim(fig,x_or_y_lim,ax_lims) 
% Set all y axis limits of axes in figure to be uniform,
% using min and max across axes if unset
% 
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
if nargin < 4
    ax_inds = []; 
end
if nargin < 3
    ax_lims = []; 
end
if nargin < 2
    x_or_y_lim = 'YLim';    
end
ax_strings = {'YLim','XLim'};
other_ax = ax_strings{~strcmp(x_or_y_lim,ax_strings)};
lims = [inf,-inf];
axes_all = []; 
if isempty(ax_inds)
    ax_inds = 1:length(fig.Children);
end
if isscalar(ax_inds) && isempty(ax_lims) % leave auto axes
    return; 
end
for i = ax_inds
    if strcmp(fig.Children(i).Type,'axes')
        other_axlimsi = fig.Children(i).(other_ax);
        axis(fig.Children(i),'auto');
        lims(1) = min(fig.Children(i).(x_or_y_lim)(1),lims(1));
        lims(2) = max(fig.Children(i).(x_or_y_lim)(2),lims(2));
        axes_all = [axes_all,fig.Children(i)];
        fig.Children(i).(other_ax) = other_axlimsi;
    end
end
if ~isempty(ax_lims)
    lims = ax_lims; 
end
if strcmp(x_or_y_lim,'YLim')
    ylim(axes_all,lims);
else
    xlim(axes_all,lims);
end
