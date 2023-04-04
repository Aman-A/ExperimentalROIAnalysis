% Get ROIs automatically from Synapsin-mRuby
condition = 'SynmRuby';
img_name = 'control.fits';
save_rois = 0; 
dish_folder = fullfile(fileparts(which('test_auto_detect_ROIs_SynmRuby.m')),'test_data',...
                       '20220802_GluSnFR3_SynmRuby_dish3_350mM_sucrose');
rec_filepath = fullfile(dish_folder,condition,img_name);
rec = Recording(rec_filepath);
rec.load(); 
%%
close all;
intens_thresh = 0.99; % quantile
pixel_size = rec.pixel_size; 
area_thresh = [2 25]*pixel_size^2; % min to max area in um
roi_radius = 3; % ROI radius in pixels
num_pixel_dist = 0; 
opts = struct(); 
opts.min_distance = ((roi_radius*2)+num_pixel_dist)*pixel_size; % min distance between ROIs in un
opts.filt_width = 1.5;
opts.filt_type = 'log';
opts.center_mode = 1; 

rois = detectROIs(rec.vals,intens_thresh,area_thresh,roi_radius,...
                opts);

roiset_filename = sprintf('RoiSet_auto_%s',img_name);
if save_rois
    rois.save(fullfile(dish_folder,[roiset_filename '.mat']));
end