function [successful_spikes,varargout] = detectSpikesAlignedTraces(deltaF_F0_aligned,...
                                                                  exp_settings,std_threshold,...
                                                                   varargin)
%DETECTSPIKESALIGNEDTRACES Detect spikes using STD/width criteria for
%aligned traces with single stimulus per trace
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
% in.min_width = 0; % min width in sec, set > 0 to enable, or [min_width, max_width]
in.min_width = [10e-3 60e-3];
in.spike_window = 0.03; % sec - window to look for peak
in = sl.in.processVarargin(in,varargin);
if nargin < 3
    std_threshold = 3; 
end
trace_dims = size(deltaF_F0_aligned);
% successful_spikes = false(trace_dims(2:end)); % num_rois x ...
n_traces = prod(trace_dims(2:end));
exp_settings.convert2Frames(); 
stim_frame = exp_settings.baseline_wind + 1;
spike_window = exp_settings.convert2Frames(in.spike_window);
t = exp_settings.getTimeVector(trace_dims(1));
t = t - t(stim_frame);
% Apply STD baseline criteria

[peaks,peak_inds] = max(deltaF_F0_aligned((stim_frame + 1):(stim_frame + spike_window),:,:,:,:),[],1);
peaks = squeeze(peaks); 
peak_inds = squeeze(peak_inds) + stim_frame;
std_baselines = squeeze(std(deltaF_F0_aligned(1:exp_settings.baseline_wind,:,:,:,:),0,1));
successful_spikes = peaks > std_baselines*std_threshold; 
if length(in.min_width) == 1
    in.min_width = [in.min_width inf]; % if specific min width only, add max width
end
if in.min_width(1) > 0
    widths = zeros(size(successful_spikes));
    for i = 1:n_traces
        if successful_spikes(i)
            tracei = deltaF_F0_aligned(:,i);
            widths(i) = spikeWidth(t,tracei,stim_frame,0.5,0,peak_inds(i));
        end        
    end
    outside_min_width = widths > in.min_width(1) & widths < in.min_width(2);
    successful_spikes0 = successful_spikes; % peaks that failed std criterion    
    successful_spikes = successful_spikes & outside_min_width; % peaks failing both
    varargout = {widths,successful_spikes0,outside_min_width};
end
