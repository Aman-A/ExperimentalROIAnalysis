%% Make kymograph
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
stim_pulse_dur1 = 0.02; % sec
% DC field stim
stim_vals2 = 10.25; % sec 
stim_pulse_dur2 = 10; % sec
% ROIs
roiset_filename = 'axon_branch1';
%% Load recording
condition = 'control_4mABi_-1mAG';
img_name = [condition '_1'];
rec = Recording(fullfile(exp_fold,condition,[img_name '.fits'])); 
rec.load(); 
% Load ROIs
line_roi = ROIs(fullfile(exp_fold,[roiset_filename '.zip']));
line_roi.invert_y(rec.imsize);
%% Save kymograph
ks = struct();  % movie settings
ks.log_scale = 1; 
% ks.start_frame = 1; 
% ks.end_frame = 2049; 
ks.start_frame = 985; 
ks.end_frame = 1190; 
ks.stim_vals1 = stim_vals1; 
ks.stim_pulse_dur1 = stim_pulse_dur1; 
ks.stim_vals2 = stim_vals2; 
ks.stim_pulse_dur2 = stim_pulse_dur2; 
ks.colormap = 'inferno';
ks.cax_lims = []; 
ks.fig_units = 'inches';
ks.fig_size = [8 6]; % truncated recording
% ks.fig_size = [26 5];
ks.filt_size = 4; % size of sptial filter
ks.filt_sigma = 1; % std of gaussian spatial filter
ks.mov_ave_window = 3; % moving average temporal filter on kymograph
ks.save_figs = 1; 
ks.fig_fold = fullfile(exp_fold,condition);
makeKymograph(rec,line_roi,sampling_rate,ks)
%% Make mRuby image with same crop
% mruby_file = fullfile(exp_fold,'SynmRuby','pos2.fits');
% mruby_rec = Recording(mruby_file);
% mruby_rec.load(); 
% 
% mruby_img = mean(mruby_rec.vals,3); 
% % mruby_img = mean(mruby_rec.vals(ms.ROI(1):ms.ROI(2),ms.ROI(3):ms.ROI(4),:),3);
% fig = figure('Units',ms.fig_units);
% fig.Position(3:4) = ms.fig_size; 
% ax = gca;
% imagesc(ax,mruby_img)
% axis(ax,'equal','tight','off');
% ax.YDir = 'normal';
% colormap(magma(1000))
% % rois_crop.plot('y',ax);
% rois.plot('y',ax);
% axis(ms.ROI);
