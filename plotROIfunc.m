function plotROIfunc(func_output,func_name,stim_frames,sampling_rate,ax)
%PLOTROIFUNC ... 
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
% Todo: add optional plot styles for stim time points (point, vertical bar,
% etc.)

% AUTHOR    : Aman Aberra 
if nargin < 5 % create new figure, otherwise add to existing
    fig = figure;
    ax = gca;
end
if nargin < 4
    x = 1:size(func_output.(func_name),1); % frames    
    unit_str = 'frames';
else
    x = (1:size(func_output.(func_name),1))/sampling_rate; % convert frames to time in sec
    stim_frames = stim_frames/sampling_rate; 
    if length(stim_frames) == 1 % set t = 0 to single stimulus time
        x = x - stim_frames; 
        stim_frames = 0; 
    end
    unit_str = 'sec'; 
end

hold(ax,'on'); 
if strcmp(func_output.roi_mode,'combine')    
    display_names = {func_output.img_name};
    title_str = sprintf('%s: Baseline = %.1f a.u.',...
                         func_output.img_name,func_output.baseline);
else
    display_names = cellfun(@(x) sprintf('%s: %s',func_output.img_name,x),...
                            func_output.rois.names,'UniformOutput',0)';
    title_str = sprintf('%s: Baseline = %.1f ± %.1f a.u.',...
                        func_output.img_name,mean(func_output.baseline),...
                        std(func_output.baseline,0));
end
lns = plot(ax,x,func_output.(func_name)); % plot trace/s
set(lns,{'DisplayName'},display_names); % set legend names
% shadedErrorBar(x,mean(func_output.(func_name),2),std(func_output.(func_name),0,2),{'-k'}); hold on;
names = {ax.Children.DisplayName}; 
ind_stim_times = strcmp(names,'Stim times');
if ~any(ind_stim_times) % only plot if stim times don't already exist on this axis    
    plot(ax,stim_frames,ax.YLim(2)*0.99*ones(1,length(stim_frames)),...
        'r.','MarkerSize',8,'DisplayName','Stim times'); 
    names = {ax.Children.DisplayName};
    ind_stim_times = strcmp(names,'Stim times');
    all_inds = 1:length(ax.Children); 
    ax.Children = ax.Children([all_inds(~ind_stim_times),find(ind_stim_times)]); 
else    
%     global_peak = max([ax.Children(~ind_stim_times).YData],[],'all'); 
%     ax.Children(ind_stim_times).YData = global_peak*1.05; 
    ax.Children(ind_stim_times).YData = ax.YLim(2)*0.99*ones(1,length(stim_frames)); 
end
xlabel(ax,sprintf('time (%s)',unit_str)); ylabel(ax,'\Delta F/F_{0}')
box(ax,'off'); 
title(ax,title_str,'Interpreter','none'); 
% legend(ax.Children(~ind_stim_times)); 
legend(ax,'Interpreter','none','Box','off');