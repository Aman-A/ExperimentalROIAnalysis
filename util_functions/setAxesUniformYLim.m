function setAxesUniformYLim(fig)
%SETAXESUNIFORMYLIM Set all y axis limits of axes in figure to be uniform,
%using min and max across axes
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

y_lims = [inf,-inf];
axes_all = []; 
for i = 1:length(fig.Children)
    if strcmp(fig.Children(i).Type,'axes')
        y_lims(1) = min(fig.Children(i).YLim(1),y_lims(1));
        y_lims(2) = max(fig.Children(i).YLim(2),y_lims(2));
        axes_all = [axes_all,fig.Children(i)];
    end
end
ylim(axes_all,y_lims);
