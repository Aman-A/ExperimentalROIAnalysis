function plotTracesOverlaidGrid(t,traces_all,err_all,varargin)
%PLOTTRACESOVERLAIDGRID Helper function for plotTracesOverlaid, plots sets
% of traces in separate axes of same figure
%  
%   Inputs 
%   ------ 
%   t : vector or cell array
%      either time vector for all traces or 1 x num_conditions cell array
%      of time vectors 
%   traces_all : 1 x num_conditions cell array
%                each element of array has num_time_points x num_traces 
%                of traces to plot overlaid on separate axes
%   err_all : 1 x num_conditions cell array
%                each element of array has num_time_points x num_traces 
%                of error values 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.fig_units = 'centimeters';
in.fig_size = [50 25];
in.inset_pos = []; % [0.4 0.4 0.5 0.5] 
in.x_lim = []; % main limits
in.y_lim = []; 
in.x_lim2 = []; % inset limits
in.y_lim2 = []; 
in.x_sbar_len1 = 0.1;
in.y_sbar_len1 = 0.2; 
in.x_sbar_len2 = 0.005;
in.y_sbar_len2 = 0.2; 
in.save_fig = 0;
in.fig_dir = './';
in.fig_name = 'traces_overlaid';
in.title_on = 1;
in.plot_func = 'deltaF_F0';
in.leg_labels = ''; 
in.colors = []; 
in.mode = 1; % 1 - plot traces from conditions on same axes
             % 2 - plot traces from same condition on same axes
in = sl.in.processVarargin(in,varargin);
% Format plotTracesOverlaid options
topts = struct(); 
topts.inset_pos = in.inset_pos; 
topts.x_lim = in.x_lim;
topts.y_lim = in.y_lim;
topts.x_lim2 = in.x_lim2;
topts.y_lim2 = in.y_lim2;
topts.x_sbar_len1 = in.x_sbar_len1;
topts.y_sbar_len1 = in.y_sbar_len1; 
topts.x_sbar_len2 = in.x_sbar_len2;
topts.y_sbar_len2 = in.y_sbar_len2; 
if ~isempty(in.colors)
    topts.cols = in.colors; 
end
% Reformat traces_all cell array
if nargin < 2
    err_all = []; 
end
trace_rows = cellfun(@(x) size(x,1), traces_all,'UniformOutput',1);
trace_cols = cellfun(@(x) size(x,2), traces_all,'UniformOutput',1);
assert(all(trace_rows == trace_rows(1)),'All conditions should have same number of time points')
assert(all(trace_cols == trace_cols(1)),'All conditions should have same number of columns')
if in.mode == 1
    Nax = trace_cols(1);  % number of separate axes
else
    Nax = length(traces_all);
end
[Nrows,Ncols] = getSubplotDimensions(Nax);
Nt = trace_rows(1); % number of time points
Nconds = length(traces_all); % number of conditions
%% Plot
fig = figure('Units','normalized');
fig.Position(1:2) = [0.01 0.01]; % place at bottom left corner
fig.Units = in.fig_units; 
if ~isempty(in.fig_size)
    fig.Position(3:4) = in.fig_size;
end
ti = t; % set t if constant
for i = 1:Nax            
    if in.mode == 1
        if iscell(t)
            ti = zeros(Nt,Nconds);
        end
        tracesi = zeros(Nt,Nconds);
        erri = zeros(Nt,Nconds);
        for j = 1:Nconds
            tracesi(:,j) = traces_all{j}(:,i);        
            if ~isempty(err_all)
                erri(:,j) = err_all{j}(:,i);
            end
            if iscell(t)
                ti(:,j) = t{j}(:,i);
            end
        end
    else
        ti = t{i};
        tracesi = traces_all{i}; 
        if ~isempty(err_all)
            erri = err_all{i}; 
        end
    end
    ax = subplot(Nrows,Ncols,i);
%     for k = 1:size(tracesi,2)
%         shadedErrorBar(t,tracesi(:,k),erri(:,k),'lineProps',{'Color',in.colors(k,:)})
%     end
    plotTracesOverlaid(ti,tracesi,topts); 
    if in.title_on && Nax > 1
        if in.mode == 1
            title(ax,num2str(i));
        else
            title(ax,strrep(in.leg_labels{i},'_',' '))
        end
    end
    if i < ((Nrows-1)*Ncols)
        xlabel(ax,'');
    end
    if (mod(i,Ncols) == 1 || Nax == 1) && isempty(in.x_sbar_len1)
        if strcmp(in.plot_func,'deltaF_F0')
            ylabel(ax,'\Delta F/F_{0}')
        elseif regexp(in.plot_func,'deltaF_F0_aligned')
            ylabel(ax,'Mean \Delta F/F_{0}')
        else
            ylabel(ax,in.plot_func);
        end
    else
        ylabel(ax,''); 
    end
    if ~isempty(in.leg_labels)
        if i == Nax % i == Ncols 
            if Nax == Nrows*Ncols
                ax_leg = ax; 
            else
                ax_leg = subplot(Nrows,Ncols,i+1); % plot on next empty axis                
                plotTracesOverlaid([0;1],nan(2,Nconds),topts)
                axis(ax_leg,'off');
            end
            if in.mode == 1
                legend(ax_leg,strrep(in.leg_labels,'_',' '),'Box','off');                            
            end
        end
    end
end
if in.save_fig
    printFig(fig,in.fig_dir,in.fig_name);
end
end
