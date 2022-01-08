function trials_data = plotTrials(img_names,exp_settings,roi_set_filename,...
                                  varargin)
%PLOTTRIALS Plot set of trials on same axis  
%TODO: make arrays compatible with roi_func_mode 'separate'
in.data_fold = pwd;
in.exp_date = ''; % use for default experiment file structure:
                  % <data_fold>/<exp_date>/<reporter>/<dish>/<condition>
in.reporter = '';
in.dish = '';
in.div = [];
in.condition = '';
in.position = '';
in.filedir = ''; % if not empty, this folder is used instead of default 
                 % structure above
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
in.show_roi_labels = 0; 
in.pixel_size = 0.4; % um (pixel size on Thor camera with 40x objective)
in.bin_size = 1; % 1x1 binning
in = sl.in.processVarargin(in,varargin); 
%% Get file names within condition if not input
if isempty(img_names) % assume all .fits files are relevant trial data
    if isempty(in.filedir) % construct default experiment file path to this condition
        filedir = fullfile(in.data_fold,in.exp_date,in.reporter,in.dish,in.condition);            
        img_names = getImagesWithinDir(filedir); 
    else % use input path to find all trials for this condition
        filedir = in.filedir; 
        img_names = getImagesWithinDir(filedir); 
        % append full path
        img_names = fullfile(filedir,img_names); 
    end    
end
if ischar(img_names)
   img_names = {img_names};  
end
num_trials = length(img_names); 
trace_fig = figure; 
if strcmp(in.roi_func_mode,'combine')
    trace_axis = gca; 
elseif strcmp(in.roi_func_mode,'separate') 
    if num_trials > 1
        traces_axes = cell(num_trials,1); 
        for i = 1:num_trials
            traces_axes{i} = subplot(1,num_trials,i);         
        end
    else
        trace_axis = gca;
    end
end
func_outputs = cell(1,num_trials); 
deltaF_F0 = cell(1,num_trials); 
trial_times = NaT(1,num_trials); 
bslines = cell(1,num_trials); 
means = cell(1,num_trials); 
rois_all = cell(1,num_trials); 
% Format roi_set_filename
if iscell(roi_set_filename) && length(roi_set_filename) == 1
    roi_set_filename = roi_set_filename{1};
end
if ischar(roi_set_filename) || ~iscell(roi_set_filename)
    roi_set_filename = repmat({roi_set_filename},1,num_trials);
    % roi_set_filename should be cell array of length num_trials
end
if ~strcmp(in.transform_type,'none') && ~isempty(in.registration_rec)
    if ischar(in.registration_rec)    
        if exist(in.registration_rec,'file')
            in.registration_rec = Recording(in.registration_rec);  % pre-load once
        else
            error('''%s'' input for registration_rec does not exist',in.registration_rec);  
        end
    end
end
for i = 1:num_trials
    if  strcmp(in.roi_func_mode,'separate') && num_trials > 1
        trace_axis = traces_axes{i}; 
    end
    img_namei = img_names{i}; 
    datai = plotTrial(img_namei,exp_settings,roi_set_filename{i},...
                   trace_axis,in);
    func_outputs{i} = datai.func_output; 
    deltaF_F0{i} = datai.func_output.deltaF_F0;
    trial_times(i) = datai.recording.time_start; 
    bslines{i} = datai.func_output.baseline;    
    rois_all{i} = datai.rois;
    if any(strcmp('mean',in.funcs))
       means{i} = datai.func_output.mean; 
    end
end
if strcmp(in.roi_func_mode,'combine')
    deltaF_F0 = cell2mat(deltaF_F0); 
    bslines = cell2mat(bslines); 
    if any(strcmp('mean',in.funcs))
        means = cell2mat(means); 
    end
    peaks_deltaF_F0 = max(deltaF_F0,[],1); % peaks within trial
    mean_peak_deltaF_F0 = mean(peaks_deltaF_F0);
    std_peak_deltaF_F0 = std(peaks_deltaF_F0,0);
    fprintf('%s: Peak deltaF_F0 across trials (mean +/- std) = %.3f +/- %.3f\n',...
             in.condition, mean_peak_deltaF_F0,std_peak_deltaF_F0); 
    fprintf('  Mean baseline (%g frames) across trials = %.3f +/- %.3f\n',...
            exp_settings.baseline_wind,mean(bslines(1,:)),std(bslines(1,:),0));
elseif strcmp(in.roi_func_mode,'separate')
    bslines = cell2mat(bslines'); % [num_trials x num_rois] 
    peaks_deltaF_F0 = cell2mat(cellfun(@(x) max(x,[],1),deltaF_F0,'UniformOutput',0)'); % [num_trials x num_rois]
    mean_peak_deltaF_F0 = mean(peaks_deltaF_F0,1); % mean across trials, within roi
    std_peak_deltaF_F0 = std(peaks_deltaF_F0,0,1); % mean across trials, within roi
    fprintf('%s: Peak deltaF_F0 across trials and ROIs (mean +/- std) = %.3f +/- %.3f\n',...
             in.condition, mean(mean_peak_deltaF_F0),mean(std_peak_deltaF_F0)); 
    fprintf('  Mean baseline (%g frames) across trials and ROIs = %.3f +/- %.3f\n',...
            exp_settings.baseline_wind,mean(bslines,'all'),std(bslines,0,'all'));
end
trials_data = struct(); 
trials_data.deltaF_F0 = deltaF_F0;
if any(strcmp('mean',in.funcs))
    trials_data.means = means; 
end
trials_data.peaks_deltaF_F0 = peaks_deltaF_F0;
trials_data.mean_peak_deltaF_F0 = mean_peak_deltaF_F0;
trials_data.std_peak_deltaF_F0 = std_peak_deltaF_F0;
trials_data.trial_times = trial_times; 
trials_data.bslines = bslines;
trials_data.rois_all = rois_all; 
trials_data.img_names = img_names; 
if in.save_fig
    if isfield(datai,'fig_dir') && isempty(in.data_fold)
        fig_dir = datai.fig_dir;
    else
        roiset_filename_no_ext = getROIset_name(roi_set_filename{1},...
                                            in.transform_type,...
                                            in.registration_rec);  
        fig_dir = fullfile(in.data_fold,in.exp_date,in.reporter,in.dish,...
                            in.condition,['figs_',roiset_filename_no_ext]);
    end
    fig_name = sprintf('%s_%s_%s_%gtrials',in.condition,in.plot_func,in.roi_func_mode(1:3),num_trials);
    printFig(trace_fig,fig_dir,fig_name);
end
end