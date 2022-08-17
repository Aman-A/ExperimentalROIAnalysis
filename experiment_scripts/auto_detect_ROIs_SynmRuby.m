% Get ROIs automatically from Synapsin-mRuby
data_folder = getDataFold(); 
exp_date = '20220802';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish3';
condition = 'SynmRuby';
img_name = 'wash';
save_rois = 1;
dish_folder = fullfile(data_folder,exp_date,reporter,dish);
rec_filepath = fullfile(dish_folder,condition,img_name);
roiset_filename = sprintf('RoiSet_auto_%s',img_name);
intens_thresh = 0.99; % quantile
area_thresh = 4; 
roi_radius = 3; 
min_distance = roi_radius*2*0.4; 
rois = detectROIs(rec_filepath,intens_thresh,area_thresh,roi_radius,...
                'min_distance',min_distance);
if save_rois
    rois.save(fullfile(dish_folder,[roiset_filename '.mat']));
end