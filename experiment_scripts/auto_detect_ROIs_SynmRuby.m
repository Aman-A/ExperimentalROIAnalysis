% Get ROIs automatically from Synapsin-mRuby
data_folder = getDataFold(); 
exp_date = '20220802';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish3';
condition = 'SynmRuby';
img_name = 'wash';
save_rois = 1;
% dish_folder = fullfile(data_folder,exp_date,reporter,dish);
% rec_filepath = fullfile(dish_folder,condition,img_name);
dish_folder = fullfile(fileparts(which('test_mini_detection2.m')),'test_data',...
                       '20220802_GluSnFR3_SynmRuby_dish3_350mM_sucrose');
rec_filepath = fullfile(dish_folder,condition,img_name);
rec = Recording(rec_filepath);
roiset_filename = sprintf('RoiSet_auto_%s',img_name);
intens_thresh = 0.99; % quantile
pixel_size = rec.pixel_size; 
area_thresh = [4 25]*pixel_size^2; % 4x4 pixels to 8x8 pixels or 0.64 to 10.24 um^2 
roi_radius = 3; 
num_pixel_dist = 2;
min_distance = ((roi_radius*2)+num_pixel_dist)*pixel_size; 
rois = detectROIs(rec,intens_thresh,area_thresh,roi_radius,...
                'min_distance',min_distance);
if save_rois
    rois.save(fullfile(dish_folder,[roiset_filename '.mat']));
end