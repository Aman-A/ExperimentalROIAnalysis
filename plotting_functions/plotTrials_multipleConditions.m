function out = plotTrials_multipleConditions(conditions,plot_settings,exp_settings,...
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
out = struct();
out.conditions = conditions;
out.means_all = cell(1,num_conditions); 
out.deltaF_F0_all = cell(1,num_conditions); 
out.mean_deltaF_F0_all = cell(1,num_conditions); 
out.peaks_deltaF_F0_all = cell(1,num_conditions);
out.deltaF_F0_aligned_all = cell(1,num_conditions); 
out.deltaF_F0_aligned2_all = cell(1,num_conditions); 
out.mean_deltaF_F0_aligned_all= cell(1,num_conditions);
out.peak_times_all = cell(1,num_conditions); % time of peak relative to stimulus (sec)
out.poststim_ints_all = cell(1,num_conditions); % integrals in post-stim window (a.u. * sec)
out.mean_peaks = cell(1,num_conditions);
out.std_peaks = cell(1,num_conditions);
out.sem_peaks = cell(1,num_conditions);
out.decay_fits = cell(1,num_conditions);
out.fwhm = cell(1,num_conditions);
out.mean_fwhm = cell(1,num_conditions);
out.successful_spikes = cell(1,num_conditions);
out.trial_times_all = cell(1,num_conditions);
out.baselines_all = cell(1,num_conditions); 
out.rois_all = cell(1,num_conditions); 
out.imgs_all = cell(1,num_conditions);
% Update img_names with img_names loaded in plotTrials
img_names_new = cell(size(in.img_names)); 
if ischar(roiset_filenames) || ~iscell(roiset_filenames)
    roiset_filenames = repmat({roiset_filenames},1,num_conditions);
elseif iscell(roiset_filenames)
    if length(roiset_filenames) == 1
        roiset_filenames = repmat(roiset_filenames,1,num_conditions);
    elseif length(roiset_filenames) ~= num_conditions
        error('Number of roiset_filenames should match number of conditions'); 
    end
end
% Format exp_settings
if length(exp_settings) == 1
    exp_settings_all = repmat(exp_settings,num_conditions,1); % convert to object array
    sep_trial_settings = 0; % same settings for all conditions/trials
elseif length(exp_settings) == num_conditions
    exp_settings_all = exp_settings;
    sep_trial_settings = 0; % same settings for all trials within condition
else
    % each exp_settings array applies to trials of each condition    
    if ~iscell(exp_settings) % replicate object array for each condition 
        exp_settings_all = cell(1,num_conditions);
        exp_settings_all(:) = {exp_settings};
    else % already cell array of object arrays (or single object)
        exp_settings_all = exp_settings;
    end
    sep_trial_settings = 1; % separate settings for all trials and each condition
end

for i = 1:num_conditions    
    if sep_trial_settings
        exp_settingsi = exp_settings_all{i}; 
    else 
        exp_settingsi = exp_settings_all(i); 
    end
    roiset_filename = roiset_filenames{i};
    plot_settings.condition = conditions{i};    
    % trial data for ith condition
    tdi = plotTrials(in.img_names{i},exp_settingsi,roiset_filename,plot_settings);    
    if isempty(tdi); continue; end
    out.means_all{i} = tdi.means;    
    out.deltaF_F0_all{i} = tdi.deltaF_F0;    
    out.mean_deltaF_F0_all{i} = tdi.mean_deltaF_F0;    
    if isfield(tdi,'deltaF_F0_aligned')
        out.deltaF_F0_aligned_all{i} = tdi.deltaF_F0_aligned;
        out.mean_deltaF_F0_aligned_all{i} = tdi.mean_deltaF_F0_aligned;
    end
    if isfield(tdi,'deltaF_F0_aligned2')
        out.deltaF_F0_aligned2_all{i} = tdi.deltaF_F0_aligned2;        
    end
    % Output metrics with dimensions: [num_stim x num_rois x num_trials]
    if isfield(tdi.analysis,'peaks')
        out.peaks_deltaF_F0_all{i} = permute(concatFieldInStructArray(tdi.analysis,'peaks'),[2 1 3 4]);         
        % Time of peak in sec relative to first stimulus
        out.peak_times_all{i} = permute(concatFieldInStructArray(tdi.analysis,'peak_times'),[2 1 3 4]);    
        out.mean_peaks{i} = [tdi.analysis.mean_peak];
        out.std_peaks{i} = [tdi.analysis.std_peak];
        out.sem_peaks{i} = [tdi.analysis.sem_peak];
    end    
    if isfield(tdi.analysis,'poststim_ints') 
        out.poststim_ints_all{i} = permute(concatFieldInStructArray(tdi.analysis,'poststim_ints'),[2 1 3 4]);       
    end
    if isfield(tdi.analysis,'decay_fit')
        out.decay_fits{i} = tdi.analysis.decay_fit;
    end
    if isfield(tdi.analysis,'successful_spikes')    
        out.successful_spikes{i} = tdi.analysis.successful_spikes;
        if i == num_conditions
            out.spike_thresh = tdi.analysis.spike_thresh;
            out.spike_window = tdi.analysis.spike_window; 
        end
    end    
    if isfield(tdi.analysis,'fwhm')
        out.fwhm{i} = tdi.analysis.fwhm;
    end
    if isfield(tdi.analysis,'mean_fwhm')
        out.mean_fwhm{i} = tdi.analysis.mean_fwhm;
    end    
    out.trial_times_all{i} = tdi.trial_times;
    % out.baselines_all{i} = tdi.bslines;
    out.baselines_all{i} = permute(tdi.bslines,[2 1 3 4]);
    out.rois_all{i} = tdi.rois_all; 
    img_names_new{i} = tdi.img_names; 
    out.imgs_all{i} = tdi.imgs;
end
% peaks_deltaF_F0_all = cell2mat(peaks_deltaF_F0_all);
% get start time of first trial within condition relative to first trial
% overall
out = removeEmptyConditions(out);
out.rel_times_cond_starts = cellfun(@(x) minutes(x(1)-out.trial_times_all{1}(1)),...
                                out.trial_times_all,'UniformOutput',0);
out.exp_date = plot_settings.exp_date;
out.reporter = plot_settings.reporter;
out.dish = plot_settings.dish;
out.img_names = img_names_new;
out.exp_settings = exp_settings_all;
out.roi_set_filenames = roiset_filenames;
out.plot_settings = plot_settings;
if iscell(roiset_filenames{1})
    roiset_filename = roiset_filenames{1}{1};
else
    roiset_filename = roiset_filenames{1};
end
out.roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                             plot_settings.transform_type,...
                                                plot_settings.registration_rec);  
