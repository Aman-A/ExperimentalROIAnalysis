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
in.roi_func_fig_size = [19.8 9.1];
in.roi_func_fig_units = 'centimeters';
in.save_fig = 0; 
in.close_img_after_save = 0; 
in = sl.in.processVarargin(in,varargin); 
%% Get file names within condition if not input
filedir = fullfile(data_fold,exp_date,reporter,dish,condition);            
if isempty(img_names) % assume all .fits files are relevant trial data
    d = dir(filedir); 
    file_names = {d.name};
    creation_time = [d.datenum];
    [~,inds] = sort(creation_time,'ascend');
    file_names = file_names(inds);
    [~,~,file_exts] = cellfun(@(x) fileparts(x),file_names,'UniformOutput',0);
    is_fits = cellfun(@(x) strcmp(x,'.fits'),file_exts,'UniformOutput',1);
    is_not_hidden = cellfun(@(x) ~strcmp(x(1),'.'),file_names,'UniformOutput',1);
    img_names = file_names(is_fits & is_not_hidden);
    % returns names sorted by time of creation
end
num_trials = length(img_names); 
trace_fig = figure; 
trace_axis = gca; 
func_outputs = cell(1,num_trials); 
deltaF_F0 = cell(1,num_trials); 
trial_times = NaT(1,num_trials); 
bslines = zeros(1,num_trials); 
for i = 1:num_trials
    img_namei = img_names{i}; 
    datai = plotTrial(data_fold,exp_date,reporter,dish,condition,position,...
                   img_namei,exp_settings,roi_set_filename,...
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
   [~,roi_set_filename_no_ext] = fileparts(roi_set_filename);    
   fig_dir = fullfile(data_fold,exp_date,reporter,dish,condition,...
                    ['figs_',roi_set_filename_no_ext]);       
   fig_name = sprintf('%s_%s_%gtrials',condition,in.plot_func,num_trials);
   printFig(trace_fig,fig_dir,fig_name); 
end
end