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
    in.fig_size = [19.8 9.1]; 
else
    in.fig_size = [50 25];
end
in.fig_dir = './';
in.fig_name = [plot_func,'_' num2str(length(experiment_output.conditions)),'conds'];
in.x_lim = [];  % main axis limits
in.y_lim = []; 
in.x_sbar_len1 = []; % main axis scale bar length
in.save_fig = 0;
in.cond_inds = []; % condition indices, default use all
in = sl.in.processVarargin(in,varargin);

func_field = [plot_func '_all'];
mean_func_field = ['mean_' plot_func '_all'];

F = experiment_output.(func_field);
if isfield(experiment_output,mean_func_field)
    meanF = experiment_output.(mean_func_field); % mean across trials within condition/ROI
else
    meanF = cellfun(@(x) mean(x,2),F,'UniformOutput',0); % mean across trials within condition/ROI
end    
exp_settings = experiment_output.exp_settings;
t = exp_settings.getTimeVector(size(F{1},1));
if regexp(plot_func,'aligned')
    t = t - t(exp_settings.baseline_wind+1); % align to stim
else
    t = t - t(exp_settings.stim_vals(1)); % align to first stim
end
if ~isempty(in.cond_inds)
    meanF = meanF(in.cond_inds);
    experiment_output.conditions = experiment_output.conditions(in.cond_inds);
    in.fig_name = [plot_func,'_' num2str(length(experiment_output.conditions)),'conds'];
end
plotTracesOverlaidGrid(t,meanF,[],'x_lim',in.x_lim,...
                      'y_lim',in.y_lim,'x_sbar_len1',in.x_sbar_len1,...
                      'save_fig',in.save_fig,'fig_dir',in.fig_dir,...
                      'fig_name',in.fig_name,'plot_func',plot_func,...
                      'leg_labels',experiment_output.conditions,...
                      'fig_units',in.fig_units,'fig_size',in.fig_size);