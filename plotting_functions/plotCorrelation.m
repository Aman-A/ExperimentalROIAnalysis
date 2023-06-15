function plotCorrelation(x,y,varargin)
%PLOTCORRELATION ... 
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
in.xlabel = '';
in.ylabel = ''; 
in.Marker = 'o';
in.Color = 'r';
in.plot_unity_line = 1; 
in.add_title = 1; 
in = sl.in.processVarargin(in,varargin);
plot(x,y,'LineStyle','none','Marker',in.Marker,'Color',in.Color);
hold on;
xlabel(in.xlabel);
ylabel(in.ylabel);
if in.plot_unity_line
    plot([min(x),max(x)],[min(y),max(y)],'--k')   
end
axis([min(x),max(x),min(y),max(y)])
box off; 
if in.add_title
    [R,p] = corrcoef(x,y);
    title(sprintf('R^{2} = %.3f, p = %.3f',R(1,2)^2,p(1,2)^2));
end