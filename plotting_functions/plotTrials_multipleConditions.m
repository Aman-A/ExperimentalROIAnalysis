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
in.plot_overlaid = 1; 
in.save_overlaid = 1;
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
    output.peaks_deltaF_F0_all{i} = concatFieldInStructArray(tdi.analysis,'peaks')'; % [num_trials x num_rois]
    % Time of peak in sec relative to first stimulus
    output.peak_times_all{i} = concatFieldInStructArray(tdi.analysis,'peak_times')';        
    output.poststim_ints_all{i} = concatFieldInStructArray(tdi.analysis,'poststim_ints')';       
    if isfield(tdi.analysis,'decay_fit')        
        output.decay_fits{i} = tdi.analysis.decay_fit;  
        output.successful_spikes{i} = tdi.analysis.successful_spikes;
        if i == num_conditions
            output.spike_thresh = tdi.analysis.spike_thresh;
            output.spike_window = tdi.analysis.spike_window; 
        end
    end    
    output.mean_peaks{i} = [tdi.analysis.mean_peak];
    output.std_peaks{i} = [tdi.analysis.std_peak];
    output.sem_peaks{i} = [tdi.analysis.sem_peak];
    output.trial_times_all{i} = tdi.trial_times;
    output.baselines_all{i} = tdi.bslines;
    output.rois_all{i} = tdi.rois_all; 
    img_names_new{i} = tdi.img_names; 
end
% peaks_deltaF_F0_all = cell2mat(peaks_deltaF_F0_all);
% get start time of first trial within condition relative to first trial
% overall
output.rel_times_cond_starts = cellfun(@(x) minutes(x(1)-output.trial_times_all{1}(1)),output.trial_times_all,'UniformOutput',0);
output.exp_date = exp_date;
output.reporter = reporter;
output.dish = dish;
output.conditions = conditions;
output.positions = positions;
output.img_names = img_names_new;
output.exp_settings = exp_settings;
output.roi_set_filenames = roi_set_filenames;
output.plot_settings = plot_settings;
if in.save_summary_data    
    roiset_filename_no_ext = getROIset_name(roi_set_filenames{1},...
                                             plot_settings.transform_type,...
                                                plot_settings.registration_rec);  
    summary_datafile = sprintf('%s_%s_%s_%s_%s',exp_date,reporter,dish,plot_settings.roi_func_mode,...
                            roiset_filename_no_ext);
    summary_data_filepath = fullfile(data_fold,exp_date,reporter,dish,summary_datafile);       
    save(summary_data_filepath,'-STRUCT','output');
    fprintf('Saved summary data to %s\n',summary_datafile);
end

if in.plot_overlaid
    if ~strcmp(plot_settings.plot_func,'none') && ~isempty(plot_settings.plot_func) ...
            && all(plot_settings.plot_func~=0) 
        summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                        ['figs_',roi_set_filenames{1} '_' plot_settings.roi_func_mode]);        
        plotExperimentTracesOverlaidGrid(output,plot_settings.plot_func,...
                                        'fig_dir',summary_fig_dir,...
                                        'save_fig',in.save_overlaid,...
                                        'y_lim',plot_settings.y_lim,...
                                        'x_lim',plot_settings.x_lim);
    end
end
end
