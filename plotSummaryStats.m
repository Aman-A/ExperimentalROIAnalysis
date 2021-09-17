function plotSummaryStats(data_array,time_starts,conditions,name,units,varargin)
%PLOTSUMMARYSTATS ...
%
%   Inputs
%   ------
%   data_array : cell array
%                each cell includes vector of scalar metric computed for
%                each trial within that condition
%   time_starts : 
%   Optional Inputs
%   ---------------
%   Outputs
%   -------
%   Examples
%   ---------------

% AUTHOR    : Aman Aberra
in.exp_date = '';
in.reporter = '';
in.dish = '';
in.save_fig = 1; 
in.formats = {'fig','png'}; 
in.resolutions = {[],'-r300'};
in.fig_dir = fullfile(getDataFold(),'figs');       
in = sl.in.processVarargin(in,varargin); 
num_conditions = length(data_array);
mean_vals = cellfun(@mean,data_array,'UniformOutput',1);
std_vals = cellfun(@std,data_array,'UniformOutput',1);
%% Plot to current figure
fig = gcf; 
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
if ~isempty(time_starts)
    assert(length(time_starts) == num_conditions,'Number of times does not match number of conditions'); 
    % Add time labels for each condition
    text(1:num_conditions,ones(1,num_conditions)*(ax.YLim(1)+0.05*diff(ax.YLim)),...
         cellfun(@(x) sprintf('%.0f min',x),time_starts,'UniformOutput',0),...
         'FontSize',14);
end
% Add title 
title_str = '';
if ~isempty(in.exp_date)
   title_str = [title_str 'Date: ' in.exp_date];     
end
if ~isempty(in.reporter)
   title_str = [title_str ', ' in.reporter];    
end
if ~isempty(in.dish)
   title_str = [title_str ', ' in.dish];    
end
title(title_str,'Interpreter','none'); 
if in.save_fig
    rep_chars = {' ','{','}','\','/'}; % replace in quantity name for file saving
    empty_chars = repmat({''},1,length(rep_chars));
   if isempty(in.exp_date) || isempty(in.reporter) || isempty(in.dish)       
       fig_name = regexprep(name,rep_chars,empty_chars); % remove spaces
   else       
       fig_name = [regexprep(name,rep_chars,empty_chars) '_' in.exp_date '_' in.reporter '_' in.dish]; 
   end   
   printFig(fig,in.fig_dir,fig_name,'formats',in.formats,'resolutions',in.resolutions);  
end
end