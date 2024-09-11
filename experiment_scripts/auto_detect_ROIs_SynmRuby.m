% Get ROIs automatically from Synapsin-mRuby
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240717';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish3';
div = 15; 

condition = 'SynmRuby';
img_name = 'pos0';
save_rois = 1;
dish_folder = fullfile(data_fold,exp_date,reporter,dish);
rec_filepath = fullfile(dish_folder,condition,img_name);
rec = Recording(rec_filepath);
roiset_filename = sprintf('RoiSet_auto_%s',img_name);
intens_thresh = 0.993; % for control.fits
% intens_thresh = 0.97; % for control_aftercut.fits
pixel_size = rec.pixel_size; 
% area_thresh = [3 40]*pixel_size^2; % 4x4 pixels to 8x8 pixels or 0.64 to 10.24 um^2 
area_thresh = [1 80]*pixel_size^2; % 4x4 pixels to 8x8 pixels or 0.64 to 10.24 um^2 
roi_radius = 3; % pixels
num_pixel_dist = 1;
filt_width = 0; 
min_distance = ((roi_radius*2)+num_pixel_dist)*pixel_size; 
rois = detectROIs(rec,intens_thresh,area_thresh,roi_radius,...
                'min_distance',min_distance,'save_figs',1,'filt_width',filt_width);
% roi_inds =1:27;
% roi_inds([1,2,6,7,8,9,12,18,19]) = []; 
% 
% rois.removeROIs(1); 
if save_rois
    rois.save(fullfile(dish_folder,[roiset_filename '.mat']));
end