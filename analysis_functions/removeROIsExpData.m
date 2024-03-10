function data_out = removeROIsExpData(data,exclude_rois,varargin)
%REMOVEROISEXPDATA Remove ROIs from experimental data structure output by
%plotTrials_multipleConditions 
%  
%   Inputs 
%   ------ 
%   data : structure
%          output structure of plotTrials_multipleConditions
%   exclude_rois : 1 x num_rois boolean vector or vector of integers
%               specify indices of ROIs to remove
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
% TODO: remove data from decay_fits struct, fwhm/mean_fwhm
% AUTHOR    : Aman Aberra 
in.print_level = 1; 
in = sl.in.processVarargin(in,varargin);
num_rois = data.rois_all{1}{1}.num_rois; 
keep_rois = true(1,num_rois); 
keep_rois(exclude_rois) = 0; % CHANGES BEHAVIOR OF OLD FUNCTIONS USING THIS SCRIPT
data_out = data;
if any(~keep_rois)     
    num_conditions = length(data.conditions);
    data_out.means_all = cellfun(@(x) x(:,keep_rois,:),data_out.means_all,'UniformOutput',0);
    data_out.baselines_all = cellfun(@(x) x(keep_rois,:,:),data_out.baselines_all,'UniformOutput',0);
    data_out.deltaF_F0_all = cellfun(@(x) x(:,keep_rois,:),data_out.deltaF_F0_all,'UniformOutput',0);
    data_out.mean_deltaF_F0_all = cellfun(@(x) x(:,keep_rois),data_out.mean_deltaF_F0_all,'UniformOutput',0);
    data_out.peaks_deltaF_F0_all = cellfun(@(x) x(:,keep_rois,:,:),data_out.peaks_deltaF_F0_all,'UniformOutput',0);
    data_out.deltaF_F0_aligned_all = cellfun(@(x) x(:,keep_rois,:,:),data_out.deltaF_F0_aligned_all,'UniformOutput',0);
    data_out.mean_deltaF_F0_aligned_all = cellfun(@(x) x(:,keep_rois,:),data_out.mean_deltaF_F0_aligned_all,'UniformOutput',0);
    if ~isempty(data_out.deltaF_F0_aligned2_all{1})
        data_out.deltaF_F0_aligned2_all = cellfun(@(x) x(:,keep_rois,:,:,:),data_out.deltaF_F0_aligned2_all,'UniformOutput',0);
    end
    if ~isempty(data_out.peak_times_all{1})
        data_out.peak_times_all = cellfun(@(x) x(:,keep_rois,:,:),data_out.peak_times_all,'UniformOutput',0);
    end
    if ~isempty(data_out.poststim_ints_all{1})
        data_out.poststim_ints_all = cellfun(@(x) x(:,keep_rois,:,:),data_out.poststim_ints_all,'UniformOutput',0);
    end
    if numel(data_out.mean_peaks{1}) == 1
        % recompute means/std peaks across trials from remaining ROIs
        for i = 1:num_conditions
            data_out.mean_peaks{i} = mean(data_out.peaks_deltaF_F0_all{i},1,'omitnan');
            data_out.std_peaks{i} = std(data_out.peaks_deltaF_F0_all{i},0,1,'omitnan');
            data_out.sem_peaks{i} = data_out.std_peaks{i}/sqrt(size(data_out.peaks_deltaF_F0_all{i},1));        
        end
    else
        data_out.mean_peaks = cellfun(@(x) x(keep_rois),data_out.mean_peaks,'UniformOutput',0);
        data_out.std_peaks = cellfun(@(x) x(keep_rois),data_out.std_peaks,'UniformOutput',0);
        data_out.sem_peaks = cellfun(@(x) x(keep_rois),data_out.sem_peaks,'UniformOutput',0);
    end
    if ~isempty(data_out.successful_spikes{1})
        data_out.successful_spikes = cellfun(@(x) x(keep_rois,:,:,:),data_out.successful_spikes,'UniformOutput',0);
    end
    for i = 1:num_conditions
        num_trialsi = length(data_out.rois_all{i});
        for j = 1:num_trialsi
            data_out.rois_all{i}{j} = data.rois_all{i}{j}.copy(); 
            data_out.rois_all{i}{j}.removeROIs(~keep_rois);
        end
    end
    if in.print_level > 0
        fprintf('Removed %g ROIs from %s/%s/%s (%g remaining)\n',...
                sum(~keep_rois),data_out.exp_date,data_out.reporter,data_out.dish,...
                sum(keep_rois));
    end
else
    if in.print_level > 0
        fprintf('No ROIs removed from %s/%s/%s\n',data_out.exp_date,data_out.reporter,data_out.dish)
    end
end
end