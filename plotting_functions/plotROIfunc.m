function plotROIfunc(func_output,func_name,stim_frames,sampling_rate,...
                     varargin)
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
in.ax = []; 
in.rois = []; % use for labeling
in.show_legend = 1;
in.title_on = 1;
in.offset_factor = 1.01; % 1.01 default 1 - offset lines by offset_factor*max(func_output) 
                      % >1 - offset based on y axis limits - offset_factor
in.sbar_len = 1; % for separate roi_func_mode plots
in.sort_traces = 0; % 1 for ascending, 2 for descending
in.stim_marker_mode = []; % 1 for points, 2 for vertical lines, 3 for horz (needs stim_pulse_dur)
in.stim_pulse_dur = []; % duration of stimulus pulses, default ignore
in.show_y_tick_labels = 1; % for separate mode, shows ytick labels for ROIs
in.indicator_dir = 1; % 1 = positive going, -1 = negative going
in.plot_settings = {};
in.peak_align = 1;
in.stim_frames2 = []; 
in.stim_pulse_dur2 = []; 
in = sl.in.processVarargin(in,varargin); 
if isempty(in.ax) % create new figure, otherwise add to existing
    figure;
    ax = gca;
else
    ax = in.ax; 
end
y = func_output.(func_name);
if regexp(func_name,'mean','ONCE')
    if strcmp(func_output.roi_func_mode,'separate') && size(y,2) > 1
        non_nan_frames = find(~isnan(y(:,1)));
        y = y - y(non_nan_frames(1),:); % start all traces at 0 for plot
    end
%     y = y - mean(y,1,'omitnan'); % set baseline to mean of trace
    sbar_str = sprintf('Scale bar = %g a.u.',in.sbar_len);
    y_flipped = 0; 
else
    sbar_str = sprintf('Scale bar = %g%%',100*in.sbar_len);
    y = y*in.indicator_dir; 
    if in.indicator_dir < 0
        y_flipped = 1;
    else
        y_flipped = 0;
    end
end
baseline_wind = size(func_output.baseline_wind_inds,1);
if nargin < 4 || isempty(sampling_rate)
    x = (1:size(y,1))'; % frames    
    unit_str = 'frames';
else    
    x = (1:size(y,1))'/sampling_rate; % convert frames to time in sec
    stim_frames = stim_frames/sampling_rate; 
%     if length(stim_frames) == 1 % set t = 0 to single stimulus time
%         x = x - stim_frames; 
%         stim_frames = 0;     
%     end
    % 2nd source
    if ~isempty(in.stim_frames2)
        in.stim_frames2 = in.stim_frames2/sampling_rate;
    end
    in.stim_pulse_dur2 = in.stim_pulse_dur2/sampling_rate; 
    % set t = 0 as first stim frame
    if ~isempty(stim_frames) && numel(stim_frames) < 40
%     if ~isempty(stim_frames) && ~strcmp(func_name,'deltaF_F0')
        x = x - stim_frames(1); 
        in.stim_frames2 = in.stim_frames2 - stim_frames(1);
        stim_frames = stim_frames - stim_frames(1);         
    end       
    if regexp(func_name,'aligned','ONCE')
        x = x - x(baseline_wind+1); 
    end
    unit_str = 'sec'; 
   
end

if regexp(func_name,'aligned','ONCE') 
%     std_y = std(y,0,ndims(y));
    if strcmp(func_name,'deltaF_F0_aligned')
        if strcmp(func_output.roi_func_mode,'combine')
            if in.peak_align
                [x,y] = averagePeakAlignedTraces(x,y,baseline_wind+1,3);
            else
                y = squeeze(mean(y,3,'omitnan')); % mean across trains or stimuli
            end
        else
            y = squeeze(mean(y,3:ndims(y),'omitnan')); 
        end
    else
        if strcmp(func_output.roi_func_mode,'combine')
            if in.peak_align
                [x,y] = averagePeakAlignedTraces(x,y,baseline_wind+1,4);
            else
                y = squeeze(mean(y,[2 4],'omitnan')); % mean within trains
            end
        else
%             y = squeeze(mean(y,3:ndims(y),'omitnan')); 
            if in.peak_align
                [x,y] = averagePeakAlignedTraces(x,y,baseline_wind+1,4);
            else
                y = mean(y,4,'omitnan'); 
            end
            % concatenate average response to each 
            % train, plot as single trace in each ROI
            if size(stim_frames,1) > 1
                y_all = zeros(size(y,1)*size(stim_frames,1),size(y,2));
                starti = 1; endi = size(y,1);
                for i = 1:size(stim_frames,1)
                    y_all(starti:endi,:) = y(:,:,i);
                    starti = endi + 1; 
                    endi = endi + size(y,1);
                end
                y = y_all; 
                x = (1:size(y,1))'/sampling_rate; % convert frames to time in sec
                x = x - x(baseline_wind+1); 
            end            
        end
    end
