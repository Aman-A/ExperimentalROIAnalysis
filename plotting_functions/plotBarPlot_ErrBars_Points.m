function plotBarPlot_ErrBars_Points(data,varargin)
%PLOTBARPLOT_ERRBARS_POINTS ... 
%  
%   Inputs 
%   ------ 
%   data : cell array or matrix
%         If matrix, should be number of pts x number of conditions
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.x_vals = []; 
in.plot_err = 'sem'; % 'std' or 'sem' to use st dev or standard error for error bars
in.err_bar_lw = 2; % error bar line width
in.bar_labels = {}; % cell array of string labels for bars
in.bar_cols = [0.4 0.4 0.4]; 
in.bar_alphas = 0.4;
in.bar_width = 0.8;
in.bar_edgecolor = 'none';
in.bar_linewidth = 0.5;
in.font_name = 'Arial';
in.font_size = 16; 
in.jitter_amount = 0; 
in.plot_pts = 1; 
in.pt_size = 24; 
in.pt_cols = []; % color data for scatter plot
in.pt_marker = 'o';
in.print_level = 0; 
in.connect_pts = 0; 
in = sl.in.processVarargin(in,varargin);
if iscell(data)
    n_pts = cellfun(@length,data,'UniformOutput',1);
    % convert to matrix, use max number of points for all columns
    data_mat = nan(max(n_pts),length(data));
    for i = 1:length(data)
        data_mat(1:n_pts(i),i) = data{i}; 
    end
else
    data_mat = data; 
    n_pts = zeros(1,size(data_mat,2));
    for i = 1:size(data_mat,2)
        n_pts(i) = sum(~isnan(data_mat(:,i)));
    end
end
n_bars = size(data_mat,2); 
if isempty(in.x_vals)
    x_vals = 1:n_bars;
else
    x_vals = in.x_vals; 
end
% calculate mean and error bars
mean_data = mean(data_mat,1,'omitnan');
std_data = std(data_mat,0,1,'omitnan');
if strcmp(in.plot_err,'sem')
    sem_data = std_data./sqrt(n_pts);
    err_bars = sem_data;
elseif strcmp(in.plot_err,'std')
    err_bars = std_data;
end
if in.print_level > 0
    fprintf('Mean +/- %s:\n',in.plot_err);
    for i = 1:length(mean_data)
        fprintf('  %g: %.4f +/- %.4f\n',i,mean_data(i),err_bars(i))
    end
end
if ~isempty(in.bar_cols)
    if ~iscell(in.bar_cols) && size(in.bar_cols,1) == 1 % uniform bar color
        in.bar_cols = repmat({in.bar_cols},n_bars,1);
    elseif ~iscell(in.bar_cols) && size(in.bar_cols,1) == size(data,2) % RGB array
        in.bar_cols = mat2cell(in.bar_cols,ones(1,size(in.bar_cols,1)),3);
    end
end
if ~isempty(in.bar_alphas)
    if isscalar(in.bar_alphas) % uniform bar alpha
        in.bar_alphas = repmat(in.bar_alphas,n_bars,1);
    end
end
for i = 1:n_bars
    % plot mean as bar
    b = bar(x_vals(i),mean_data(i),in.bar_width,'EdgeColor',in.bar_edgecolor); hold on;       
    if ~isempty(in.bar_cols)
        b.FaceColor = in.bar_cols{i}; 
    end
    if ~isempty(in.bar_alphas)
        b.FaceAlpha = in.bar_alphas(i); 
        b.EdgeColor = in.bar_cols{i};
    end
end
ax = gca; 
box(ax,'off');
% data points
if in.plot_pts 
    if in.connect_pts
        l = plot(x_vals,data_mat,'LineWidth',0.5,'Marker',in.pt_marker,'MarkerSize',in.pt_size);
        if ~isempty(in.pt_cols)
            if size(in.pt_cols,1) == 1; in.pt_cols = repmat(in.pt_cols,length(l),1); end;                 
            for i = 1:length(l)
                l(i).Color = in.pt_cols(i,:);
            end
        end
    else
        if in.jitter_amount > 0
            jitter_str = 'on';   
            jitter_width = in.jitter_amount;
            xjitter_str = 'rand';
        else            
            jitter_str = 'off';
            jitter_width = 1; % placeholder
            xjitter_str = 'none';
        end 
        if isempty(in.pt_cols)
            % s = scatter(x_vals,data_mat,in.pt_size,in.pt_marker,'jitter','on','jitterAmount',in.jitter_amount);
            for i = 1:length(x_vals)
                s = swarmchart(repmat(x_vals(i),size(data_mat,1),1),data_mat(:,i),in.pt_size,in.pt_marker,...
                                'jitter',jitter_str,'XJitterWidth',jitter_width,...
                                'XJitter',xjitter_str);
            end
        else
            if (iscell(in.pt_cols) && length(in.pt_cols) > 1) || (ismatrix(in.pt_cols) && size(in.pt_cols,1) > 1)
                % for i = 1:length(x_vals)
                %     if iscell(in.pt_cols)
                %         s = scatter(x_vals(i),data_mat(:,i),in.pt_size,...
                %             in.pt_cols{i},in.pt_marker,...
                %             'jitter',jitter_str,'XJitterWidth',jitter_width,...
                %             'XJitter',xjitter_str);
                %     else
                %         s = scatter(x_vals(i),data_mat(:,i),in.pt_size,...
                %             in.pt_cols(i,:),in.pt_marker,'jitter',jitter_str,...
                %             'XJitterWidth',jitter_width,'XJitter',xjitter_str);
                %     end
                % end
                for i = 1:length(x_vals)                    
                    s = swarmchart(repmat(x_vals(i),size(data_mat,1),1),data_mat(:,i),in.pt_size,in.pt_cols,in.pt_marker,...
                            'jitter',jitter_str,'XJitterWidth',jitter_width,...
                            'XJitter',xjitter_str);
                end
            else
                s = swarmchart(repmat(x_vals,size(data_mat,1),1),data_mat,in.pt_size,in.pt_cols,in.pt_marker,...
                        'jitter',jitter_str,'XJitterWidth',jitter_width,...
                        'XJitter',xjitter_str);
            end
        end
    end
end
% error bars
e = errorbar(x_vals,mean_data,err_bars,'ko','LineStyle','none','LineWidth',in.err_bar_lw,...
            'Marker','none');
ax.XTick = x_vals;
if ~isempty(in.bar_labels)
    ax.XTickLabel = in.bar_labels;
end
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontName = in.font_name;
ax.FontSize = in.font_size;