function [F_traces_norm,ss_dFF0,nh4cl_trace] = analyzeNH4ClNormTrial(img_name,...
                                                exp_settings,roiset_filename,...
                                                plot_settings,mean_wind,F_traces,...
                                                varargin)
%ANALYZENH4CLNORMTRIAL ... 
%  
%   Inputs 
%   ------ 
%   img_name : string
%              Name of glutamate normalization recording trial
%   exp_settings : ExperimentSettings object
%                  Specify start time of glutamate response and baseline
%                  window to use for deltaF/F calculation
%   roi_set_filename : string
%                      Name of RoiSet file 
%   plotTrial_settings : struct
%                        Struct matching output of plotTrialSettings
%                        function, plotting options for plotTrials
%   mean_wind : 1 x N vector
%               indices within which to calculate mean glutamate response
%   F_traces : num_frames x num_traces array
%              Can be either deltaF/F0 or deltaF depending on setting of
%              in.norm_func
%   Optional Inputs 
%   --------------- 
%   check_settings : 1 or 0
%                   If set to 1, runs interactive step for selecting start,
%                   baseline window, and end points for computing mean
%                   glutamate response 
%   Outputs 
%   ------- 
%   norm_output : struct
%                 Experiment data (output by plotTrials_multipleConditions)
%                 normalized using experimental responses normalized to
%                 glutamate response (ss_dFF0)
%   ss_dFF0 : 1 x num_rois vector
%             Mean deltaF/F0 values within mean_wind frames of glutamate
%             response within each ROI
%   exp_settings : ExperimentSettings object
%                  Updated ExperimentSettings, if modified (check_settings
%                  = 1)
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.norm_func = 'deltaF'; % deltaF or deltaF_F0
in.check_settings = 1; 
in.save_data = 1;
in.scaling_factor = 1; % mM - default 5 mM, otherwise set externally
in = sl.in.processVarargin(in,varargin);
getting_traces = 1; 
check_settings = in.check_settings;
plot_settings.funcs = {'mean','baseline','deltaF','deltaF_F0'}; % calculate all functions just in case
plot_settings.plot_func = in.norm_func;
plot_settings.roi_func_mode = 'combine'; % make sure set to separate
plot_settings.roi_func_sbar_len = 4; 

while getting_traces
    trace_fig = figure; 
    trace_axis = gca;
    datai = plotTrial(img_name,exp_settings,roiset_filename,...
                       trace_axis,plot_settings);
    if check_settings % allow user to modify settings 
        if strcmp(plot_settings.plot_func,'none') || ...
                isempty(plot_settings.plot_func) || ...
                all(plot_settings.plot_func==0) 
            % Plot wasn't generated so generate first
            t = exp_settings.getTimeVector(datai.recording.imsize(3));
            plot(trace_axis,t,datai.func_output.(in.norm_func))        
        else
            display_names = {trace_axis.Children.DisplayName};
            t = trace_axis.Children(1).XData;            
            t0 = t-t(1); % set first time point to 0
        end
        % Get stim start
        figure(trace_fig); 
        trace_fig.Units = 'normalized'; trace_fig.Position = [0.05 0.05 0.9 0.9];        
        title('Select time point of NH4Cl response start and hit Enter','FontSize',14);
        [x_start,~] = ginput();     
        x_start = x_start(end); % take last selected point
        [~,stim_frame] = min(abs(x_start-t));
        stim_time = t0(stim_frame);
        % Get stim window end
        figure(trace_fig);         
        title('Select time point to end stimulus window and hit Enter','FontSize',14);
        [x_end,~] = ginput();     
        x_end = x_end(end); % take last selected point
        [~,stim_end_frame] = min(abs(x_end-t));
        stim_wind = t0(stim_end_frame) - stim_time;
        % Get baseline window 
        figure(trace_fig); 
        title('Select time point to start baseline and hit Enter','FontSize',14);
        [x_bsline,~] = ginput();     
        [~,bsline_frame] = min(abs(x_bsline-t));        
        bsline_wind = stim_time - t0(bsline_frame);
        exp_settings = ExperimentSettings(stim_time,stim_wind,bsline_wind,'sec',...
                                          exp_settings.sampling_rate);
        plot_settings.load_processed_data = 0; % rerun analysis
        fprintf('New experiment settings for this trial:\n')
        disp(exp_settings)
        check_settings = 0; % rerun loop and skip this step
        close(trace_fig)
    else
        break % don't loop, proceed with input settings
    end
end
% get mean value during steady state phase of glutamate response
nh4cl_trace = datai.func_output.(in.norm_func);
if isempty(mean_wind)
    mean_wind = exp_settings.stim_wind_inds(:,1);
    fprintf('Using mean_wind from frame %g to %g\n',mean_wind(1),mean_wind(end));
end
if in.scaling_factor ~= 1    
    nh4cl_trace = nh4cl_trace*in.scaling_factor;
    fprintf('Scaling factor of %g applied\n',in.scaling_factor);
else
    fprintf('No scaling factor applied\n')
end
ss_dFF0 = mean(nh4cl_trace(mean_wind,:),1);
F_traces_norm = F_traces/ss_dFF0; 
end
