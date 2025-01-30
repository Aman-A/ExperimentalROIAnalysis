function [num_minis_in_bin, mini_rates_in_bin] = ...
    analyzeMiniRatesBinned(mini_frames,num_bins, sampling_rate, total_time)
%ANALYZEMINIRATESBINNED 
% mini_frames : 1 x num_rois cell array
%               each element is a vector of frames when mini occurred
% sampling_rate : imaging sampling rate (frames/sec)
% total_time : total recording duration in sec

num_rois = length(mini_frames);
bin_size = total_time/num_bins;  % bin size in sec
num_minis_in_bin = zeros(num_rois,num_bins);
for i = 1:num_rois
    mini_timesi = mini_frames{i}/sampling_rate; 
    if ~isempty(mini_timesi)
        bin_edges = 0:bin_size:total_time; 
        num_minis_per_bini = histcounts(mini_timesi,bin_edges); %
        num_minis_in_bin(i,:) = num_minis_per_bini; % store in matrix
    end
end
mini_rates_in_bin = num_minis_in_bin/bin_size; % rates in Hz
end