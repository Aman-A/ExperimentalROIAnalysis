function [aligned_deltaF_F0s,aligned_means] = calcStimAlignedResponses(means,...
                                                    stim_frames,baseline_wind,...
                                                    stim_wind)
%CALCSTIMALIGNEDRESPONSES Aligns traces to stimulus times and computes 
%   deltaF/F using baseline preceding each stimulus
%  
%   Inputs 
%   ------ 
%   means : num_frames x num_traces array
%           mean fluorescence (or other data) values at each time point
%   stim_frames : num_trains x num_stim array 
%                 Frames at which stimuli applied. For single stimulus
%                 train, should be 1D row vector
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
num_traces = size(means,2); % number of separate ROIs
if isvector(stim_frames)
    num_stim = length(stim_frames); % number of stimuli
    num_trains = 1; % number of pulse trains
else
    num_stim = size(stim_frames,2); % number of stimuli
    num_trains = size(stim_frames,1); % number of pulse trains
end
if num_trains == 1 % align to individual stimuli
    Nt = stim_wind + baseline_wind + 1; % number of frames/time points to include
    aligned_means = nan(Nt,num_traces,num_stim);
    for j = 1:num_stim
        framesij = (stim_frames(j)-baseline_wind):(stim_frames(j) + stim_wind);
        framesij(framesij<=0) = nan; % exclude frames before recording start
        framesij(framesij>size(means,1)) = nan; % exclude frames after recording end
        include_indsi = ~isnan(framesij);
        aligned_means(include_indsi,:,j) = means(framesij(include_indsi),:);
    end
else % align to stim trains
    Nt = baseline_wind + stim_frames(1,end)-stim_frames(1,1) + stim_wind +  1; % number of frames/time points to include
    aligned_means = nan(Nt,num_traces,num_trains);
    for j = 1:num_trains
        % extract frames from baseline_wind before 1st stim to stim_wind
        % after last stim within train
        framesij = (stim_frames(j,1)-baseline_wind):(stim_frames(j,end) + stim_wind);
        framesij(framesij<=0) = nan; % exclude frames before recording start
        framesij(framesij>size(means,1)) = nan; % exclude frames after recording end
        include_indsi = ~isnan(framesij);
        aligned_means(include_indsi,:,j) = means(framesij(include_indsi),:);
    end
end

baselines = mean(aligned_means(1:baseline_wind,:,:),1); % [1 x num_traces x num_stim or num_trains]
aligned_deltaF_F0s = (aligned_means - baselines)./baselines; 
% aligned_means = squeeze(aligned_means); % remove singleton dimensions
% aligned_deltaF_F0s = squeeze(aligned_deltaF_F0s); % remove singleton dimensions
end