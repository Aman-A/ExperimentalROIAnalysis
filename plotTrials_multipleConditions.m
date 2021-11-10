function output = plotTrials_multipleConditions(data_fold,exp_date,reporter,dish,...
                                       conditions,positions,img_names,exp_settings,...
                                       roi_set_filenames,plot_settings,varargin)
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
in.save_summary_data = 1;
in = sl.in.processVarargin(in,varargin); 
num_conditions = length(conditions);
output = struct();
output.deltaF_F0_all = cell(1,num_conditions); 
output.peaks_deltaF_F0_all = cell(1,num_conditions);
output.peak_times_all = cell(1,num_conditions); % time of peak relative to stimulus (sec)
output.poststim_ints_all = cell(1,num_conditions); % integrals in post-stim window (a.u. * sec)
output.mean_peaks = cell(1,num_conditions);
output.std_peaks = cell(1,num_conditions);
output.sem_peaks = cell(1,num_conditions);
output.trial_times_all = cell(1,num_conditions);
output.baselines_all = cell(1,num_conditions); 
output.rois_all = cell(1,num_conditions); 
for i = 1:num_conditions
    condition = conditions{i};
    roi_set_filename = roi_set_filenames{i};
    position = positions{i};
    % trial data for ith condition
    tdi = plotTrials(data_fold,exp_date,reporter,dish,condition,position,img_names{i},...
                              exp_settings,roi_set_filename,plot_settings);    
    output.deltaF_F0_all{i} = tdi.deltaF_F0;    
    output.peaks_deltaF_F0_all{i} = tdi.peaks_deltaF_F0;
    if strcmp(plot_settings.roi_func_mode,'combine')        
        [~,pk_inds] = max(tdi.deltaF_F0(exp_settings.stim_wind_inds,:),[],1);
        % Time of peak in sec relative to first stimulus
        output.peak_times_all{i} = exp_settings.convert2Time(exp_settings.stim_wind_inds(pk_inds) - exp_settings.stim_vals(1));
        output.poststim_ints_all{i} = (1/exp_settings.sampling_rate)*...
                                      trapz(tdi.deltaF_F0(exp_settings.stim_wind_inds,:));        
    else
        [~,pk_inds] = cellfun(@(x) max(x(exp_settings.stim_wind_inds,:),[],1),...
                              tdi.deltaF_F0,'UniformOutput',0);
        pk_inds = cell2mat(pk_inds'); % [ num_trials x num_rois]
        output.peak_times_all{i} = exp_settings.convert2Time(exp_settings.stim_wind_inds(pk_inds)-exp_settings.stim_vals(1));
        output.poststim_ints_all{i} = cell2mat(cellfun(@(x) (1/exp_settings.sampling_rate)*...
                                        trapz(x(exp_settings.stim_wind_inds,:)),...
                                        tdi.deltaF_F0,'UniformOutput',0)');        
    end
    output.mean_peaks{i} = tdi.mean_peak_deltaF_F0;
    output.std_peaks{i} = tdi.std_peak_deltaF_F0;
    output.sem_peaks{i} = tdi.std_peak_deltaF_F0/sqrt(length(tdi.peaks_deltaF_F0));
    output.trial_times_all{i} = tdi.trial_times;
    output.baselines_all{i} = tdi.bslines;
    output.rois_all{i} = tdi.rois_all; 
end
% peaks_deltaF_F0_all = cell2mat(peaks_deltaF_F0_all);
% get start time of first trial within condition relative to first trial
% overall
output.rel_times_cond_starts = cellfun(@(x) minutes(x(1)-output.trial_times_all{1}(1)),output.trial_times_all,'UniformOutput',0);
if in.save_summary_data
    if strcmp(plot_settings.transform_type,'displace')
        [~,reg_rec_name,~] = fileparts(plot_settings.registration_rec); 
        summary_data_file = sprintf('%s_%s_%s_%s_%s_%s_displace.mat',exp_date,...
                                    reporter,dish,plot_settings.roi_func_mode,...
                                    roi_set_filenames{1},reg_rec_name);
    else
        summary_data_file = sprintf('%s_%s_%s_%s_%s.mat',exp_date,reporter,dish,...
                                                      plot_settings.roi_func_mode,...
                                                      roi_set_filenames{1});
    end
    summary_data_filepath = fullfile(data_fold,exp_date,reporter,dish,summary_data_file);
    save(summary_data_filepath,'output','exp_date','reporter','dish','conditions',...
                           'positions','img_names','exp_settings',...
                           'roi_set_filenames','plot_settings');
    fprintf('Saved summary data to %s\n',summary_data_file);
end
end
