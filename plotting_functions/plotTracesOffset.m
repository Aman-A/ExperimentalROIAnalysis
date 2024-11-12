function [lns,varargout] = plotTracesOffset(x,y,offset_factor,varargin)
%PLOTTRACESOFFSET ... 
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
in.ax = []; 
in.sort_traces = 0; 
in.show_y_tick_labels = 1; % for separate mode, shows ytick labels for ROIs
in.sbar_len = 0.5; 
in.plot_settings = {};
in.font_size = 10; 
in.sbar_str = ''; 
in = sl.in.processVarargin(in,varargin);
if isempty(in.ax)
    ax = gca;    
else
    ax = in.ax;     
end
hold(ax,'on');
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
    elseif length(in.sort_traces) == size(y,2) % input indices
        sort_inds = in.sort_traces;
        y = y(:,sort_inds);        
    end
    varargout = {sort_inds};
else
    varargout = {[]}; 
end
% Set vertical offsets
offset = linspace(size(y,2)*offset_factor,...
    0,size(y,2));
if strcmp(ax.YLimMode,'auto') % YLim wasn't set, set now
    %             ax.YLim = (offset(1)+max(y(:,1)))*[-0.05 1];
    ax.YLim = [min(y(:,end)),1.02*max(y+offset,[],'all')];
    % else
    %     offset = linspace(num_rois*in.offset_factor,...
    %         0,size(y,2));
end
lns = plot(ax,x,y+offset,in.plot_settings{:}); % plot trace/s
if in.show_y_tick_labels
    y_ticks = offset(end:-1:1);
    y_tick_labels = length(offset):-1:1;
    if length(offset) > 60   % display every other tick label                
        y_tick_labels = numericVec2chars(y_tick_labels,'%g');
        y_tick_labels(2:2:end) = {''};
        % y_ticks = y_ticks(1:2:end); 
    end
    ax.YTick = y_ticks;
    ax.YTickLabel = y_tick_labels;
    ax.YAxis.FontSize = in.font_size;
else
    ax.YAxis.Visible = 'off';
end
if in.sbar_len > 0
    sbar_hand = plot(ax,ax.XLim(1)*ones(1,2)+0.01*range(ax.XLim),[ax.YLim(2)-in.sbar_len,ax.YLim(2)],...
        'k','LineWidth',3,'DisplayName',in.sbar_str);
    varargout = {varargout,sbar_hand};
else
    varargout = {varargout,[]};
end