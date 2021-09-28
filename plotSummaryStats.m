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
% in.rm_anova = 0;
in = sl.in.processVarargin(in,varargin); 
num_conditions = length(data_array);
mean_vals = cellfun(@mean,data_array,'UniformOutput',1);
std_vals = cellfun(@std,data_array,'UniformOutput',1);
% if in.rm_anova 
%     % Run Repeated Measures ANOVA
% %     data_table = cell2table(data_array);
%     data_table = table(); 
%     for i = 1:num_conditions
%         data_table = [data_table;[num2cell(data_array{i}'),... % values
%                                   num2cell((1:length(data_array{i}))'),... % trial indices
%                                   repmat(conditions(i),length(data_array{i}),1)]]; % condition name
%     end
%     data_table.Properties.VariableNames = {'response','trial','condition'};
%     % linear mixed-effects model, fixed-effects term for condition    
%     lme = fitlme(data_table,'response ~ 1 + condition');
%     lme2 = fitlme(data_table,'response ~ 1 + condition + (1 | trial)'); % include random effect for trial
%     lme3 = fitlme(data_table,'response ~ 1 + condition + (-1 + condition | trial)'); % include interaction between condition and trial
%     lme4 = fitlme(data_table,'response ~ 1 + condition + (1 | trial) + (-1 + condition | trial)'); % include interaction between condition and trial
%     lme5 = fitlme(data_table,'response ~ 1 + condition + (condition | trial)');
%     
% end
data_mat = nan(length(data_array),max(cellfun(@length,data_array,'UniformOutput',1))); 
for i = 1:length(data_array)
   data_mat(i,1:length(data_array{i})) = data_array{i}; 
end
%% Plot to current figure
rng(1); % ensure consistent jitter for identical data
fig = gcf; 
errorbar(mean_vals,std_vals,'-','LineWidth',2,...
         'Marker','o','Color',0.6*ones(1,3));
hold on;     
scatter(1:num_conditions,data_mat','ko','MarkerFaceColor','k','SizeData',12,...
        'jitter','on','jitterAmount',0.05);      
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