function setAxesUniformLim(fig,x_or_y_lim,ax_lims)
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
if nargin == 2
    ax_lims = []; 
end
if nargin == 1
    x_or_y_lim = 'YLim';    
end

lims = [inf,-inf];
axes_all = []; 
for i = 1:length(fig.Children)
    if strcmp(fig.Children(i).Type,'axes')
        axis(fig.Children(i),'auto');
        lims(1) = min(fig.Children(i).(x_or_y_lim)(1),lims(1));
        lims(2) = max(fig.Children(i).(x_or_y_lim)(2),lims(2));
        axes_all = [axes_all,fig.Children(i)];
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
