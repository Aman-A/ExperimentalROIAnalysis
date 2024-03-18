%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
% data_fold = fullfile(getDataFold('aman_sora'),'DC_mod_experiments'); 
data_fold = fullfile(getDataFold('aman_sora'),'DC_mod_experiments'); 
exp_date = '240317';
reporter = 'Ace2NmNeonGreen_SynmRuby';
dish = 'dish3';
div = 19;

%pos1
roiset_filename = [1240 1308 657 725];
% pos4
% roiset_filename = [761 1258 778 1275]; % [min row max row min col max col]
% roiset_filename = 'RoiSet_test2.zip';

sampling_rate = 20; % sampling rate of camera (frames/sec) - exp time 0.0004815
num_stim = 20; % number desired APs 20 or 100
stim_pulse_dur = 0.5; % pulse duration (sec)
stim_freq = 1; % Hz
stim_delay = 0; % sec % 3 or 5 sec delay
% stim_delay = 0.2; 
stim_duration = (num_stim+1)/stim_freq;
stim_vals = defineStimTrain(stim_delay,stim_freq,stim_duration); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.7; % window
baseline_wind = 0.3; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate,'stim_pulse_dur',...
                                  stim_pulse_dur); % automatically converts to frames
total_time = stim_vals(end) + stim_wind;
num_frames = ceil(total_time*sampling_rate);
fprintf('Set stim delay to %g sec, duration to %g sec, interval to %g sec\n',...
        stim_delay,stim_duration,1/stim_freq); 
fprintf('F = %.1f Hz, record for %g frames (%.2f sec)\n',...
        sampling_rate, num_frames,total_time); 
% Optional settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
% ps.condition = condition;
ps.show_diff_image = [4]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate';
ps.save_processed_data = 1;
ps.load_processed_data = 0;
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0_aligned'; % 'deltaF_F0' 'deltaF_F0_aligned'
% ps.plot_func = 'deltaF_F0'; % 'deltaF_F0' 'deltaF_F0_aligned'
if strcmp(ps.plot_func,'deltaF_F0')
   ps.x_lim = [stim_delay stim_delay+stim_duration];
   ps.y_lim = [];
else
    ps.x_lim = [-baseline_wind,stim_wind];
    ps.y_lim = [];
end
ps.recenterROIs = 0;
ps.show_roi_labels = 1;
ps.close_img_after_save = 0; 
% ps.bin_size = 2;
ps.offset_factor = 0.04; 
ps.peak_mode = exp_settings.convert2Frames([0.15 0.5]);
% ps.peak_mode = 'min';
ps.diff_image_cmap = 'bluewhitered';
ps.filt_width = 2; 
ps.rem_pbleach = 1;
ps.motion_correct = 0; 
ps.overlay_trials = 0; 
ps.indicator_dir = 1;
ps.roi_func_sbar_len = 0.01; 
ps.offset_factor = 0.01; 
ps.analysis_funcs = {'peaks','peak_times'};
ps.roi_func_fig_units = 'inches'; 
ps.roi_func_fig_size = [9.8 6.33]; 
% makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),{'pol_1Hz_500ms_1mAG'},exp_settings,'img_stack_name','diffimagesV','indicator_dir',-1,'filt_width',1,'peak_mode',[15 50]);
% makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),conditions,exp_settings,'img_stack_name','diffimagesV','indicator_dir',-1,'filt_width',1,'peak_mode',[15 50]);
%%
ps.condition = 'pol_1Hz_500ms_3mAG_pos1';
img_name = [ps.condition '_002.nd2'];
% ps.condition = 'test_pol';
% img_name = 'trial.fits';
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
datai.recording.load(); % load recording for processing here
%% Make stim-averaged movie from recording
mean_mov = meanMovie(datai.recording.vals,exp_settings.stim_vals,...
                    exp_settings.baseline_wind,exp_settings.stim_wind);
% Spatial and temporal filter on mean movie
exp_settings.convert2Frames(); 
stim_frame = exp_settings.baseline_wind + 1; 
mean_mov_filt1 = spatialFilter(mean_mov,4,2);% 8x8 filter, sigma = 4
mean_mov_filt2 = pcafilt(mean_mov_filt1,3); % take top 3 principle components

