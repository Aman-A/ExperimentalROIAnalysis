%% Plot traces in subregion
% subROI = [69 156 100 153];
subROI = [69 156 100 160];
imsize = [156 512];
save_figs = 1;
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '230908';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish5';
div = 17; 
exp_fold = fullfile(data_fold,exp_date,reporter,dish);
sampling_rate = 100; % Hz
% Stimulation settings
% Bipolar stim
num_stim = 20; 
num_trains = 2; 
del = 0; % sec 
freq = 2; % Hz
dur = (1+num_stim)/freq; 
stim_vals1 = defineStimTrains(del,freq,dur,num_trains,num_stim/freq); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.4; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
exp_settings = ExperimentSettings(stim_vals1,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
% DC field stim
stim_vals2 = 10.25-stim_vals1(1); % sec 
stim_pulse_dur2 = 10; % sec
% ROIs
roiset_filename = 'RoiSet_pc_pos2.zip';
% Plot settings
% Optional settings
ps = plotTrialSettings();
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div;
ps.show_diff_image = []; % can include [1,2,3,4]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate'; % combine or separate
ps.save_processed_data = 1;
ps.load_processed_data = 1; 
ps.save_fig = 0;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0' 'deltaF_F0_aligned'
% if strcmp(ps.roi_func_mode,'combine')
%     ps.y_lim = [];
% else
%     ps.y_lim = [];
% end
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, 1.4];
else
    ps.x_lim = [-0.4 stim_vals1(end) + stim_wind];
end
ps.recenterROIs = 0;
ps.transform_type = 'displace'; % 'none' or 'displace'         
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,'control_4mABi_1mAG',...
                               'control_4mABi_1mAG.fits'); 
ps.show_roi_labels = 1; 
ps.close_img_after_save = 0;   
ps.roi_func_fig_size = [48 16]; 
ps.overlay_trials = 0; 
ps.offset_factor = 0.5;
ps.analyze_traces = 'deltaF_F0_aligned2';
ps.motion_correct = 0;
ps.rem_pbleach = 0; 
ps.roi_func_sbar_len = 0.5;
% Load ROIs
rois = ROIs(fullfile(exp_fold,roiset_filename));
if regexp(roiset_filename,'pc')
    rois.invert_y(imsize);
end
xOk = rois.x > subROI(3) & rois.x < subROI(4);
yOk = rois.y > subROI(1) & rois.y < subROI(2);
roi_inds = find(xOk & yOk);
rois = rois.slice(roi_inds);
rois.roiset_filename = [rois.roiset_filename,'_crop'];
%% Plot
stim2_y = 1.005; 
ps.condition = 'control_4mABi_1mAG';
img_name = [ps.condition ''];
datai = plotTrial(img_name,exp_settings,rois,[],ps);
t = datai.func_output.trec; 
% Add DC stim
ax = gca;
plot(ax,[stim_vals2';stim_vals2'+stim_pulse_dur2;nan(size(stim_vals2'))],...
          [ax.YLim(1)+range(ax.YLim).*[stim2_y;stim2_y].*ones(2,length(stim_vals2'));nan(size(stim_vals2'))],...
            'Color','k','LineStyle','-','LineWidth',2);
ax.YLim = [ax.YLim(1) ax.YLim(1)+range(ax.YLim)*stim2_y];
fig = gcf;
if save_figs
    roiset_filename_no_ext = getROIset_name(rois,...
                                            ps.transform_type,...
                                            ps.registration_rec);  
    fig_dir = fullfile(datai.recording.filedir,['figs_',roiset_filename_no_ext]);
    fig_name = [datai.recording.img_name '_' ps.plot_func];
    printFig(fig,fig_dir,fig_name);
end
%% Plot diffImage cropped
mean_diff_img = datai.imgs.mean_diff_img(subROI(1):subROI(2),subROI(3):subROI(4));
fig = figure; 
imagesc(mean_diff_img); 
ax = gca;
ax.YDir = 'normal';
axis(ax,'equal','tight','off');
colormap(inferno(1000));
cb = colorbar;
cb.Label.String = 'Mean \Delta F (a.u.)';
cb.Label.Rotation = -90; 
rois_crop = rois.copy(); 
rois_crop.shift([-subROI(3)+1,-subROI(1)+1]);
rois_crop.plot('y',ax,1);
if save_figs
    fig_name = [datai.recording.img_name '_mean_diff_img'];
    printFig(fig,fig_dir,fig_name);
end