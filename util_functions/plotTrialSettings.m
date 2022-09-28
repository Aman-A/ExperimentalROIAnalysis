function settings = plotTrialSettings(varargin) 
%PLOTTRIALSETTINGS Outputs settings struct for plotTrial/plotTrials 
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
settings.data_fold = pwd;
settings.exp_date = '';
settings.reporter = '';
settings.dish = '';
settings.div = [];
settings.condition = '';
settings.position = '';
settings.filedir = ''; % placeholder for inputs from plotTrials
settings.show_diff_image = [3]; % for diffImage, specify which plots to include, can include 1, 2, 3 in
                         %  any order (1 - Baseline, 2 - Peak, 3 - Difference)
settings.filt_width = 0; % gaussian filter width, used on peak deltaF to refine 
               % ROI positions
settings.peak_mode = 'max'; % 'max', 'mean', or 1x2 vector [start frame, end frame] 
                            % within which to take mean for diffImage
settings.diff_image_cmap = 'inferno'; % colormap for diffImage
settings.funcs = {'mean','baseline','deltaF_F0'}; % functions to compute
settings.plot_func = 'deltaF_F0'; % function to plot in ROI (plotROIfunc)
settings.roi_func_mode = 'combine';
settings.save_processed_data = 1;
settings.load_processed_data = 1; 
settings.y_lim = [];
settings.x_lim = []; 
settings.recenterROIs = 0; 
settings.roiset_filedir = []; % default set below (one directory above img directory)
settings.roi_func_fig_size = [19.8 9.1];
settings.roi_func_fig_units = 'centimeters';
settings.transform_type = 'none'; % 'displace','translation','rigid','similarity','affine' - Image coregistration
settings.registration_rec = ''; % full path to Recording to register for shifting ROIs or Recording object
settings.save_fig = 0; % 1 just plots images for trial, 2 also plots funcs in ROI for trial
settings.overlay_trials = 1;
settings.close_img_after_save = 1; 
settings.show_roi_labels = 0;
settings.pixel_size = 0.4; % um (pixel size on Thor camera with 40x objective)
settings.bin_size = 1; % 1x1 binning
settings.sort_traces = 0; % 1 to sort traces by plotROIfunc 
settings.offset_factor = 1.01; % sets trace offset for separate ROIs in plotROIfunc 
settings.roi_func_sbar_len = 1; 
settings.registration_rec_settings = []; % if necessary, separate ExperimentSettings for registration recording
settings.analysis_funcs = {}; % for plotTrials
settings.analyze_traces = 'deltaF_F0_aligned'; % choose which to analyze: 'deltaF_F0_aligned' or 'deltaF_F0_aligned2'
settings.rem_pbleach = 0; % 1 to remove photobleaching in calcROIfuncs
settings.fwhm_spline_interp = 0; % 1 to use cubic spline interpolation for FWHM calculation
settings.motion_correct = 0; % 1 to use motionCorrectRecording (uses dftregistration FFT-based algorithm)
settings = sl.in.processVarargin(settings,varargin);
