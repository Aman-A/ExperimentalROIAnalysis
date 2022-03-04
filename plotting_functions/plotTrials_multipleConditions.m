function output = plotTrials_multipleConditions(conditions,plot_settings,exp_settings,...
                                                roiset_filenames,varargin)
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
in.img_names = cell(1,num_conditions); % default load all recordings within condition folders
in.save_summary_data = 1;
in.summary_fig_dir = ''; % set automatically below
in.summary_datafile = ''; % set automatically below
in.plot_overlaid = 1; 
in.save_overlaid = 1;
in = sl.in.processVarargin(in,varargin); 
% Data compiled across trials and conditions in output struct
output = struct();
output.conditions = conditions;
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
output.fwhm = cell(1,num_conditions);
output.mean_fwhm = cell(1,num_conditions);
output.successful_spikes = cell(1,num_conditions);
output.trial_times_all = cell(1,num_conditions);
output.baselines_all = cell(1,num_conditions); 
output.rois_all = cell(1,num_conditions); 
% Update img_names with img_names loaded in plotTrials
img_names_new = cell(size(in.img_names)); 
if ischar(roiset_filenames) || ~iscell(roiset_filenames)
    roiset_filenames = repmat({roiset_filenames},1,num_conditions);
elseif iscell(roiset_filenames)
    if length(roiset_filenames) == 1
        roiset_filenames = repmat(roiset_filenames,1,num_trials);
    else
        error('Number of roiset_filenames should match number of conditions'); 
    end
end
for i = 1:num_conditions    
    roiset_filename = roiset_filenames{i};
    plot_settings.condition = conditions{i};    
    % trial data for ith condition
    tdi = plotTrials(in.img_names{i},exp_settings,roiset_filename,plot_settings);    
    output.deltaF_F0_all{i} = tdi.deltaF_F0;    
    output.mean_deltaF_F0_all{i} = tdi.mean_deltaF_F0;    
    if isfield(tdi,'deltaF_F0_aligned')
        output.deltaF_F0_aligned_all{i} = tdi.deltaF_F0_aligned;
        output.mean_deltaF_F0_aligned_all{i} = tdi.mean_deltaF_F0_aligned;
    end
    % Output metrics with dimensions: [num_stim x num_rois x num_trials]
    output.peaks_deltaF_F0_all{i} = permute(concatFieldInStructArray(tdi.analysis,'peaks'),[2 1 3 4]); 
    % Time of peak in sec relative to first stimulus
    output.peak_times_all{i} = permute(concatFieldInStructArray(tdi.analysis,'peak_times'),[2 1 3 4]);    
    if isfield(tdi.analysis,'poststim_ints') 
        output.poststim_ints_all{i} = permute(concatFieldInStructArray(tdi.analysis,'poststim_ints'),[2 1 3 4]);       
    end
    if isfield(tdi.analysis,'decay_fit')        
        output.decay_fits{i} = tdi.analysis.decay_fit;  
        output.successful_spikes{i} = tdi.analysis.successful_spikes;
        if i == num_conditions
            output.spike_thresh = tdi.analysis.spike_thresh;
            output.spike_window = tdi.analysis.spike_window; 
        end
    end    
    if isfield(tdi.analysis,'fwhm')
        output.fwhm{i} = tdi.analysis.fwhm;
    end
    if isfield(tdi.analysis,'mean_fwhm')
        output.mean_fwhm{i} = tdi.analysis.mean_fwhm;
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
output.exp_date = plot_settings.exp_date;
output.reporter = plot_settings.reporter;
output.dish = plot_settings.dish;
output.img_names = img_names_new;
output.exp_settings = exp_settings;
output.roi_set_filenames = roiset_filenames;
output.plot_settings = plot_settings;
output.roiset_filename_no_ext = getROIset_name(roiset_filenames{1},...
                                             plot_settings.transform_type,...
                                                plot_settings.registration_rec);  
if in.save_summary_data    
    if isempty(in.summary_datafile)
        summary_datafile = sprintf('%s_%s_%s_%s_%s',plot_settings.exp_date,...
                                    plot_settings.reporter,plot_settings.dish,...
                                    plot_settings.roi_func_mode,...
                                    output.roiset_filename_no_ext);
    else
        summary_datafile = in.summary_datafile; 
    end
    summary_data_filepath = fullfile(plot_settings.data_fold,plot_settings.exp_date,...
                                     plot_settings.reporter,plot_settings.dish,...
                                     summary_datafile);       
    save(summary_data_filepath,'-STRUCT','output');
    fprintf('Saved summary data to %s\n',summary_datafile);
end

if in.plot_overlaid
    if ~strcmp(plot_settings.plot_func,'none') && ~isempty(plot_settings.plot_func) ...
            && all(plot_settings.plot_func~=0) 
        if isempty(in.summary_fig_dir)
            summary_fig_dir = fullfile(plot_settings.data_fold,...
                                        plot_settings.exp_date,plot_settings.reporter,...
                                        plot_settings.dish,...
                                        ['figs_',output.roiset_filename_no_ext '_' ...
                                           plot_settings.roi_func_mode]);        
        else
            summary_fig_dir = in.summary_fig_dir;
        end
        plotExperimentTracesOverlaidGrid(output,plot_settings.plot_func,...
                                        'fig_dir',summary_fig_dir,...
                                        'save_fig',in.save_overlaid,...
                                        'y_lim',plot_settings.y_lim,...
                                        'x_lim',plot_settings.x_lim,...
                                        'norm_peak_ind',0);
    end
end
end