out.imgs_all = cellfun(@cell2mat,out.imgs_all,'UniformOutput',0);
if in.save_summary_data    
    if isempty(in.summary_datafile)
        summary_datafile = sprintf('%s_%s_%s_%s_%s',plot_settings.exp_date,...
                                    plot_settings.reporter,plot_settings.dish,...
                                    plot_settings.roi_func_mode,...
                                    out.roiset_filename_no_ext);
    else
        summary_datafile = in.summary_datafile; 
    end
    summary_data_filepath = fullfile(plot_settings.data_fold,plot_settings.exp_date,...
                                     plot_settings.reporter,plot_settings.dish,...
                                     [summary_datafile '.mat']);       
    save(summary_data_filepath,'-STRUCT','out');
    fprintf('Saved summary data to %s\n',summary_datafile);
end

if in.plot_overlaid
    if ~strcmp(plot_settings.plot_func,'none') && ~isempty(plot_settings.plot_func) ...
            && all(plot_settings.plot_func~=0) 
        if isempty(in.summary_fig_dir)
            summary_fig_dir = fullfile(plot_settings.data_fold,...
                                        plot_settings.exp_date,plot_settings.reporter,...
                                        plot_settings.dish,...
                                        ['figs_',plot_settings.reporter, '_',...
                                        out.roiset_filename_no_ext '_' ...
                                           plot_settings.roi_func_mode]);        
        else
            summary_fig_dir = in.summary_fig_dir;
        end
        if strcmp(plot_settings.roi_func_mode,'combine')
            y_lim = plot_settings.y_lim;
        else
            y_lim = []; % y_lim applies to shifted traces, instead use auto limits by default
        end
        plotExperimentTracesOverlaidGrid(out,plot_settings.plot_func,...
                                        'fig_dir',summary_fig_dir,...
                                        'save_fig',in.save_overlaid,...
                                        'y_lim',y_lim,...
                                        'x_lim',plot_settings.x_lim,...
                                        'norm_peak_ind',0);
    end
end
end
function out = removeEmptyConditions(out)
    valid_conditions = ~cellfun(@isempty,out.trial_times_all,'UniformOutput',1);
    out_fields = fieldnames(out);    
    if any(~valid_conditions)
        fprintf('Removing invalid conditions:\n')
        fprintf([repmat('%s ',1,sum(~valid_conditions)),'\n'],out.conditions{~valid_conditions})
        for i = 1:length(out_fields)
             if iscell(out.(out_fields{i}))                
                out.(out_fields{i}) = out.(out_fields{i})(valid_conditions);
             end
        end
    end
end
