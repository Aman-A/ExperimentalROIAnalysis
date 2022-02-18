%% Example of loading image stack and ROI set and computing deltaF/F
% First make sure the folder containing ExperimentalROIAnalysis code is on
% your path, e.g., if ExperimentalROIAnalysis folder is at: 
% C:\Users\HoppaLab\Documents\MATLAB\ExperimentalROIAnalysis 
% Run in the Command Window:
% >> addpath(genpath('C:\Users\HoppaLab\Documents\MATLAB\ExperimentalROIAnalysis'))
%
% Note: to avoid doing this everytime you start MATLAB, create a file called
% startup.m (if it doesn't exist already) in MATLAB's default
% directory, which is typically C:\Users\<username>\Documents\MATLAB. Or,
% you can get the location of this folder by entering 'userpath' in the
% command window. Now, everytime MATLAB starts, it will run the code in
% startup.m, including the addpath line we added, allowing you to run
% the functions in ExperimentalROIAnalysis regardless of where your
% analysis script/data files are saved.

% NOTE: To run this script, make sure to run it from the 
% ..\ExperimentalROIAnalysis\examples\ folder 
% (the working directory in the left panel (default layout) should be
%  the folder where this script is saved)
%% First specify the file names of your image stack and ROIset
img_file_name = 'FILENAME.fits'; % replace FILENAME with your image file name 
                                 % if the file is in a different
                                 % folder, make sure to include
                                 % full path, e.g.
                                 % C:\Users\HoppaLab\Documents\...
                                 % Only tiff and fits currently supported
roiset_file_name = 'ROISET_FILENAME.zip'; % Replace ROISET_FILENAME with 
                                          % ROI set file name. Save these 
                                          % from ImageJ in the ROI manager 
                                          % as a zip file
%% Next specify your experimental parameters
sampling_rate = 200; % Sampling rate (frames/sec)
stim_vals = [600]; % Stimulation frames, either a single value or list of
                   % values enclosed in brackets [] (a MATLAB vector)
stim_wind = 200; % Frames after stimulus frame to calculate peak of response
baseline_wind = 30; % frames before stimulation frame to take baseline
units = 'frames'; % the values above can also be specified in sec, in which
                  % case this variable would be set to 'sec'

% These parameters are used to create an ExperimentSettings object that 
% holds this information for use later
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,units,...
                                  sampling_rate); % Creates instance of 
                                                  % ExperimentSettings object
                              
%% Now that our parameters have been specified, we'll create a Recording 
% object to hold the image stack                                          
img = Recording(img_file_name); % Create instance of Recording object,
                                % this can currently handle 'fits' or 'tiff' 
                                % file formats                                          
% Actually load the file into memory with the 'load' method 
img.load(); 
%% Load the ROIset into an object called ROIs object
rois = ROIs(roiset_file_name); 
% This next part is a temporary fix for ROIs saved on windows ImageJ. For some
% (May not be necessary anymore)
% % reason the y coordinate is inverted relative to the data files
% if ischar(roiset_file_name)
%     if regexp(roiset_file_name,'pc')
%         % TEMPORARY FIX: include 'pc' in file name to indicate ROIs created on
%         % Windows ImageJ, require y axis to be inverted when
%         % importing to MATLAB
%         rois.invert_y(img.imsize);
%     end
% end
%% Plot the mean baseline, peak response, and peak - baseline images
include_plots = [1 2 3]; % this specifies which plots to include: 
                         % 1 - mean baseline
                         % 2 - peak in stim_wind
                         % 3 - difference (peak - mean baseline images)
                         % Ex: to just plot the difference plot, replace
                         % with include_plots = [3];
filt_width = 0; % Specify width of 2D gaussian filter to apply, or set to 
                % 0 for no filtering (default)
[mean_bsline_img,peak_stim_img,diff_img,fig_hands] = diffImage(img,...
                                                        exp_settings,...                                                        
                                                        'include_plots',...
                                                        include_plots,...
                                                        'filt_width',...
                                                        filt_width); 
% Overlay ROIset on all images
for i = 1:length(fig_hands)
   ax = fig_hands(i).Children(end); 
   rois.plot('y',ax,1); 
end
%% Finally, we can compute functions on the pixels within the ROIset
funcs = {'mean','deltaF_F0','baseline'}; % List of functions you want
                                               % to apply. These are all
                                               % functions currently
                                               % implemented. You can
                                               % enter them in any order,
                                               % or remove functions you
                                               % don't want                                               
roi_func_mode = 'combine'; % can be 'separate' or 'combine'. 'separate' 
                            % applies function separately within each ROI,
                            % while 'combine' applies function to pixels
                            % from all ROIs. For example, in 'combine'
                            % mode, 'mean' outputs the mean fluorescence
                            % across all ROI pixels in each frame (single 
                            % trace), but in 'separate' mode, it computes 
                            % the mean fluorescence within each ROI in each
                            % frame (for 21 ROIs in this example, 21 traces)
func_output = calcROIfuncs(img,rois,funcs,exp_settings,...
                           roi_func_mode,'print_level',1);
% func_output is a structure with fields containing the output of each
% function in 'funcs' as arrays, i.e., func_output.mean, func_output.std,
% func_output.deltaF_F0
%% You can plot the output of calcROIfuncs using the plotROIfunc function
% Let's just plot the deltaF_F0
plot_func = 'deltaF_F0'; % this specifies which function to plot 
                         % (should match names in funcs/func_output)
fig = figure; 
fig.Units = 'inches'; % units of figure dimensions 
fig.Position = [0.54 2.46 12.37 7.7]; % set figure position, 
                                      % [x,y,width,height] referenced 
                                      % to bottom left corner
ax = gca; % grab axis handle
plotROIfunc(func_output,plot_func,exp_settings.stim_vals,...
            exp_settings.sampling_rate,'ax',ax,'show_legend',1); 
%% You can save function output to csv files using saveROIfuncOutput
saveROIfuncOutput(func_output);