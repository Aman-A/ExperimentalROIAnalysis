function [aligned_deltaF_F0s,aligned_means] = calcStimAlignedResponses(means,...
                                                    stim_frames,baseline_wind,...
                                                    stim_wind)
%CALCSTIMALIGNEDRESPONSES Aligns traces to stimulus times and computes 
%   deltaF/F using baseline preceding each stimulus
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
Nt = stim_wind + baseline_wind + 1; % number of frames/time points to include
num_traces = size(means,2); % number of separate ROIs
num_stim = length(stim_frames); % number of stimuli
aligned_means = nan(Nt,num_traces,num_stim);
for i = 1:num_stim
    framesi = (stim_frames(i)-baseline_wind):(stim_frames(i) + stim_wind);
    framesi(framesi<=0) = nan; % exclude frames before recording start
    framesi(framesi>size(means,1)) = nan; % exclude frames after recording end
    include_indsi = ~isnan(framesi);
    aligned_means(include_indsi,:,i) = means(framesi(include_indsi),:);
end
baselines = mean(aligned_means(1:baseline_wind,:,:),1); % [1 x num_traces x num_stim]
aligned_deltaF_F0s = (aligned_means - baselines)./baselines; 
% aligned_means = squeeze(aligned_means); % remove singleton dimensions
% aligned_deltaF_F0s = squeeze(aligned_deltaF_F0s); % remove singleton dimensions
end