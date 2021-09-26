function output_data = plotTrial(data_fold,exp_date,reporter,dish,condition,position,...
                                 img_name,exp_settings,roi_set_filename,trace_axis,...
                                 varargin)
% Plot single trial difference image and response over time in ROIs

in.show_diff_image = []; 
in.filt_width = 0; % gaussian filter width, used on peak deltaF to refine 
               % ROI positions

in.funcs = {'baseline','deltaF_F0'}; % functions to compute
in.plot_func = 'deltaF_F0'; % function to plot in ROI (plotROIfunc)
in.roi_func_mode = 'combine';
in.save_processed_data = 1;
in.load_processed_data = 0; 
in.y_lim = [-0.2 1.2];
in.roi_func_fig_size = [19.8 9.1];
in.roi_func_fig_units = 'centimeters';
in.save_fig = 0; % 1 just plots images for trial, 2 also plots funcs in ROI for trial
in = sl.in.processVarargin(in,varargin); 
%% Load trial data
% Hold off on loading image in case processed data exists and
% load_processed_data == 1
img = Recording(img_name,position,condition,dish,reporter,exp_date,data_fold); 
% Prepare filename for saving data and check if it exists
[~,img_name_no_ext] = fileparts(img_name); 
[~,roi_set_filename_no_ext] = fileparts(roi_set_filename);    
save_data_filename = fullfile(img.filedir,sprintf('%s-%s-%s-data.mat',...
                                                  img_name_no_ext,in.roi_func_mode,...
                                                  roi_set_filename_no_ext));
fig_dir = fullfile(data_fold,exp_date,reporter,dish,condition,...
                    ['figs_',roi_set_filename_no_ext]);                                               
if exist(save_data_filename,'file') && in.load_processed_data
    % Load processed data (skips showing diff image, even if set in
    % show_diff_image)
    output_data = load(save_data_filename); 
    func_output = output_data.func_output;
    fprintf('Loaded processed data from %s\n',save_data_filename); 
    % Plot baseline, peak, diff images
    fig_hands = plotDiffImage(output_data.mean_bsline_img,output_data.peak_stim_img,...
                  output_data.diff_img,img.img_name,exp_settings,...
                  'include_plots',in.show_diff_image,'filt_width',in.filt_width);               
    addROIoverlayAndSave(fig_hands,output_data.ROIs,in.save_fig,fig_dir,img.img_name);
else
    img.load();  % Load image data
    %% Output peak image
    [mean_bsline_img,peak_stim_img,diff_img,fig_hands] = diffImage(img,...
                                                        exp_settings,...                                                        
                                                        'include_plots',...
                                                        in.show_diff_image,...
                                                        'filt_width',...
                                                        in.filt_width);                          
    %% Load saved ROIs
    rois = circROIs(roi_set_filename,[img.filedir filesep '..']); % assume directory above data for this condition
    % Recenter using peak after stim
    rois.recenterROIsLoop(diff_img,0,1); % recenter to peak value repeatedly until no further shift occurs
    if any(in.show_diff_image)
        % Overlay on diff image and save        
        addROIoverlayAndSave(fig_hands,rois,in.save_fig,fig_dir,img.img_name);
    else
        fprintf('Skipping diff image plot\n'); 
    end   
    %% Calculate deltaF/F0 
    func_output = calcROIfuncs(img,rois,in.funcs,exp_settings.baseline_wind_inds,...
                               in.roi_func_mode);
    %% Generate output data structure
    output_data = struct();
    output_data.Recording = img.unload(); % save with data unloaded, reduce HD usage
    output_data.Settings = exp_settings;    
    output_data.ROIs = rois; 
    output_data.mean_bsline_img = mean_bsline_img;
    output_data.peak_stim_img = peak_stim_img;
    output_data.diff_img = diff_img; 
    output_data.funcs = in.funcs; 
    output_data.func_output = func_output;            
    %% Save processed data    
    if in.save_processed_data                    
        save(save_data_filename,'-STRUCT','output_data'); 
        fprintf('Saved data to %s\n',save_data_filename); 
    end
end
%% Plot data
plotROIfunc(func_output,in.plot_func,exp_settings.stim_vals,...
                exp_settings.sampling_rate,trace_axis);       
if ~isempty(in.y_lim)            
    trace_axis.YLim = in.y_lim;         
end
fig = trace_axis.Parent;
fig.Units = in.roi_func_fig_units;
fig.Position(3:4) = in.roi_func_fig_size;
drawnow; 
if in.save_fig > 1 % set to 2 to plot individual trials   
   fig_name = [img.img_name '_' in.plot_func]; 
   printFig(fig,fig_dir,fig_name); 
end
end
function addROIoverlayAndSave(fig_hands,rois,save_fig,fig_dir,img_name)
for i = 1:length(fig_hands)
    ax = fig_hands(i).Children(end);    
    rois.plot('y',ax,0); % plot starting
    rois.plot('g',ax,1); % plot current after shift
    if save_fig  % Save images with ROI overlays (if exist)
        printFig(fig_hands(i),fig_dir,[img_name,'_',fig_hands(i).Name],...
            'formats','png','resolutions','-r300')
    end
end
end
                    