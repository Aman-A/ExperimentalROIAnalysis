function [deltaF_F0,peaks_deltaF_F0,mean_peak_deltaF_F0,std_peak_deltaF_F0,trial_times,bslines] = ...
                plotTrials(data_fold,exp_date,reporter,dish,condition,position,...
                   img_names,exp_settings,roi_set_filename,...
                   varargin)
%PLOTTRIALS Plot set of trials on same axis  
%TODO: make arrays compatible with roi_func_mode 'separate'
in.show_diff_image = []; 
in.filt_width = 0; % gaussian filter width, used on peak deltaF to refine 
               % ROI positions

in.funcs = {'mean','std','baseline','deltaF_F0'}; % functions to compute
in.plot_func = 'deltaF_F0';
in.roi_func_mode = 'combine';
in.save_processed_data = 1;
in.load_processed_data = 0; 
in.y_lim = [-0.2 1.2];
in.x_lim = []; 
in.recenterROIs = 'diff'; 
in.roiset_filedir = []; % default set below (one directory above img directory)
in.roi_func_fig_size = [19.8 9.1];
in.roi_func_fig_units = 'centimeters';
in.transform_type = 'none'; % 'displace','translation','rigid','similarity','affine' - Image coregistration
in.registration_rec = ''; % full path to Recording to register for shifting ROIs or Recording object
in.save_fig = 0; 
in.close_img_after_save = 0; 
in = sl.in.processVarargin(in,varargin); 
%% Get file names within condition if not input
filedir = fullfile(data_fold,exp_date,reporter,dish,condition);            
if isempty(img_names) % assume all .fits files are relevant trial data
    img_names = getImagesWithinDir(filedir); 
end
num_trials = length(img_names); 
trace_fig = figure; 
trace_axis = gca; 
func_outputs = cell(1,num_trials); 
deltaF_F0 = cell(1,num_trials); 
trial_times = NaT(1,num_trials); 
bslines = zeros(1,num_trials); 
% Format roi_set_filename
if iscell(roi_set_filename) && length(roi_set_filename) == 1
    roi_set_filename = roi_set_filename{1};
end
if ischar(roi_set_filename) || ~iscell(roi_set_filename)
    roi_set_filename = repmat({roi_set_filename},1,num_trials);
    % roi_set_filename should be cell array of length num_trials
end
if ~isempty(in.registration_rec) && ischar(in.registration_rec)
    if exist(in.registration_rec,'file')
        in.registration_rec = Recording(in.registration_rec);  % pre-load once
    else
        error('''%s'' input for registration_rec does not exist',in.registration_rec);  
    end
end
for i = 1:num_trials
    img_namei = img_names{i}; 
    datai = plotTrial(data_fold,exp_date,reporter,dish,condition,position,...
                   img_namei,exp_settings,roi_set_filename{i},...
                   trace_axis,in);
    func_outputs{i} = datai.func_output; 
    deltaF_F0{i} = datai.func_output.deltaF_F0;
    trial_times(i) = datai.recording.time_start; 
    bslines(i) = datai.func_output.baseline;
end
deltaF_F0 = cell2mat(deltaF_F0); 
peaks_deltaF_F0 = max(deltaF_F0,[],1); % peaks within trial
mean_peak_deltaF_F0 = mean(peaks_deltaF_F0);
std_peak_deltaF_F0 = std(peaks_deltaF_F0,0);
fprintf('%s: Peak deltaF_F0 across trials (mean +/- std) = %.3f +/- %.3f\n',...
         condition, mean_peak_deltaF_F0,std_peak_deltaF_F0); 
fprintf('  Mean baseline (%g frames) across trials = %.3f +/- %.3f\n',...
        exp_settings.baseline_wind,mean(bslines),std(bslines,0));
if in.save_fig
    if isfield(datai,'fig_dir')
        fig_dir = datai.fig_dir;
    else
        fig_dir = fullfile(data_fold,exp_date,reporter,dish,condition,...
            ['figs_',roi_set_filename_no_ext]);
    end
    fig_name = sprintf('%s_%s_%gtrials',condition,in.plot_func,num_trials);
    printFig(trace_fig,fig_dir,fig_name);
end
end