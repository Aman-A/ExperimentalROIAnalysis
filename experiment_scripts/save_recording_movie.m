%% Make movies 
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
roiset_filename = 'RoiSet_pc_pos2.zip';
%% Load recording
condition = 'control_4mABi_-1mAG';
img_name = [condition '_1'];
rec = Recording(fullfile(exp_fold,condition,[img_name '.fits'])); 
rec.load(); 
% Load ROIs
rois = ROIs(fullfile(exp_fold,roiset_filename));
if regexp(roiset_filename,'pc')
    rois.invert_y(rec.imsize);
end
%% Write movie
ms = struct();  % movie settings
% ms.start_frame = 1; 
% ms.end_frame = 2049; 
ms.start_frame = 985; 
ms.end_frame = 1190; 
ms.movie_slow_down_factor = 0.25; 
ms.stim_vals1 = stim_vals1; 
ms.stim_pulse_dur1 = stim_pulse_dur1; 
ms.stim_vals2 = stim_vals2; 
ms.stim_pulse_dur2 = stim_pulse_dur2; 
% ms.ROI = [50 130 60 150];
% ms.ROI = [50 149 65 164];
ms.ROI = [69 156 100 153];
ms.colormap = 'inferno';
ms.cax_lims = []; 
ms.fig_units = 'inches';
ms.fig_size = [8 6]; 
ms.filt_size = 4; % size of sptial filter
ms.filt_sigma = 1; % std of gaussian spatial filter
% Crop ROIs
rois_crop = rois.copy(); 
inside_ROI = rois_crop.x>ms.ROI(1) & rois_crop.x<ms.ROI(2) & rois_crop.y>ms.ROI(3) & rois_crop.y<ms.ROI(4); 
rois_crop.shift([-ms.ROI(1),-ms.ROI(3)]);
rois_crop.removeROIs(~inside_ROI)

mov_name = sprintf('%s_f%g-%g_%gx',img_name,ms.start_frame,ms.end_frame,ms.movie_slow_down_factor);;
mov_file = fullfile(exp_fold,condition,mov_name);
makeMovie(rec,sampling_rate,mov_file,ms)
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
