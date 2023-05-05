function plotExperimentTracesOverlaidGrid(experiment_output,plot_func,varargin)
%PLOTEXPERIMENTTRACESOVERLAIDGRID Calls plotTracesOverlaidGrid using output
% of plotTrials_multipleConditions and plot_settings
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
in.fig_units = 'centimeters';
if strcmp(experiment_output.plot_settings.roi_func_mode,'combine')
%     in.fig_size = [19.8 9.1]; 
    in.fig_size = [38 11];
else
    in.fig_size = [50 25];    
end
in.fig_dir = './';
% in.fig_name = [plot_func,'_' num2str(length(experiment_output.conditions)),'conds'];
in.fig_name = '';
in.x_lim = [];  % main axis limits
in.y_lim = []; 
in.x_sbar_len1 = []; % main axis scale bar length
in.save_fig = 0;
in.cond_inds = []; % condition indices, default use all
in.norm_peak_ind = 0; % index of column (condition) to take peak and normalize 
                      % all traces within ROI, or set to -1 to normalize
                      % all trials to peak
in.align_to = 'none'; % 'none','max', or 'min'                      
in.colors = lines(length(experiment_output.conditions));                       
in.mode = 1; % 1 - plot traces from conditions on same axes
             % 2 - plot traces from same condition on same axes
in.indicator_dir = 1; % 1 - positive going, -1 - negative going             
in = sl.in.processVarargin(in,varargin);

func_field = [plot_func '_all'];
mean_func_field = ['mean_' plot_func '_all'];

F = experiment_output.(func_field);
if isfield(experiment_output,mean_func_field)
    meanF = experiment_output.(mean_func_field); % mean across trials within condition/ROI
    meanF = cellfun(@(x) mean(x,3),meanF,'UniformOutput',0); 
else
%     meanF = cellfun(@(x) mean(x,[2 4]),F,'UniformOutput',0); % mean across trials within condition/ROI
    meanF = cellfun(@(x) squeeze(mean(x,[2 4 5])),F,'UniformOutput',0); % mean across trials within condition/ROI
end  
meanF = cellfun(@(x) x*in.indicator_dir,meanF,'UniformOutput',0); % flip if negative going
exp_settings = experiment_output.exp_settings(1);
%% Pad ending of shorter traces with nans
num_frames = cellfun(@(x) size(x,1),meanF,'UniformOutput',1);
if any(num_frames ~= num_frames(1))
    max_frames = max(num_frames); 
    for i = 1:length(meanF)
        if num_frames(i) ~= max_frames
            meanF{i} = [meanF{i};nan([max_frames-num_frames(i),size(meanF{i},2:ndims(meanF{i}))])];
        end
    end
end
%% extract relevant columns (conditions)
if ~isempty(in.cond_inds)
    meanF = meanF(in.cond_inds);
    experiment_output.conditions = experiment_output.conditions(in.cond_inds);    
    in.colors = in.colors(in.cond_inds,:);
end
if isempty(in.fig_name)
    in.fig_name = [plot_func,'_' num2str(length(experiment_output.conditions)),'conds'];
end
%% Normalize traces
if regexp(plot_func,'aligned')
    stim_wind_inds = (exp_settings.baseline_wind + 1):size(meanF{1},1);
else
    stim_wind_inds = exp_settings.stim_vals(1):size(meanF{1},1);
end
if in.norm_peak_ind > 0   
    meanF = cellfun(@(x) x./max(meanF{1}(stim_wind_inds,:),[],1),meanF,'UniformOutput',0); 
    fprintf('Normalized all responses to peak of %s\n',...
            experiment_output.conditions{in.norm_peak_ind});
    in.fig_name = [in.fig_name '_norm' num2str(in.norm_peak_ind)]; 
elseif in.norm_peak_ind == -1
    meanF = cellfun(@(x) x./max(x(stim_wind_inds,:),[],1),meanF,'UniformOutput',0); 
    fprintf('Normalized all responses to peak\n');
    in.fig_name = [in.fig_name '_norm-1']; 
end
%% Shift time vector/s
t = exp_settings.getTimeVector(size(F{1},1));
if strcmp(in.align_to,'none') % align to stimulus, not characteristics of responses 
    if regexp(plot_func,'aligned')
        t = t - t(exp_settings.baseline_wind+1); % align to stim
    else
        t = t - t(exp_settings.stim_vals(1)); % align to first stim
    end
else % align to some aspect of response waveforms
    t_all = cell(1,size(meanF,2));
%     t_all = zeros(length(t),size(meanF,2));
    if strcmp(in.align_to,'max')       
       for i = 1:size(meanF,2)           
            [~,max_inds]  = max(meanF{i}(stim_wind_inds,:),[],1); % use 1st stim
            t_all{i} = zeros(length(t),size(meanF{i},2));
            for j = 1:size(meanF{i},2)
                t_all{i}(:,j) = t - t(stim_wind_inds(max_inds(j))); % set t = 0 to max
            end            
       end
    elseif strcmp(in.align_to,'min')
        for i = 1:size(meanF,2)           
            [~,min_inds]  = min(meanF{i}(stim_wind_inds,:),[],1); % use 1st stim
            t_all{i} = zeros(length(t),size(meanF{i},2));
            for j = 1:size(meanF{i},2)
                t_all{i}(:,j) = t - t(stim_wind_inds(min_inds(j))); % set t = 0 to max
            end            
       end
    end
    t = t_all; % num_time_points x num_conds array instread of single vector
end
%% Plot
plotTracesOverlaidGrid(t,meanF,[],'x_lim',in.x_lim,...
                      'y_lim',in.y_lim,'x_sbar_len1',in.x_sbar_len1,...
                      'save_fig',in.save_fig,'fig_dir',in.fig_dir,...
                      'fig_name',in.fig_name,'plot_func',plot_func,...
                      'leg_labels',experiment_output.conditions,...
                      'fig_units',in.fig_units,'fig_size',in.fig_size,...
                      'colors',in.colors,'mode',in.mode,'indicator_dir',in.indicator_dir);