function stimpoints_hand = addStimPointsToPlot(stim_frames,stim_marker_mode,ax,...
                                               varargin)
%ADDSTIMPOINTSTOPLOT ... 
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
if nargin < 3
    ax = gca;
end
if nargin < 2
    stim_marker_mode = 1; % 1 - plot points, 2 - plot vertical dashed red lines
end
in.stim_dur = []; % duration of stimuli (same units as plot's time base), 
                  % should be vector same length as stim_frames
in.stim_leg_name = 'Stim times';
in = sl.in.processVarargin(in,varargin);

leg_names = {ax.Children.DisplayName};
ind_stim_times = strcmp(leg_names,in.stim_leg_name);
if ~any(ind_stim_times) % only plot if stim times don't already exist on this axis
    if stim_marker_mode == 1 || length(stim_frames(:)) > 100
        stimpoints_hand = plot(ax,stim_frames,ax.YLim(2)*0.99*ones(1,length(stim_frames)),...
            'r.','MarkerSize',8,'DisplayName','Stim times');
    else
        stimpoints_hand = plot(ax,[stim_frames(:)';stim_frames(:)';nan(size(stim_frames(:)'))],...
            [ax.YLim'.*[1;0.99].*ones(2,length(stim_frames(:)'));nan(size(stim_frames(:)'))],...
            'r--','LineWidth',0.5,'DisplayName','Stim times');
    end
    leg_names = {ax.Children.DisplayName};
    ind_stim_times = strcmp(leg_names,'Stim times');
    all_inds = 1:length(ax.Children);
    ax.Children = ax.Children([all_inds(~ind_stim_times),find(ind_stim_times)]);
else
    %     global_peak = max([ax.Children(~ind_stim_times).YData],[],'all');
    %     ax.Children(ind_stim_times).YData = global_peak*1.05;
    ax.Children(ind_stim_times).YData = ax.YLim(2)*0.99*ones(1,length(stim_frames));
end

end