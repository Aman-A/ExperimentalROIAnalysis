%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '241114';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish4';
div = 16; 

% roiset_filename = 'RoiSet_auto_diffimagesG_test.mat';
roiset_filename = 'RoiSet_auto_pos5.mat';
% roiset_filename = 'RoiSet_pc_pos0.zip';

num_stim = 1; 
del = 0.5; % sec 
freq = 1/6; % Hz
dur = num_stim/freq; 
stim_vals = defineStimTrain(del,freq,dur); 
stim_wind = 0.4; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 100; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames

% Plot settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.show_diff_image = [3]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate'; % 'combine' or 'separate'
ps.save_processed_data = 1;
ps.load_processed_data = 0;
ps.save_fig = 2;
if strcmp(ps.roi_func_mode,'combine')
    ps.y_lim = [-0.1 0.6];
else
    ps.y_lim = [];
end
% ps.x_lim = [-baseline_wind,stim_wind]; 
% ps.x_lim = [-0.75 1.25];
ps.recenterROIs = 0;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0'
ps.transform_type = 'none'; % 'none' or 'displace'
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,...
                                          'burst','control.fits'); 
ps.show_roi_labels = 1;  
ps.close_img_after_save = 0;
ps.offset_factor = 0.5; 
%makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),{'test'},exp_settings,'img_stack_name','diffimages');
%%
ps.condition = 'test'; % 'control', '50nM_DTX'
img_name = 'trial_1';
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
peaks = max(datai.func_output.deltaF_F0_aligned(exp_settings.baseline_wind:exp_settings.baseline_wind+exp_settings.stim_wind,:),[],1);
bsline_std = std(datai.func_output.deltaF_F0_aligned(1:exp_settings.baseline_wind,:),0,1);
snrs = peaks./bsline_std; 
fprintf('mean +/- std (min,max)\n')
fprintf('Peaks: %.3f +/- %.3f (%.3f, %.3f)\n',mean(peaks),std(peaks),min(peaks),max(peaks));
fprintf('SNR: %.3f +/- %.3f (%.3f, %.3f)\n',mean(snrs),std(snrs),min(snrs),max(snrs));
%% Plot multiple trials, same condition
% ps.condition = 'control_30mAB_-3mAY_2'; % 'control', '100nM_DTX'
% img_names = {}; % use all images in condition folder
% trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);