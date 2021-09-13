function output_data = plotTrial(data_fold,exp_date,reporter,dish,condition,position,...
                                 img_name,exp_settings,roi_set_filename,trace_axis,...
                                 show_diff_image,filt_width,funcs,... % Optional
                                 roi_func_mode,save_processed_data,...
                                 load_processed_data)
% Plot single trial difference image and response over time in ROIs
if nargin < 11
   show_diff_image = []; 
   filt_width = 0; % gaussian filter width, used on peak deltaF to refine 
                   % ROI positions
   
   funcs = {'mean','std','baseline','deltaF_F0'}; % functions to compute
   roi_func_mode = 'combine';
   save_processed_data = 1;
   load_processed_data = 0; 
end
%% Load trial data
% Hold off on loading image in case processed data exists and
% load_processed_data == 1
img = Recording(img_name,position,condition,dish,reporter,exp_date,data_fold); 
% Prepare filename for saving data and check if it exists
[~,img_name_no_ext] = fileparts(img_name); 
[~,roi_set_filename_no_ext] = fileparts(roi_set_filename);    
save_data_filename = fullfile(img.filedir,sprintf('%s-%s-data.mat',...
                                                  img_name_no_ext,...
                                                  roi_set_filename_no_ext));
if exist(save_data_filename,'file') && load_processed_data && ~any(show_diff_image)
    % Load processed data (skips showing diff image, so must be empty/set
    % to zeros)
    output_data = load(save_data_filename); 
    func_output = output_data.func_output;
    fprintf('Loaded processed data from %s\n',save_data_filename); 
else
    img.load();  % Load image data
    %% Output peak image
    [~,~,diff_img] = diffImage(img,exp_settings,'inferno',show_diff_image,filt_width); % Plot peak pixel values - baseline
    ax = gca;                        
    %% Load saved ROIs
    rois = circROIs(roi_set_filename,[img.filedir filesep '..']); % assume directory above data for this condition
    % Recenter using peak after stim
    rois.recenterROIsLoop(diff_img,0,1); % recenter to peak value repeatedly until no further shift occurs
    if any(show_diff_image)
        % Overlay on diff image
        rois.plot('y',ax,0); % plot starting
        rois.plot('g',ax,1); % plot current after shift
    else
        fprintf('Skipping diff image plot\n'); 
    end
    %% Calculate deltaF/F0 
    func_output = calcROIfuncs(img,rois,funcs,exp_settings.baseline_wind_inds,...
                               roi_func_mode);
            
    %% Save processed data
    if save_processed_data            
        output_data = struct();
        output_data.Recording = img.unload(); % save with data unloaded, reduce HD usage
        output_data.Settings = exp_settings;    
        output_data.ROIs = rois; 
        output_data.funcs = funcs; 
        output_data.func_output = func_output;       
        save(save_data_filename,'-STRUCT','output_data'); 
        fprintf('Saved data to %s\n',save_data_filename); 
    end
end
%% Plot data
plotROIfunc(func_output,'deltaF_F0',exp_settings.stim_vals,...
                exp_settings.sampling_rate,trace_axis);        
drawnow; 
end
                    