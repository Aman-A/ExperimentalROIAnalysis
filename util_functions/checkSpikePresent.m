function successful_spikes = checkSpikePresent(aligned_traces,baseline_wind,...
                                               std_thresh,spike_window)
%CHECKSPIKEPRESENT Checks if spike is present in stim-aligned traces
% 
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
trace_dims = size(aligned_traces,1:4);
successful_spikes = zeros(trace_dims(2:end));
n_traces = prod(trace_dims(2:end));    
for n = 1:n_traces
    tracei = aligned_traces(:,n);
    successful_spike = spikePresentInWindow(tracei,baseline_wind,std_thresh,...
                                            spike_window);
   
    successful_spikes(n) = successful_spike;
end