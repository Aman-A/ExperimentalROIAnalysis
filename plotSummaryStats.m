function plotSummaryStats(data_array,time_starts,conditions,name,units)
%PLOTSUMMARYSTATS ...
%
%   Inputs
%   ------
%   data_array : cell array
%                each cell includes vector of scalar metric computed for
%                each trial within that condition
%   Optional Inputs
%   ---------------
%   Outputs
%   -------
%   Examples
%   ---------------

% AUTHOR    : Aman Aberra
num_conditions = length(data_array);
mean_vals = cellfun(@mean,data_array,'UniformOutput',1);
std_vals = cellfun(@std,data_array,'UniformOutput',1);
errorbar(mean_vals,std_vals,'-ko','LineWidth',2);
hold on;
ax = gca;
ax.FontSize = 16;
ax.XTick = 1:num_conditions;
ax.XTickLabel = conditions;
ax.TickLabelInterpreter = 'none';
if isempty(units)
     ylabel(sprintf('%s',name));
else
     ylabel(sprintf('%s (%s)',name,units));
end
xlabel('Condition');
ax.XLim = [0.5 num_conditions + 0.5];
% ax.YLim(1) = 0;
box(ax,'off'); grid(ax,'on');
% Add time labels for each condition
text(1:num_conditions,ones(1,num_conditions)*(ax.YLim(1)+0.05*diff(ax.YLim)),...
     cellfun(@(x) sprintf('%.0f min',x),time_starts,'UniformOutput',0),...
     'FontSize',14);