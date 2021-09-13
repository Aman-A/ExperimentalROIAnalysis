%% Script to plot multiple trials in same condition 
data_fold = '/Volumes/BACKUPDRIVE/Dartmouth_data';
exp_date= '20210911'; 
reporter = 'GluSnFr3';
dish = 'dish4'; 
condition = '5nM_DTX'; % 'control', '5nM_DTX', '50nM_DTX'
position = 'Pos1'; 
img_names = {}; % use all images in condition folder
% img_names = {'DTX5.fits','DTX5_1.fits'}; % or specify in cell array
stim_vals = 3; % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 1; % window
baseline_wind = 1; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 100; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
roi_set_filename = 'RoiSet_pos1.zip'; 
% Optional settings
show_diff_image = []; % can include [1,2,3]
filt_width = 0; 
funcs = {'mean','std','baseline','deltaF_F0'}; 
roi_func_mode = 'combine';
save_processed_data = 1;
load_processed_data = 1;
[deltaF_F0,peaks_deltaF_F0,mean_peak_deltaF_F0,std_peak_deltaF_F0] = ...
    plotTrials(data_fold,exp_date,reporter,dish,condition,position,img_names,...
            exp_settings,roi_set_filename,show_diff_image,filt_width,funcs,...
            roi_func_mode,save_processed_data,load_processed_data);