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
in.stim_marker_mode = 2; % 1 for points, 2 for vertical lines
in.show_y_tick_labels = 1; % for separate mode, shows ytick labels for ROIs
in = sl.in.processVarargin(in,varargin); 
if isempty(in.ax) % create new figure, otherwise add to existing
    figure;
    ax = gca;
else
    ax = in.ax; 
end
y = func_output.(func_name);
if regexp(func_name,'aligned','ONCE') 
%     std_y = std(y,0,ndims(y));
    if strcmp(func_name,'deltaF_F0_aligned')
        if strcmp(func_output.roi_func_mode,'combine')
            y = squeeze(mean(y,3,'omitnan')); % mean across trains or stimuli
        else
            y = squeeze(mean(y,3:ndims(y),'omitnan')); 
        end
    else
        if strcmp(func_output.roi_func_mode,'combine')
            y = squeeze(mean(y,[2 4],'omitnan')); % mean within trains
        else
%             y = squeeze(mean(y,3:ndims(y),'omitnan')); 
            y = mean(y,4,'omitnan'); 
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
            end
            y = y_all; 
        end
    end
end
if nargin < 4
    x = 1:size(y,1); % frames    
    unit_str = 'frames';
else    
    x = (1:size(y,1))/sampling_rate; % convert frames to time in sec
    stim_frames = stim_frames/sampling_rate; 
%     if length(stim_frames) == 1 % set t = 0 to single stimulus time
%         x = x - stim_frames; 
%         stim_frames = 0;     
%     end
    if ~isempty(stim_frames)
        x = x - stim_frames(1); 
        stim_frames = stim_frames - stim_frames(1); 
    end    
    if regexp(func_name,'aligned','ONCE')
        x = x - x(size(func_output.baseline_wind_inds,1)+1); 
    end
    unit_str = 'sec'; 
end
if isempty(in.rois)
    num_rois = length(func_output.roi_inds);
    roi_names = arrayfun(@(x) sprintf('ROI%g',x),func_output.roi_inds,'UniformOutput',0);
else
    num_rois = in.rois.num_rois; 
    roi_names = in.rois.names; 
end
hold(ax,'on'); 
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
    lns = plot(ax,x,y); % plot trace/s
%     lns = shadedErrorBar(x,y,std_y);
else
    display_names = arrayfun(@(x) sprintf('ROI%g',x),func_output.roi_inds,'UniformOutput',0);
%     display_names = roi_names;
%     display_names = cellfun(@(x) sprintf('%s: %s',func_output.img_name,x),...
%                             func_output.rois.names,'UniformOutput',0);
    if isrow(display_names)
       display_names = display_names'; % make column vector for setting DisplayName below
    end
    title_str = [func_output.img_name ':']; 
    if isfield(func_output,'baseline')
        title_str = {title_str, sprintf('B = %.1f ± %.1f a.u.',...
                                        mean(func_output.baseline(:,1)),...
                                        std(func_output.baseline(:,1),0))};
    end
%     title_str = [title_str sprintf(' %g ROIs',num_rois)];     
    if in.offset_factor > 0
        % Sort traces
        if ~all(in.sort_traces==0)
            if length(in.sort_traces) == 1
                peaks = max(y,[],1);
                if in.sort_traces == 1                
                    [~,sort_inds] = sort(peaks,2,'ascend');
                else 
                    [~,sort_inds] = sort(peaks,2,'descend');
                end
                y = y(:,sort_inds);
                display_names = display_names(sort_inds);
            elseif length(in.sort_traces) == size(y,2) % input indices 
                sort_inds = in.sort_traces; 
                y = y(:,sort_inds);
                display_names = display_names(sort_inds);
            end
        end
        % Set vertical offsets
%         if in.offset_factor < 1
%             offset = linspace(in.offset_factor*max(y,[],'all')*size(y,2),...
%                                 0,size(y,2));
%         else
           if strcmp(ax.YLimMode,'auto') % YLim wasn't set, use num_rois to set it and offset               
%                offset = linspace(1.4*num_rois-in.offset_factor,...
%                                 0,size(y,2));
%                offset = linspace(in.offset_factor*num_rois,0,size(y,2));
%                ax.YLim = [-0.2 offset(1)*(num_rois+1)/num_rois];
                offset = linspace(num_rois*in.offset_factor,...
                                    0,size(y,2));  
                ax.YLim = [-0.2 offset(1)+max(y(:,1))];
%                 ax.YLim = [-0.2 1.05*(offset(1)+max(y(:,1)))];
           else
                offset = linspace(num_rois*in.offset_factor,...
                                    0,size(y,2));  
%                offset = linspace(ax.YLim(2)-in.offset_factor,...
%                                 0,size(y,2));  
           end           
%         end
%         y = func_output.(func_name);
        
        lns = plot(ax,x,y+offset); % plot trace/s
        if in.show_y_tick_labels
            ax.YTick = fliplr(offset);
            ax.YTickLabel = length(offset):-1:1; 
            ax.YAxis.FontSize = 10;
        else
            ax.YAxis.Visible = 'off';
        end
        sbar_hand = plot(ax,ax.XLim(1)*ones(1,2),[ax.YLim(2)-in.sbar_len,ax.YLim(2)],...
                    'k','LineWidth',2,'DisplayName',...
                    sprintf('Scale bar = %g%%',100*in.sbar_len)); 
    else
        lns = plot(ax,x,y); % plot trace/s
    end
end
set(lns,{'DisplayName'},display_names); % set legend names

if isempty(regexp(func_name,'aligned','ONCE')) % don't add stim markers 
                                               % if plotting stim aligned 
                                               % traces
    stimpoints_hand = addStimPointsToPlot(stim_frames,in.stim_marker_mode,ax);
end
xlabel(ax,sprintf('time (%s)',unit_str)); 
if strcmp(func_name,'deltaF_F0')
    ylabel(ax,'\Delta F/F_{0}')
elseif strcmp(func_name,'deltaF')
    ylabel(ax,'\Delta F')
elseif regexp(func_name,'aligned','ONCE')
    ylabel(ax,'Mean \Delta F/F_{0}')
elseif strcmp(func_name,'mean')
    ylabel(ax,'mean F (a.u.)')
else
   ylabel(ax,func_name);  
end
box(ax,'off'); 
if in.title_on
    title(ax,title_str,'Interpreter','none','FontSize',8); 
end
% legend(ax.Children(~ind_stim_times)); 
if in.show_legend
    if strcmp(func_output.roi_func_mode,'combine')    
        legend(ax,[lns;stimpoints_hand(1);sbar_hand],'Interpreter','none',...
            'Box','off','Location','Best');
    else
        legend(ax,[lns;stimpoints_hand(1);sbar_hand],'Interpreter','none',...
            'Box','off','Location','EastOutside');
    end
end
end