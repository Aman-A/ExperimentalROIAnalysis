function [p_hand,l_hand,Rsq,p,b] = plotCorrelation(x,y,varargin)
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
in.plot_regression_line = 0; 
in.alpha = 0.05; 
in.add_title = 1; 
in = sl.in.processVarargin(in,varargin);
p_hand = plot(x,y,'LineStyle','none','Marker',in.Marker,'Color',in.Color);
hold on;
xlabel(in.xlabel);
ylabel(in.ylabel);
if in.plot_unity_line
    l_hand = plot([min(x),max(x)],[min(y),max(y)],'--k');
else
    l_hand = []; 
end
axis([min(x),max(x),min(y),max(y)])
box off; 
if isrow(x); x = x'; end
if isrow(y); y = y'; end
[b,~,~,~,stats] = regress(y,[ones(length(x),1),x]);
Rsq = stats(1); p = stats(3); 
if in.plot_regression_line
    if p < in.alpha
        plot(x,b(1) + b(2)*x,'-','Color',in.Color)    
    else
        plot(x,b(1) + b(2)*x,'-','Color',0.6*[1 1 1])    
    end
end
if in.add_title
%     [R,p] = corrcoef(x,y);
    title(sprintf('R^{2} = %.3f, p = %.3f',Rsq,p)); 
end