mov_bsline = mean(mean_mov_filt2(:,:,1:(stim_frame-1)),3);
mean_delta_mov = mean_mov_filt2 - mov_bsline;
mean_dF_F_mov = mean_delta_mov./mov_bsline;
% PCA filter to remove temporal noise
% [mean_mov_filt, eigvecs, eigvals] = pcafilt(mean_mov, 3);  
% [mean_delta_mov_filt, eigvecs, eigvals] = pcafilt(mean_delta_mov, 3); 

std_mov = std(mean_dF_F_mov,0,3);
ax_lims = [400, size(mean_mov,2),300, 1900];
%% Plot std image
% mask = std_mov > 0.2;
mask = mov_bsline > 105; 
std_img = std_mov; 
std_img(~mask) = nan;
fig = figure('Units','inches'); 
fig.Position(3:4) = [12 12];
s = surf(std_img,'EdgeColor','none');
ax = gca;
ax.View = [0 90];
axis(ax,'equal','tight','off');
axis(ax_lims);
hold on;
addScaleBar(datai.recording.pixel_size,datai.recording.imsize,ax,'sbar_len',100,...
            'x_factor',0.8,'y_factor',0.2,'color','k','text_y_factor',1.02);
std_img_name = sprintf('%s_std_img',datai.recording.img_name);
% printFig(fig,fullfile(data_fold,exp_date,reporter,dish,ps.condition),std_img_name);
%% Plot mean dF image
% mask
% use pregenerated diff img
% mean_diff_img_mask = datai.imgs.mean_diff_img;
% mean_diff_img_mask(~mask) = nan;
% cax_lims = [-3.5 2.5];
% use masked filtered movie
% mean_delta_mov_filt1 = spatialFilter(mean_dF_F_mov,8,4);
% [mean_delta_mov_filt2,eigvecs,eigvals] = pcafilt(mean_delta_mov_filt1,5);
mean_delta_mov_filt_img = mean(mean_dF_F_mov(:,:,stim_frame+ps.peak_mode(1):stim_frame+ps.peak_mode(2)),3);
mean_delta_mov_filt_img(~mask) = nan;

% cax_lims = [-15 14];
cax_lims = [-1.9 1.5];

fig = figure('Units','inches'); 
fig.Position(3:4) = [12 12];
s = surf(mean_delta_mov_filt_img*100,'EdgeColor','none');
ax = gca;
ax.View = [0 90];
axis(ax,'equal','tight','off');
axis(ax_lims);
clim(ax,cax_lims);
colormap(bluewhitered(1000));
colorbar; 
hold on;
addScaleBar(datai.recording.pixel_size,datai.recording.imsize,ax,'sbar_len',100,...
            'x_factor',0.8,'y_factor',0.2,'color','k','text_y_factor',1.02);
diff_img_name = sprintf('%s_dF_F_filt',datai.recording.img_name);
printFig(fig,fullfile(data_fold,exp_date,reporter,dish,ps.condition),diff_img_name);
%% Save stim-averaged movie 
plot_mov = mean_delta_mov_filt; 
exp_settings.convert2Time();
ms = struct(); % movie settings
ms.start_frame = 1; 
ms.end_frame = size(mean_mov,3);
ms.movie_slow_down_factor = 0.25; 
ms.stim_vals1 = exp_settings.baseline_wind + 1/sampling_rate;
ms.stim_pulse_dur1 = exp_settings.stim_pulse_dur;
% ms.ROI = [1, size(mean_mov,1),1, size(mean_mov,2)]; % [lower y, upper y, left x, right x]
ms.ROI = [300, 1900,400, size(mean_mov,2)]; % [lower y, upper y, left x, right x]
% ms.colormap = 'inferno';
ms.colormap = 'bluewhitered';
ms.cax_lims = [-5.8 3.2]; 
ms.fig_size = [16 12.5]; 
ms.filt_size = 8; % size of sptial filter
ms.filt_sigma = 4; % std of gaussian spatial filter
ms.t_rel_stim = 1; 
ms.pixel_size = datai.recording.pixel_size; 
ms.sbar_len = 100; 
ms.sbar_color = 'k';
ms.time_color = 'k';
ms.video_profile = 'MPEG-4';
ms.mask = mask; 
ms.plot_mode = 'surf';
mov_name = sprintf('%s_dF_f%g-%g_%gx',img_name,ms.start_frame,ms.end_frame,ms.movie_slow_down_factor);
mov_file = fullfile(data_fold,exp_date,reporter,dish,ps.condition,mov_name);

makeMovie(plot_mov,sampling_rate,mov_file,ms);