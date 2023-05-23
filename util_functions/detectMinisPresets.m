function settings = detectMinisPresets(preset_name,sampling_rate)
%DETECTMINIPRESETS Outputs preset settings for a given experimental
%configuration (given by preset_name)
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
settings = detectMinis(); % initialize
switch preset_name
    case 'loki_50Hz'
        if nargin == 1
            sampling_rate = 50;
            fprintf('Using preset sampling rate %g Hz\n',sampling_rate)
        end        
        settings.threshold = 4; % threshold for peak detection on filtered trace. 
                        % Defined as multiple above noise level (std of
                        % baseline fluctations)
        settings.snr_thresh = 3; % throw out minis with 
                                 % mini SNR (peak/std(baseline)) less than this number 
                                 % (based on raw F trace). Set to 0 to skip this. 
        settings.nframes_back = round(0.4*sampling_rate); % number of frames before each mini peak to extract
        settings.nframes_forward = 12; % number of frames after each mini peak to extract
        settings.stim_frames = []; % ignore if no stim
        settings.blank_around_stim = []; % ignore if no stim
        settings.plot_filt_output_roi_index = 1; % plot example of filtering in this roi
        settings.mini_width_range = [10e-3 inf]; % sec - range of FWHM, 
        settings.min_peak_distance = 120e-3; % sec - min distance between mini peaks to allow
        settings.deconv = 1; % set to 1 to use deconvolution, may need to adjust threshold if turned off
        settings.apply_filter = 1;
        settings.filt_type = 'butter'; % filter type, 'gauss' for gaussian or 'butter' for butterworth
        settings.plot_figs = 1; % 1 to plot mini detection figures, 0 to skip
        settings.save_figs = 0; % 1 to save figures, 0 to skip
        settings.save_figs_dir = ''; % save figures to this directory (or leave blank to skip)
        settings.trial_name = ''; % for file saving
        settings.refilter_deconv = 0; % 1 to refilter deconvolved trace (usually doesn't have much effect, can skip)
        settings.smooth_filt_width = 0; % width of median smoothing filter, takes 
                                        % moving median of this number of frames,
                                        % usually not needed, especially if using
                                        % lower sampling rate, b/c it can cause
                                        % smooth out peaks too much
        settings.fc = [0.5]; % Hz - highpass filter cutoff frequences, gets rid 
                             % of baseline fluctuations
        settings.deconv_tau = 100e-3; % ms decay time constant for deconvolution. 
                                      % Uses single exponential decay with this
                                      % time constant to enhance SNR of events with
                                      % similar shape, time constant should match
                                      % decay time constant of minis in your
                                      % recordings, which can be measured after
                                      % detection below
        settings.find_pk_frame = 5; % number of frames around original peak to search in unfiltered traces (or 0 to use peak frame from filtered traces)
        settings.num_frames_skip_start = 5; % frames to remove from start due to filtering artifacts
        settings.num_frames_skip_end = 5; % frames to remove from end due to filtering artifacts
        settings.use_asls_baseline = 1;  % 1  to use asymmetric least squares baseline removal
                                         % 0 uses simple average of nframes_back
                                         % frames before each peak, may be less
                                         % robust for minis immediately after other
                                         % minis
        settings.asls_smoothness = 5; % smoothness param for asymmetric least squares (see asLS_baseline.m for description)
        settings.asls_asym = 0.1;  % asymmetry parameter for asymmetric least squares
        settings.est_rise_time_frames = 1; % take baseline this many frames before peak (typical rise time of GluSnFR3 signal)
    case {'thor_200Hz','odin_200Hz','thor_100Hz','odin_100Hz'}
        if nargin == 1
            sampling_rate = 200;
            fprintf('Using preset sampling rate %g Hz\n',sampling_rate)
        end
        settings.threshold = 10; % threshold for peak detection on filtered trace. 
                        % Defined as multiple above noise level (std of
                        % baseline fluctations)
        settings.snr_thresh = 4.5; % throw out minis with 
                                 % mini SNR (peak/std(baseline)) less than this number 
                                 % (based on raw F trace). Set to 0 to skip this. 
        settings.nframes_back = round(0.15*sampling_rate); % number of frames before each mini peak to extract
        settings.nframes_forward = round(0.4*sampling_rate); % number of frames after each mini peak to extract
        settings.stim_frames = []; % ignore if no stim
        settings.blank_around_stim = 0.1*sampling_rate*[1,1]; % ignore if no stim
        settings.plot_filt_output_roi_index = 17; % plot example of filtering in this roi
        settings.mini_width_range = [25e-3 inf]; % sec - mini FWHM range
        settings.min_peak_distance = 0.1; % sec - min distance between mini peaks to allow
        settings.deconv = 1; % set to 1 to use deconvolution, may need to adjust threshold if turned off
        settings.apply_filter = 1;
        settings.filt_type = 'gauss'; % filter type, 'gauss' for gaussian or 'butter' for butterworth
        settings.plot_figs = 1; % 1 to plot mini detection figures, 0 to skip
        settings.save_figs = 0; % 1 to save figures, 0 to skip
        settings.save_figs_dir = ''; % save figures to this directory (or leave blank to skip)
        settings.trial_name = ''; % for file saving
        settings.refilter_deconv = 1; % 1 to refilter deconvolved trace (usually doesn't have much effect, can skip)
        settings.smooth_filt_width = 5; % width of median smoothing filter, takes 
                                        % moving median of this number of frames,
                                        % usually not needed, especially if using
                                        % lower sampling rate, b/c it can cause
                                        % smooth out peaks too much
        settings.fc = [0.5 60]; % Hz - highpass filter cutoff frequences, gets rid 
                             % of baseline fluctuations
        settings.deconv_tau = 35e-3; % ms decay time constant for deconvolution. 
                                      % Uses single exponential decay with this
                                      % time constant to enhance SNR of events with
                                      % similar shape, time constant should match
                                      % decay time constant of minis in your
                                      % recordings, which can be measured after
                                      % detection below
        settings.num_frames_skip_start = 160; % frames to remove from start/end due to filtering artifacts
        settings.num_frames_skip_end = 160; % frames to remove from end due to filtering artifacts
        settings.use_asls_baseline = 1;  % 1  to use asymmetric least squares baseline removal
                                         % 0 uses simple average of nframes_back
                                         % frames before each peak, may be less
                                         % robust for minis immediately after other
                                         % minis
        settings.asls_smoothness = 100; % smoothness param for asymmetric least squares (see asLS_baseline.m for description)
        settings.asls_asym = 0.4; % asymmetry parameter for asymmetric least squares
        settings.find_pk_frame = 5;% look 25 ms around peak from filtered F in raw F to get actual peak time
        
end