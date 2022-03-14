function [norm_output,ss_dFF0,exp_settings] = analyzeGlutNormTrial(img_name,...
                                                exp_settings,roi_set_filename,...
                                                plot_settings,mean_wind,exp_output,...
                                                varargin)
%ANALYZEGLUTNORM ... 
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
%   exp_output : struct
%                data from full experiment, output by
%                plotTrials_multipleConditions. Mean response to glutamate
%                within ROIs are used to normalize experiment data
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
in.check_settings = 1; 
in.save_data = 1;
in.glut_concentration = 5; % mM - default 5 mM, otherwise set externally
in = sl.in.processVarargin(in,varargin);
getting_traces = 1; 
check_settings = in.check_settings;
plot_settings.plot_func = 'deltaF_F0';
plot_settings.roi_func_mode = 'separate'; % make sure set to separate
plot_settings.roi_func_sbar_len = 4; 

while getting_traces
    trace_fig = figure; 
    trace_axis = gca;
    datai = plotTrial(img_name,exp_settings,roi_set_filename,...
                       trace_axis,plot_settings);
    if check_settings % allow user to modify settings 
        if strcmp(plot_settings.plot_func,'none') || ...
                isempty(plot_settings.plot_func) || ...
                all(plot_settings.plot_func==0) 
            % Plot wasn't generated so generate first
            t = exp_settings.getTimeVector(datai.recording.imsize(3));
            plot(trace_axis,t,datai.func_output.deltaF_F0)        
        else
            display_names = {trace_axis.Children.DisplayName};
            t = trace_axis.Children(strcmp(display_names,datai.rois.names{1})).XData;            
            t0 = t-t(1); % set first time point to 0
        end
        % Get stim start
        figure(trace_fig); 
        trace_fig.Units = 'normalized'; trace_fig.Position = [0.05 0.05 0.9 0.9];        
        title('Select time point of glutamate response start and hit Enter','FontSize',14);
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
deltaF_F0 = datai.func_output.deltaF_F0;
if isempty(mean_wind)
    mean_wind = exp_settings.stim_wind_inds(:,1);
    fprintf('Using mean_wind from frame %g to %g\n',mean_wind(1),mean_wind(end));
end
ss_dFF0 = mean(deltaF_F0(mean_wind,:),1);
%% Normalize data from experiment in exp_output
if nargin > 5 && ~isempty(exp_output)
    assert(strcmp(exp_output.plot_settings.roi_func_mode,plot_settings.roi_func_mode),...
       'Need to use roi_func_mode = ''separate''')
    
    norm_output = exp_output;
    data_to_norm = {'deltaF_F0_all','mean_deltaF_F0_all','peaks_deltaF_F0_all',...
                    'deltaF_F0_aligned_all','mean_deltaF_F0_aligned_all',...
                    'poststim_ints_all'
                    };
    for i = 1:length(data_to_norm)
        fieldi = data_to_norm{i};
        if isfield(norm_output,fieldi)
            norm_output.(fieldi) = cellfun(@(x) x./ss_dFF0,exp_output.(fieldi),...
                                        'UniformOutput',0);
        end
    end
    norm_output.mean_peaks = cellfun(@(x) mean(x,'all'),...
                                    norm_output.peaks_deltaF_F0_all,...
                                    'UniformOutput',0);
    norm_output.std_peaks = cellfun(@(x) std(x,0,'all'),...
                                    norm_output.peaks_deltaF_F0_all,...
                                    'UniformOutput',0);
    norm_output.sem_peaks = cellfun(@(x) std(x,0,'all')/numel(x),...
                                    norm_output.peaks_deltaF_F0_all,...
                                    'UniformOutput',0);
    norm_output.glut_img_name = datai.recording.img_name;
    norm_output.glut_concentration = in.glut_concentration;
    norm_output.glut_ss_deltaF_F0 = ss_dFF0; 
    % WARNING: decay_fits coefficients apply to unnormalized values, not to
    % normalized values
    if in.save_data
        data_fold = plot_settings.data_fold;
        exp_date = plot_settings.exp_date; 
        reporter = plot_settings.reporter; 
        dish = plot_settings.dish; 
        roiset_filename_no_ext = getROIset_name(roi_set_filename,...
                                                 plot_settings.transform_type,...
                                                    plot_settings.registration_rec);  
        norm_datafile = sprintf('%s_%s_%s_%s_%s_glutnorm',exp_date,reporter,dish,plot_settings.roi_func_mode,...
                                roiset_filename_no_ext);
        norm_data_filepath = fullfile(data_fold,exp_date,reporter,dish,norm_datafile);
        save(norm_data_filepath,'-STRUCT','norm_output');
        fprintf('Saved normalized summary data to %s\n',norm_data_filepath);
    end
else
    norm_output = []; 
end
end
