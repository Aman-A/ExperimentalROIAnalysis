function data_out = removeROIsExpData(data,keep_rois)
%REMOVEROISEXPDATA Remove ROIs from experimental data structure output by
%plotTrials_multipleConditions 
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
data_out = data; 
num_conditions = length(data.conditions);
data_out.baselines_all = cellfun(@(x) x(keep_rois,:,:),data_out.baselines_all,'UniformOutput',0);
data_out.deltaF_F0_all = cellfun(@(x) x(:,keep_rois,:,:),data_out.deltaF_F0_all,'UniformOutput',0);
data_out.mean_deltaF_F0_all = cellfun(@(x) x(:,keep_rois,:),data_out.mean_deltaF_F0_all,'UniformOutput',0);
data_out.peaks_deltaF_F0_all = cellfun(@(x) x(:,keep_rois,:),data_out.peaks_deltaF_F0_all,'UniformOutput',0);
data_out.deltaF_F0_aligned_all = cellfun(@(x) x(:,keep_rois,:,:),data_out.deltaF_F0_aligned_all,'UniformOutput',0);
data_out.mean_deltaF_F0_aligned_all = cellfun(@(x) x(:,keep_rois,:,:),data_out.mean_deltaF_F0_aligned_all,'UniformOutput',0);
data_out.peak_times_all = cellfun(@(x) x(:,keep_rois,:,:),data_out.peak_times_all,'UniformOutput',0);
data_out.poststim_ints_all = cellfun(@(x) x(:,keep_rois,:,:),data_out.poststim_ints_all,'UniformOutput',0);
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

data_out.successful_spikes = cellfun(@(x) x(keep_rois,:,:),data_out.successful_spikes,'UniformOutput',0);
for i = 1:num_conditions
    num_trialsi = length(data_out.rois_all{i});
    for j = 1:num_trialsi
        data_out.rois_all{i}{j} = data.rois_all{i}{j}.copy(); 
        data_out.rois_all{i}{j}.removeROIs(~keep_rois);
    end
end