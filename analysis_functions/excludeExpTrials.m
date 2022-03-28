function [data_out,keep_rois] = excludeExpTrials(data,trial_criteria,roi_criteria,varargin)
%EXCLUDEEXPTRIALS Applies several exclusion criteria to remove trials
%and/or ROIs from dataset (output of plotTrials_multipleConditions)
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
% trial_criteria
% Remove trials with baseline > x*std(all baselines) in that ROI
% Remove trials with peak < x*mean(baseline) (SNR criterion)
% roi_criteria
% Remove ROIs with peak response in wash < x*control peak
% Remove ROIs with post-stim integral response in wash < x*post-stim
% integral
% Remove ROIs with post-stim decay tau in wash < x*post-stim decay tau
in.print_level = 2;
in = sl.in.processVarargin(in,varargin);
conditions = data.conditions;
num_conditions = length(conditions);
num_rois = data.rois_all{1}{1}.num_rois;
keep_rois = ones(1,num_rois);
wash_ind = strcmp(conditions,'wash');
control_ind = strcmp(conditions,'control');
data_out = data; 
if in.print_level > 0
    fprintf('****APPLYING EXCLUSION CRITERIA TO %s/%s/%s\n',...
            data.exp_date,data.reporter,data.dish);
end
% Exclude specific trials
if ~isempty(trial_criteria)    
    baselines_all = data.baselines_all; 
    baselines_all_mat = cell2mat(baselines_all); 
    mean_baselines = mean(baselines_all_mat,2); % mean across all trials
    std_baselines = std(baselines_all_mat,0,2); % std across all trials        
    for i = 1:num_conditions        
        num_trialsi = size(baselines_all{i},2);
        for k = 1:num_rois            
            if isfield(trial_criteria,'baseline_std_thresh')
                % exclude trials with baseline - mean(baseline) >= baseline_std_thresh*std(all baselines from ROI)
                % over baseline_std_thresh std from mean of all baselines in ROI
                excl_trialsik1 = abs(baselines_all{i}(k,:) - mean_baselines(k)) >= ...
                            trial_criteria.baseline_std_thresh*std_baselines(k);
                if any(excl_trialsik1)
                    if in.print_level > 1
                        fprintf('%s: Removing %g trials from ROI %g with mean baseline outside %.1f x STD\n',...
                              conditions{i}, sum(excl_trialsik1),k,trial_criteria.baseline_std_thresh);
                    end
                end
            else
                excl_trialsik1 = zeros(1,num_trialsi);
            end
            if isfield(trial_criteria,'snr_thresh') % TODO: FIX THIS 
                % Exclude trials with peak response <
                % snr_thresh*mean(baseline) within trial
                excl_trialsik2 = data_out.peaks_deltaF_F0_all{i}(:,k) < ...
                    trial_criteria.snr_thresh*baselines_all{i}(k,:)';                
                if any(excl_trialsik2)
                    if in.print_level > 1
                        fprintf('%s: Removing %g trials from ROI %g with SNR below threshold\n',...
                            conditions{i},sum(excl_trialsik2),k);
                    end
                end
            else
                excl_trialsik2 = zeros(1,num_trialsi);
            end
            excl_trialsik = excl_trialsik1 | excl_trialsik2;
            if sum(excl_trialsik) > length(excl_trialsik)/2 
                % mark ROI for removal if less than half trials remaining
                % in this condition
                keep_rois(k) = 0; 
                if in.print_level > 1
                    fprintf('Removing ROI %g, only %g trials remaining in condition %s\n',k,sum(excl_trialsik),conditions{i});
                end
            end
            data_out.deltaF_F0_all{i}(:,k,excl_trialsik) = nan;                        
            data_out.deltaF_F0_aligned_all{i}(:,k,excl_trialsik) = nan;
            data_out.peaks_deltaF_F0_all{i}(excl_trialsik,k) = nan;
            data_out.peak_times_all{i}(excl_trialsik,k) = nan;
            data_out.poststim_ints_all{i}(excl_trialsik,k) = nan;
            data_out.successful_spikes{i}(k,excl_trialsik) = nan;
        end
        % recompute means
        data_out.mean_deltaF_F0_all{i} = mean(data_out.deltaF_F0_all{i},3,'omitnan');
        data_out.mean_deltaF_F0_aligned_all{i} = mean(data_out.deltaF_F0_aligned_all{i},3,'omitnan');
        data_out.mean_peaks{i} = mean(data_out.peaks_deltaF_F0_all{i},1,'omitnan');
        data_out.std_peaks{i} = std(data_out.peaks_deltaF_F0_all{i},0,1,'omitnan');
        data_out.sem_peaks{i} = data_out.std_peaks{i}/sqrt(size(data_out.peaks_deltaF_F0_all{i},1));        
    end
