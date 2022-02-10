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
% Data compiled across trials and conditions in output struct
output = struct();
output.deltaF_F0_all = cell(1,num_conditions); 
output.mean_deltaF_F0_all = cell(1,num_conditions); 
output.peaks_deltaF_F0_all = cell(1,num_conditions);
output.deltaF_F0_aligned_all = cell(1,num_conditions); 
output.mean_deltaF_F0_aligned_all= cell(1,num_conditions);
output.peak_times_all = cell(1,num_conditions); % time of peak relative to stimulus (sec)
output.poststim_ints_all = cell(1,num_conditions); % integrals in post-stim window (a.u. * sec)
output.mean_peaks = cell(1,num_conditions);
output.std_peaks = cell(1,num_conditions);
output.sem_peaks = cell(1,num_conditions);
output.decay_fits = cell(1,num_conditions);
output.successful_spikes = cell(1,num_conditions);
output.trial_times_all = cell(1,num_conditions);
output.baselines_all = cell(1,num_conditions); 
output.rois_all = cell(1,num_conditions); 
% Update img_names with img_names loaded in plotTrials
img_names_new = cell(size(img_names)); 
for i = 1:num_conditions    
    roi_set_filename = roi_set_filenames{i};
    plot_settings.condition = conditions{i};
    plot_settings.position = positions{i};
    % trial data for ith condition
    tdi = plotTrials(img_names{i},exp_settings,roi_set_filename,plot_settings);    
    output.deltaF_F0_all{i} = tdi.deltaF_F0;    
    output.mean_deltaF_F0_all{i} = tdi.mean_deltaF_F0;    
    if isfield(tdi,'deltaF_F0_aligned')
        output.deltaF_F0_aligned_all{i} = tdi.deltaF_F0_aligned;
        output.mean_deltaF_F0_aligned_all{i} = tdi.mean_deltaF_F0_aligned;
    end
    output.peaks_deltaF_F0_all{i} = tdi.analysis.peaks;
    % Time of peak in sec relative to first stimulus
    output.peak_times_all{i} = tdi.analysis.peak_times;        
    output.poststim_ints_all{i} = tdi.analysis.poststim_ints;   
    output.decay_fits{i} = tdi.analysis.decay_fit;  
    if isfield(tdi.analysis,'decay_fit')        
        output.successful_spikes{i} = tdi.analysis.successful_spikes;
        if i == num_conditions
            output.spike_thresh = tdi.analysis.spike_thresh;
        end
    end    
    output.mean_peaks{i} = tdi.analysis.mean_peak;
    output.std_peaks{i} = tdi.analysis.std_peak;
    output.sem_peaks{i} = tdi.analysis.sem_peak;
    output.trial_times_all{i} = tdi.trial_times;
    output.baselines_all{i} = tdi.bslines;
    output.rois_all{i} = tdi.rois_all; 
    img_names_new{i} = tdi.img_names; 
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
    summary_data = struct(); 
    summary_data.output = output;
    summary_data.exp_date = exp_date;
    summary_data.reporter = reporter;
    summary_data.dish = dish;
    summary_data.conditions = conditions;
    summary_data.positions = positions;
    summary_data.img_names = img_names_new;
    summary_data.exp_settings = exp_settings;
    summary_data.roi_set_filenames = roi_set_filenames;
    summary_data.plot_settings = plot_settings;
    save(summary_data_filepath,'-STRUCT','summary_data');
    fprintf('Saved summary data to %s\n',summary_data_file);
end
end