end

if isempty(in.rois)
    num_rois = length(func_output.roi_inds);    
    roi_names = numericVec2chars(func_output.roi_inds,'ROI%g');    
else
    num_rois = in.rois.num_rois; 
%     roi_names = in.rois.names; 
    roi_names = numericVec2chars(func_output.roi_inds,'ROI%g');     
end
hold(ax,'on'); 
sbar_hand = [];
if strcmp(func_output.roi_func_mode,'combine')    
    if length(func_output.roi_inds) < num_rois
        roi_str = sprintf('%g/%g ROIs',length(func_output.roi_inds),...
                          num_rois); 
    else
        roi_str = sprintf('all %g ROIs',num_rois);
    end
    display_names = strcat(func_output.img_name,{': '},roi_str);
    title_str = func_output.img_name;
    if isfield(func_output,'baseline')
       title_str = [title_str sprintf(': Baseline = %.1f a.u.',...
                                        func_output.baseline(1))];
    end
%     title_str = [title_str sprintf(' (%s combined)',roi_str)];
    % Plot on single axis
    lns = plot(ax,x,y,in.plot_settings{:}); % plot trace/s
%     lns = shadedErrorBar(x,y,std_y);   
else
    display_names = roi_names;
%     display_names = cellfun(@(x) sprintf('%s: %s',func_output.img_name,x),...
%                             func_output.rois.names,'UniformOutput',0);
    if isrow(display_names)
       display_names = display_names'; % make column vector for setting DisplayName below
    end
    title_str = [func_output.img_name ':']; 
    if isfield(func_output,'baseline')
        title_str = {title_str, sprintf('B = %.1f ± %.1f a.u.',...
                                        mean(func_output.baseline(:,1),'omitnan'),...
                                        std(func_output.baseline(:,1),0,'omitnan'))};
    end
%     title_str = [title_str sprintf(' %g ROIs',num_rois)];     
    if in.offset_factor > 0
        [lns,sort_inds,sbar_hand] = plotTracesOffset(x,y,in.offset_factor,...
                                            'ax',ax,'sort_traces',in.sort_traces,...
                                            'show_y_tick_labels',in.show_y_tick_labels,...
                                            'sbar_len',in.sbar_len,...
                                            'plot_settings',in.plot_settings,...
                                            'sbar_str',sbar_str);
        if in.sort_traces
            display_names = display_names(sort_inds);
        end
    else
        lns = plot(ax,x,y,in.plot_settings{:}); % plot trace/s
    end
end
set(lns,{'DisplayName'},display_names); % set legend names

if isempty(regexp(func_name,'aligned','ONCE'))
    stimpoints_hand = addStimPointsToPlot(stim_frames,in.stim_marker_mode,ax,...
                                         'stim_pulse_dur',in.stim_pulse_dur,...
                                         'plot_y_factor',0.97);    
    if ~isempty(in.stim_frames2)
        stimpoints_hand2 = addStimPointsToPlot(in.stim_frames2,3,ax,...
                                        'stim_pulse_dur',in.stim_pulse_dur2,...
                                        'add_more_pts',1,'color','r',...
                                        'stim_leg_name','Stim2',...
                                        'plot_y_factor',0.99);
    end
else
    stimpoints_hand = addStimPointsToPlot(x(baseline_wind+1),in.stim_marker_mode,...
                                            ax,'stim_pulse_dur',in.stim_pulse_dur);    
end
xlabel(ax,sprintf('time (%s)',unit_str)); 
ylabel_str = funcNameToLabel(func_name,y_flipped);
ylabel(ax,ylabel_str)
box(ax,'off'); 
if in.title_on
    title(ax,title_str,'Interpreter','none','FontSize',8); 
end
% legend(ax.Children(~ind_stim_times)); 
if in.show_legend
    leg_objs = [lns;sbar_hand];
    if ~isempty(stimpoints_hand)
        leg_objs = [lns;stimpoints_hand(1);sbar_hand];           
    end
    if ~isempty(stimpoints_hand2)
        leg_objs = [lns;stimpoints_hand(1);stimpoints_hand2(1);sbar_hand];           
    end
    if strcmp(func_output.roi_func_mode,'combine')    
        leg_location = 'Best';
    else
        leg_location = 'EastOutside';
    end
    if length(leg_objs) > 10
        num_columns = 2;
    else
        num_columns = 1; 
    end
    legend(ax,leg_objs,'Interpreter','none',...
            'Box','off','Location',leg_location,'NumColumns',num_columns);
end
end