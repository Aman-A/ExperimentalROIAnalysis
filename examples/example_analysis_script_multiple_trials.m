%% Example of loading set of image stacks (trials) and ROI sets to compute
% deltaF/F and plot
img_folder = './'; % replate with path to you folder
img_names = {'control_1','control_2'}; % enter list of img file names (can leave out .fits if they are all .fits files) 
                % make sure to separate with commas and enclose in single
                % quotes, ex: img_names = {'img1','img2','img3'}; 
roiset_names = {'RoiSet_pc_pos8','RoiSet_pc_pos8'}; % enter list of roiset file names (can leave out .zip)
                   % if using same roiset on multiple images, repeat that
                   % file name at the same index as the img file in the
                   % img_names array, ex:
                   % roiset_names = {'roiset_img1and2','roiset_img1and2','roiset_img3'};
plot_settings = struct();
plot_settings.show_diff_image = []; % can include [1,2,3]
plot_settings.filt_width = 0;
plot_settings.funcs = {'baseline','deltaF_F0'}; % options: 'mean','std','baseline','deltaF_F0'
plot_settings.roi_func_mode = 'separate'; % options: 'combine' or 'separate'
plot_settings.recenterROIs = 0; % set to 0 for off, or set to 'diff', 'peak', or 'baseline' to use those images for recentering ROIs
plot_settings.save_processed_data = 1;
plot_settings.load_processed_data = 1;
plot_settings.save_fig = 0;    
plot_settings.roiset_filedir = img_folder; % file directory where roisets are saved, currently same as image files
%% Specify your experimental parameters
sampling_rate = 200; % Sampling rate (frames/sec or Hz)
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
%% Next we'll extract data and plot traces for each trial
num_trials = length(img_names); 
func_outputs = cell(1,num_trials); 
deltaF_F0 = cell(1,num_trials); 
trial_times = NaT(1,num_trials); 
bslines = cell(1,num_trials); 
for i = 1:num_trials
    figi = figure; 
    axi = gca;
    img_namei = img_names{i}; 
    roi_set_filenamei = roiset_names{i};
    datai = plotTrial([],[],[],[],[],[],...
                   fullfile(img_folder,img_namei),exp_settings,roi_set_filenamei,...
                   axi,plot_settings);
    func_outputs{i} = datai.func_output; 
    deltaF_F0{i} = datai.func_output.deltaF_F0;
    trial_times(i) = datai.Recording.time_start; 
    bslines{i} = datai.func_output.baseline;
    saveROIfuncOutput(datai.func_output);
end
deltaF_F0 = cell2mat(deltaF_F0); 
peaks_deltaF_F0 = max(deltaF_F0,[],1); % peaks within trial
mean_peak_deltaF_F0 = mean(peaks_deltaF_F0);
std_peak_deltaF_F0 = std(peaks_deltaF_F0,0);
