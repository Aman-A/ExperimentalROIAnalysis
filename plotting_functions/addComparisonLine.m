function addComparisonLine(x1,x2,y,tick_len,varargin)
%ADDCOMPARISONLINE for displaying statistical significance
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
in.ax = gca;
in.col = 'k';
in.lw = 1.5; 
in = sl.in.processVarargin(in,varargin);
% main line
ax = in.ax; 
hold(ax,'on');
plot(ax,[x1 x2],[y y],'Color',in.col,'LineWidth',in.lw);
% ticks
plot(ax,[x1, x1, nan, x2, x2],y+[-tick_len, 0, nan, 0,-tick_len],...
    'Color',in.col,'LineWidth',in.lw)