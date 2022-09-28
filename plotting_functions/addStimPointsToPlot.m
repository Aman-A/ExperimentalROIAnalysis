function stimpoints_hand = addStimPointsToPlot(stim_frames,stim_marker_mode,ax,...
                                               varargin)
%ADDSTIMPOINTSTOPLOT ... 
%  
%   Inputs 
%   ------ 
%   stim_frames : vector
%   stim_marker_mode : scalar (1,2, or 3)
%                       1 - plot points, 2 - plot vertical dashed red lines
%                       3 - horz bar (requires stim_pulse_dur to be set)                          
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.stim_pulse_dur = []; % duration of stimuli (same units as plot's time base), 
                  % should be vector same length as stim_frames
in.stim_leg_name = 'Stim times';
in.color = 'r';
in = sl.in.processVarargin(in,varargin);
if nargin < 3
    ax = gca;
end
if nargin < 2 || isempty(stim_marker_mode)
    if length(stim_frames(:)) > 100
        stim_marker_mode = 1;
    elseif ~isempty(in.stim_pulse_dur) 
        stim_marker_mode = 3; 
    else
        stim_marker_mode = 2;
    end    
end

leg_names = {ax.Children.DisplayName};
ind_stim_times = strcmp(leg_names,in.stim_leg_name);
if ~any(ind_stim_times) % only plot if stim times don't already exist on this axis
    if stim_marker_mode == 1
        stimpoints_hand = plot(ax,stim_frames,ax.YLim(2)*0.99*ones(1,length(stim_frames)),...
            'Color',in.color,'Marker','.','MarkerSize',8,'DisplayName','Stim times');
    elseif stim_marker_mode == 2
        stimpoints_hand = plot(ax,[stim_frames(:)';stim_frames(:)';nan(size(stim_frames(:)'))],...
            [ax.YLim'.*[1;0.99].*ones(2,length(stim_frames(:)'));nan(size(stim_frames(:)'))],...
            'Color',in.color,'LineStyle','--','LineWidth',0.5,'DisplayName','Stim times');
    elseif stim_marker_mode == 3
        if isempty(in.stim_pulse_dur)
            error('Need to set stim_pulse_dur for stim_marker_mode = 3')
        end
        stimpoints_hand = plot(ax,...
          [stim_frames(:)';stim_frames(:)'+in.stim_pulse_dur(:);nan(size(stim_frames(:)'))],...
          [ax.YLim(2).*[0.99;0.99].*ones(2,length(stim_frames(:)'));nan(size(stim_frames(:)'))],...
            'Color',in.color,'LineStyle','-','LineWidth',1,'DisplayName','Stim times');
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