end
% Exclude all trials from specific ROIs
if isfield(roi_criteria,'wash_rel_control_mean_peak')
    % exclude ROIs with wash mean peak < wash_rel_control_mean_peak*control
    %    
    mean_control_peaks = mean(data.peaks_deltaF_F0_all{control_ind},1); % trial average
    mean_wash_peaks = mean(data.peaks_deltaF_F0_all{wash_ind},1); 
    keep_rois1 = mean_wash_peaks >= mean_control_peaks*roi_criteria.wash_rel_control_mean_peak; 
    if in.print_level > 1
        fprintf('wash_rel_control_mean_peak: Removing %g ROIs\n',sum(~keep_rois1));
    end
%     figure; plot(mean_wash_peaks./mean_control_peaks); hold on; 
%     plot([1,length(keep_rois1)],roi_criteria.wash_rel_control_mean_peak*[1 1],'--k');
else
    keep_rois1 = ones(size(keep_rois));
end
if isfield(roi_criteria,'wash_rel_control_mean_int')
    % exclude ROIs with wash mean integral < wash_rel_control_mean_int*control    
    mean_control_ints = mean(data.poststim_ints_all{control_ind},1); % trial average
    mean_wash_ints = mean(data.poststim_ints_all{wash_ind},1);     
    keep_rois2 = mean_wash_ints >= mean_control_ints*roi_criteria.wash_rel_control_mean_peak; 
    if in.print_level > 1
        fprintf('wash_rel_control_mean_int: Removing %g ROIs\n',sum(~keep_rois2));
    end
%     figure; plot(mean_wash_ints./mean_control_ints); hold on; 
%     plot([1,length(keep_rois1)],roi_criteria.wash_rel_control_mean_peak*[1 1],'--k');
else
    keep_rois2 = ones(size(keep_rois));
end
if isfield(roi_criteria,'wash_rel_control_baseline')
    % exclude ROIs with wash baseline relative difference > wash_rel_control_baseline    
    mean_control_baseline = mean(data.baselines_all{control_ind},2)'; % trial average
    mean_wash_baseline = mean(data.baselines_all{wash_ind},2)'; 
    keep_rois3 = abs((mean_wash_baseline-mean_control_baseline)./mean_control_baseline) ...
                < roi_criteria.wash_rel_control_baseline; 
    if in.print_level > 1
        fprintf('wash_rel_control_baseline: Removing %g ROIs\n',sum(~keep_rois3));
    end
%     figure; plot(abs((mean_wash_baseline-mean_control_baseline)./mean_control_baseline)); hold on;     
%     plot([1,length(keep_rois1)],roi_criteria.wash_rel_control_baseline*[1 1],'--k');
else
    keep_rois3 = ones(size(keep_rois));
end
keep_rois = keep_rois & keep_rois1 & keep_rois2 & keep_rois3; 
if in.print_level > 0
    fprintf('Excluding %g/%g ROIs based on all criteria:\n',sum(~keep_rois),length(keep_rois));
    if sum(~keep_rois) > 0
        fprintf('%g, ',find(~keep_rois))
        fprintf('\n');
    end
end
data_out = removeROIsExpData(data_out,keep_rois);
end