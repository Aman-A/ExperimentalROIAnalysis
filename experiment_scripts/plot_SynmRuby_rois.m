%% Plot SynmRuby with defined ROIset
% Experiment parameters
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240216';
reporter = 'GluSnFR3_SynmRuby_Kvbeta1shRNA';
dish = 'dish5';
% Specify image and ROIset files
condition = 'SynmRuby';
img_name = 'pos1';
roiset_filename = 'RoiSet_pc_pos1.zip';
% Plot settings
save_fig = 1;
cax_lims = [0.6 0.99];
sbar_x_factor = 0.8;
sbar_y_factor = 0.1;
sbar_text_x_factor = 0.5; 
sbar_text_y_factor = 1.1;
%% Load
dish_folder = fullfile(data_fold,exp_date,reporter,dish);
rec_filepath = fullfile(dish_folder,condition,img_name);
rec = Recording(rec_filepath);
rec.load();
vals = rec.vals;
pixel_size = rec.pixel_size;
imsize = rec.imsize;
rois = ROIs(roiset_filename);
if regexp(roiset_filename,'pc')
    rois.invert_y(rec.imsize);
end
%% Plot
fig = figure('Units','inches','Position',[0.1 1 20.5 5.2]); 
ax = gca;
rec.plot(round(rec.imsize(3)/2)); 
caxis(ax,quantile(rec.vals(:),cax_lims)) 
rois.plot('g',ax,1,1); 
colormap(ax,inferno(1000));      
ax.Position = [0.05 0.05 0.9 0.9];
addScaleBar(pixel_size,imsize,ax,'x_factor',sbar_x_factor,'y_factor',sbar_y_factor,...
            'text_x_factor',sbar_text_x_factor,'text_y_factor',sbar_text_y_factor)
fig.Children(1).Visible = 'off'; % turn of cbar
if save_fig
    printFig(fig,fullfile(data_fold,exp_date,reporter,dish),...
                sprintf('%s_%s',img_name,rois.roiset_filename))
end