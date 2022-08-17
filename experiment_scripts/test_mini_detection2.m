%% Mini detection 
% Analysis settings
method = 1; % mini finding method
threshold = 3; % x std (noise level) 12 if deconv on
min_mini_width = 10e-3; % sec - min FWHM of minis
fc = [0.5 30]; % Hz - bandpass filter cutoff frequences
nframes_back = 10;  % number of frames behind each mini to extend window
nframes_forward = 30; 
% Path to data and ROIs
exp_folder = fullfile(getDataFold(),'20220802/GluSnFR3_SynmRuby/dish3'); 
img_folder = fullfile(exp_folder,'350mM_sucrose');
% roi_set_name = 'RoiSet_pc_pos0';
roi_set_name = 'RoiSet_auto_wash.mat';
% roi_set_name = 'RoiSet_test.zip';
% exp_folder = fullfile(getDataFold(),'../Sam_data/20210908 d5'); 
% img_folder = fullfile(exp_folder,'the stack');
% roi_set_name = 'RoiSet_analysis';
% Experiment/imaging settings
sampling_rate = 200; % 
stim_vals = defineStimTrain(0,0.5,42); 
stim_wind = 0.5; 
baseline_wind = 0.15; 
units = 'sec';
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,units,sampling_rate); 
%% Load recording
img_names = getImagesWithinDir(img_folder); 
img_name = img_names{2}; 
rec = Recording(fullfile(img_folder,img_name));  
rec.load(); 
rois = ROIs(fullfile(exp_folder,roi_set_name)); 
if regexp(roi_set_name,'pc')
    rois.invert_y(rec.imsize); 
end
%% Extract traces in ROIs
func_output = calcROIfuncs(rec,rois,{'mean','deltaF_F0'},exp_settings,...
                            'separate');
deltaF_F0 = func_output.deltaF_F0;    
means = func_output.mean;
t = exp_settings.getTimeVector(size(deltaF_F0,1));
funcs = {'peaks','peak_times'};
peaks_struct = analyzeTraces(func_output.deltaF_F0,exp_settings,'funcs',funcs);
evoked_peaks = peaks_struct.peaks;
%% Plot traces in all
fig = figure('Units','inches','Position',[0.4479    1.3021   19.0625    8.9583]); 
ax = gca;
plotROIfunc(func_output,'deltaF_F0',exp_settings.stim_vals,...
            exp_settings.sampling_rate,'ax',ax,...
            'show_legend',0,'rois',rois);
%% 
settings.sampling_rate = exp_settings.sampling_rate;
settings.nframes_back = nframes_back;
settings.nframes_forward = nframes_forward; 
settings.stim_frame = exp_settings.stim_vals;
settings.blank_around_stim = [exp_settings.baseline_wind,exp_settings.stim_wind]; 
settings.threshold = 15; % 3 or 12 (deconv)
settings.snr_thresh = 4;
settings.roi_with_mini_index = 19; 
settings.min_mini_width = 10e-3;
% To do: Add width criteria based on upstroke/downstroke of mini (FWHM?)
mini_output = detect_minis(means,settings,method,'apply_filter',1,...
                           'plot_figs',1,'deconv',1,'fc',fc); 
%% Example analyis
num_minis_per_roi = cellfun(@length,mini_output.mini_frames,'UniformOutput',1);
% rois_w_minis = num_minis_per_roi > 0; 
% peaks_evoked_rois_w_minis = evoked_peaks(rois_w_minis);
mean_peaks_minis = cellfun(@mean,mini_output.mini_peaks_deltaF_F,'UniformOutput',1)';
evoked_rel_minis = evoked_peaks./mean_peaks_minis;
fig = figure('Units','normalized'); 
fig.Position(3:4) = [0.412 0.323];
histogram(evoked_rel_minis,'BinWidth',0.25,'Normalization','probability',...
                  'EdgeColor','none'); box off; hold on;
xlabel('Peak evoked/mean peak mini'); ylabel('Proportion')
title(sprintf('Mean mini = %.2f, mean evoked = %.3f. Threshold = %.1f x std',...
       mean(mean_peaks_minis,'omitnan'),mean(evoked_rel_minis,'omitnan'),settings.threshold))
ax = gca; ax.FontSize = 16; 
plot([1:3;1:3],ax.YLim','--k'); % lines at 1, 2, 3