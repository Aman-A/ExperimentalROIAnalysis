%% Mini detection 
% Analysis settings
method = 1; % mini finding method
threshold = 4; % x std (noise level)
min_mini_width = 20e-3; % sec - min FWHM of minis
apply_high_pass_filt = 0;    
fc = 1/3; % Hz - filter cutoff
nframes_back = 10;  % number of frames behind each mini to extend window
nframes_forward = 10; 
roi_with_mini_index = 25; % index of ROI with known mini
% Path to data and ROIs
exp_folder = fullfile(getDataFold(),'../Sam_data/20210908 d5'); 
img_folder = fullfile(exp_folder,'the stack');
roi_set_name = 'RoiSet_analysis';
% Experiment/imaging settings
sampling_rate = 100; % 
stim_vals = 100; 
stim_wind = 10; 
baseline_wind = 10; 
units = 'frames';
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,units,sampling_rate); 
%% Load recording
img_names = getImagesWithinDir(img_folder); 
img_name = img_names{3}; 
rec = Recording(fullfile(img_folder,img_name));  
rec.load(); 
rois = ROIs(fullfile(exp_folder,roi_set_name)); 
rois.invert_y(rec.imsize); 
%% Extract traces in ROIs
func_output = calcROIfuncs(rec,rois,{'mean','deltaF_F0'},exp_settings.baseline_wind_inds,...
                            'separate');
deltaF_F0 = func_output.deltaF_F0;    
means = func_output.mean;
%% High pass filter to remove photobleaching transient
if apply_high_pass_filt
    filt_order = 3; 
    [b,a] = butter(filt_order,fc/(exp_settings.sampling_rate/2),'high');
    deltaF_F0 = filtfilt(b,a,deltaF_F0); 
    means = filtfilt(b,a,means); 
    fprintf('Applied %g order high pass filter with %g Hz cutoff\n',filt_order,fc); 
else
    fprintf('Skipped filtering step\n'); 
end
%% Plot traces in all
fig = figure('Units','inches','Position',[0.4479    1.3021   19.0625    8.9583]); 
ax = gca;
plotROIfunc(func_output,'deltaF_F0',exp_settings.stim_vals,...
            exp_settings.sampling_rate,'ax',ax,...
            'show_legend',0);
%% 
settings.sampling_rate = exp_settings.sampling_rate;
settings.nframes_back = nframes_back;
settings.nframes_forward = nframes_forward; 
settings.stim_frame = exp_settings.stim_vals;
settings.blank_around_stim = exp_settings.stim_wind; 
settings.threshold = threshold;
settings.roi_with_mini_index = roi_with_mini_index; 
settings.min_mini_width = min_mini_width;
mini_times = detect_minis(means,settings,method); 

