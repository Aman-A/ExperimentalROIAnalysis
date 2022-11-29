%% Run SNAPT algorithm on set of trials
exp_name = 'AP_prop_polarization_experiments';
data_fold = fullfile(getDataFold(),exp_name);
exp_date= '221111';
reporter = 'Archon';
dish = 'dish4';
div = 17; 
% Experiment conditions/trial data
conditions = {'25AP_5Hz_pos0_soma','25AP_5Hz_pos0_axon','25AP_5Hz_pos0_dend'};
img_names = cell(1,length(conditions));
%% Experiment settings
num_stim = 25; % number desired APs 20 or 100
stim_pulse_dur = 0.001; % pulse duration (sec)
stim_freq = 5; % Hz
stim_delay = 0; % sec % 3 or 5 sec delay
% stim_delay = 0.2; 
stim_duration = (num_stim+1)/stim_freq;
total_time = stim_duration + stim_delay;
sampling_rate = 2000; % sampling rate of camera (frames/sec) - exp time 0.0004815
stim_vals = defineStimTrain(stim_delay,stim_freq,stim_duration); % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 0.1; % window
baseline_wind = 0.05; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec'
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
%% SNAPT settings
exp_folder = fullfile(data_fold,exp_date,reporter,dish);
finalT = 3.5; 
std_thresh = [0.007,0.013,0.015]; 
save_figs = 1; 
get_traces = 0;
cax_lims = [0.5 2.5]; % colorbar limits for SNAPT timing plot
set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
for i = 2:length(conditions)
    conditioni = conditions{i};
    if isempty(img_names{i})
        img_namesi = getImagesWithinDir(fullfile(exp_folder,conditioni));
    else
        img_namesi = img_names{i};
    end    
    if length(std_thresh) == length(conditions)
        std_threshi = std_thresh(i); 
    else
        std_threshi = std_thresh; 
    end
    for j = 1:length(img_namesi)        
        img_nameij = img_namesi{j}; 
        [~,img_nameij_no_ext] = fileparts(img_nameij);
        fig_dir = fullfile(exp_folder,conditioni,sprintf('%s_snapt',img_nameij_no_ext));
        roi_points_file = fullfile(exp_folder,conditioni,sprintf('roi_points.mat'));
        % Load recording
        rec = Recording(fullfile(exp_folder,conditioni,img_nameij));   
        rec.load(); 
        if exist(roi_points_file,'file')
            roi_points = load(roi_points_file);
            [spike_movie,df_F_spike_movie,dtimg2] = snapt_pca_fcn(rec.vals,exp_settings.sampling_rate,exp_settings.stim_vals,...
                'fig_dir',fig_dir,'roi_points',roi_points.roi_points,...
                'img_name',img_nameij_no_ext,'find_spikes',0,'finalT',finalT,...
                'save_figs',save_figs,'std_thresh',std_threshi,...
                'cax_lims_timing',cax_lims,'get_traces',get_traces);
        else
            [spike_movie,df_F_spike_movie,dtimg2] = snapt_pca_fcn(rec.vals,exp_settings.sampling_rate,exp_settings.stim_vals,...
                'fig_dir',fig_dir,...
                'img_name',img_nameij_no_ext,'find_spikes',0,'finalT',finalT,...
                'save_figs',save_figs,'std_thresh',std_threshi,...
                'cax_lims_timing',cax_lims,'get_traces',get_traces);
        end
        close all;
    end
end
set(0,'DefaultFigureVisible','on') % undo