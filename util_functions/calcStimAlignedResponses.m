function out = calcStimAlignedResponses(means,stim_frames,baseline_wind,...
                                        stim_wind,varargin)
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
%   bsline_wind : 1 x 2 integer vector or indices
%                   Specify frames to take baseline over, either start and end
%                   or all frames as a vector (from ExperimentSettings
%                   object)
%   stim_vals : 1 x num_stim vector of stim times or frames 
%               (from ExperimentSettings object)

%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   out : struct
%   Contains fields:
%       deltaF_F0_aligned : num_frames x num_traces x num_stim (or
%       num_train) array
%       mean_aligned : num_frames x num_traces x num_stim (or num_train
%       array)
%   (If num_trains > 1 and use_train_baseline=1:
%       deltaF_F0_aligned2 : num_frames x num_traces x num_train x num_stim
%       array
%       mean_aligned2 : num_frames x num_traces x num_train x num_stim
%       array
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.align_spikes_and_trains = 1; % if num_trains > 1 also output array with 
                                % individual stimuli aligned
in.use_train_baseline = 1; % for individual alignment of stim responses 
                           % within train, set to 1 to use baseline from 
                           % 1st stim in train or 0 to use individual stim
                           % baselines
in = sl.in.processVarargin(in,varargin);
num_traces = size(means,2); % number of separate ROIs
if isvector(stim_frames)
    num_stim = length(stim_frames); % number of stimuli
    num_trains = 1; % number of pulse trains
else
    num_stim = size(stim_frames,2); % number of stimuli   
    num_trains = size(stim_frames,1); % number of pulse trains
end
out = struct(); 
if isempty(stim_frames)
    return;
end
% Multi-train stimuli, align to train
if num_trains > 1
    Nt = baseline_wind + stim_frames(1,end)-stim_frames(1,1) + stim_wind +  1; % number of frames/time points to include
    mean_aligned = nan(Nt,num_traces,num_trains);
    for j = 1:num_trains
        % extract frames from baseline_wind before 1st stim to stim_wind
        % after last stim within train
        framesj = (stim_frames(j,1)-baseline_wind):(stim_frames(j,end) + stim_wind);
        framesj(framesj<=0) = nan; % exclude frames before recording start
        framesj(framesj>size(means,1)) = nan; % exclude frames after recording end
        include_indsi = ~isnan(framesj);
        mean_aligned(include_indsi,:,j) = means(framesj(include_indsi),:);
    end
    baselines = mean(mean_aligned(1:baseline_wind,:,:),1,'omitnan'); % [1 x num_traces x num_stim or num_trains]
    deltaF_F0_aligned = (mean_aligned - baselines)./baselines; 
    
    if in.align_spikes_and_trains % also align to individual stimuli
        Nt = stim_wind + baseline_wind + 1; % number of frames/time points to include
        mean_aligned2 = nan(Nt,num_traces,num_trains,num_stim); 
        for i = 1:num_trains
            for j = 1:num_stim
                framesij = (stim_frames(i,j)-baseline_wind):(stim_frames(i,j) + stim_wind);
                framesij(framesij<=0) = nan; % exclude frames before recording start
                framesij(framesij>size(means,1)) = nan; % exclude frames after recording end
                include_indsij = ~isnan(framesij);
                mean_aligned2(include_indsij,:,i,j) = means(framesij(include_indsij),:);
            end
        end
        baselines2 = mean(mean_aligned2(1:baseline_wind,:,:,:),1,'omitnan'); % [1 x num_traces x num_trains x num_stim]
        if in.use_train_baseline
            deltaF_F0_aligned2 = (mean_aligned2 - baselines2(:,:,:,1))./baselines2(:,:,:,1); 
        else
            deltaF_F0_aligned2 = (mean_aligned2 - baselines2)./baselines2; 
        end
        out.deltaF_F0_aligned2 = deltaF_F0_aligned2;
        out.mean_aligned2 = mean_aligned2; 
        out.baselines2 = baselines2;         
    end
else % Align all individual spikes 
    Nt = stim_wind + baseline_wind + 1; % number of frames/time points to include
    mean_aligned = nan(Nt,num_traces,num_stim);
    for j = 1:num_stim
        framesj = (stim_frames(j)-baseline_wind):(stim_frames(j) + stim_wind);
        framesj(framesj<=0) = nan; % exclude frames before recording start
        framesj(framesj>size(means,1)) = nan; % exclude frames after recording end
        include_indsi = ~isnan(framesj);
        mean_aligned(include_indsi,:,j) = means(framesj(include_indsi),:);
    end
    baselines = mean(mean_aligned(1:baseline_wind,:,:),1,'omitnan'); % [1 x num_traces x num_stim or num_trains]
    deltaF_F0_aligned = (mean_aligned - baselines)./baselines; 
end
out.deltaF_F0_aligned = deltaF_F0_aligned;
out.mean_aligned = mean_aligned;
out.baselines = baselines;
% aligned_means = squeeze(aligned_means); % remove singleton dimensions
% aligned_deltaF_F0s = squeeze(aligned_deltaF_F0s); % remove singleton dimensions
end