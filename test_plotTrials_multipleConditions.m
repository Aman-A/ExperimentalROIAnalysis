%% Script to plot multiple trials across multiple conditions 
data_fold = '/Volumes/BACKUPDRIVE/Dartmouth_data';
exp_date= '20210911'; 
reporter = 'GluSnFr3';
dish = 'dish4'; 
conditions = {'control','5nM_DTX','50nM_DTX_t2','post50_wash_t2'}; % 'control', '5nM_DTX', '50nM_DTX'
% conditions = {'control','5nM_DTX','50nM_DTX','post50_wash','50nM_DTX_t2',...
%                 'post50_wash_t2'}; % 'control', '5nM_DTX', '50nM_DTX'
position = 'Pos1'; 
img_names = {}; % use all images in condition folder
% img_names = {'DTX5.fits','DTX5_1.fits'}; % or specify in cell array
stim_vals = 3; % frames - 3 sec delay (100 Hz sampling time)
stim_wind = 1; % window
baseline_wind = 1; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 100; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames
roi_set_filenames = {'RoiSet_pos1.zip','RoiSet_pos1.zip',...
                    'RoiSet_pos1_t2.zip','RoiSet_pos1_t2.zip'}; 
% Optional settings
show_diff_image = []; % can include [1,2,3]
filt_width = 0; 
funcs = {'mean','std','baseline','deltaF_F0'}; 
roi_func_mode = 'combine';
save_processed_data = 1;
load_processed_data = 1;
%% Plot
num_conditions = length(conditions); 
peaks_deltaF_F0_all = cell(1,num_conditions); 
mean_peaks = zeros(1,num_conditions);
std_peaks = zeros(1,num_conditions);
sem_peaks = zeros(1,num_conditions);
trial_times_all = cell(1,num_conditions); 
for i = 1:num_conditions
    condition = conditions{i}; 
    roi_set_filename = roi_set_filenames{i}; 
    [deltaF_F0,peaks_deltaF_F0,mean_peak_deltaF_F0,std_peak_deltaF_F0,trial_times] = ...
        plotTrials(data_fold,exp_date,reporter,dish,condition,position,img_names,...
                exp_settings,roi_set_filename,show_diff_image,filt_width,funcs,...
                roi_func_mode,save_processed_data,load_processed_data);
    peaks_deltaF_F0_all{i} = peaks_deltaF_F0;
    mean_peaks(i) = mean_peak_deltaF_F0;
    std_peaks(i) = std_peak_deltaF_F0; 
    sem_peaks(i) = std_peak_deltaF_F0/sqrt(length(peaks_deltaF_F0)); 
    trial_times_all{i} = trial_times; 
end
peaks_deltaF_F0_all = cell2mat(peaks_deltaF_F0_all); 
% get start time of first trial within condition relative to first trial
% overall
rel_times_cond_starts = cellfun(@(x) minutes(x(1)-trial_times_all{1}(1)),trial_times_all,'UniformOutput',0);
%% Plot summary data
figure; 
% errorbar(mean_peaks,sem_peaks,'-ko','LineWidth',2); 
errorbar(mean_peaks,std_peaks,'-ko','LineWidth',2); 
hold on;
ax = gca;
ax.FontSize = 16; 
ax.XTick = 1:num_conditions;
ax.XTickLabel = conditions;
ax.TickLabelInterpreter = 'none';
ylabel('Peak \Delta F / F_{0}'); 
xlabel('Condition'); 
ax.XLim = [0.5 num_conditions + 0.5]; 
ax.YLim(1) = 0; 
box(ax,'off'); grid(ax,'on');
% Add time labels for each condition
text(1:num_conditions,ones(1,num_conditions)*(ax.YLim(1)+0.05*diff(ax.YLim)),...
     cellfun(@(x) sprintf('%.0f min',x),rel_times_cond_starts,'UniformOutput',0),...
     'FontSize',14); 