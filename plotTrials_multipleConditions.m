function output = plotTrials_multipleConditions(data_fold,exp_date,reporter,dish,...
                                       conditions,positions,img_names,exp_settings,...
                                       roi_set_filenames,plot_settings)
%PLOTTRIALS_MULTIPLECONDITIONS ... 
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

num_conditions = length(conditions);
output = struct();
output.deltaF_F0_all = cell(1,num_conditions); 
output.peaks_deltaF_F0_all = cell(1,num_conditions);
output.peak_times_all = cell(1,num_conditions); % time of peak relative to stimulus (sec)
output.poststim_ints_all = cell(1,num_conditions); % integrals in post-stim window (a.u. * sec)
output.mean_peaks = zeros(1,num_conditions);
output.std_peaks = zeros(1,num_conditions);
output.sem_peaks = zeros(1,num_conditions);
output.trial_times_all = cell(1,num_conditions);
output.baselines_all = cell(1,num_conditions); 
for i = 1:num_conditions
    condition = conditions{i};
    roi_set_filename = roi_set_filenames{i};
    position = positions{i};
    [deltaF_F0,peaks_deltaF_F0,mean_peak_deltaF_F0,std_peak_deltaF_F0,trial_times,bslines] = ...
        plotTrials(data_fold,exp_date,reporter,dish,condition,position,img_names{i},...
                exp_settings,roi_set_filename,plot_settings);
    output.deltaF_F0_all{i} = deltaF_F0; 
    output.peaks_deltaF_F0_all{i} = peaks_deltaF_F0;
    [~,pk_inds] = max(deltaF_F0(exp_settings.stim_wind_inds,:),[],1);
    output.peak_times_all{i} = pk_inds/exp_settings.sampling_rate;
    output.poststim_ints_all{i} = trapz(exp_settings.stim_wind/exp_settings.sampling_rate,...
                                deltaF_F0(exp_settings.stim_wind_inds,:));
    output.mean_peaks(i) = mean_peak_deltaF_F0;
    output.std_peaks(i) = std_peak_deltaF_F0;
    output.sem_peaks(i) = std_peak_deltaF_F0/sqrt(length(peaks_deltaF_F0));
    output.trial_times_all{i} = trial_times;
    output.baselines_all{i} = bslines;
end
% peaks_deltaF_F0_all = cell2mat(peaks_deltaF_F0_all);
% get start time of first trial within condition relative to first trial
% overall
output.rel_times_cond_starts = cellfun(@(x) minutes(x(1)-output.trial_times_all{1}(1)),output.trial_times_all,'UniformOutput',0);

end
