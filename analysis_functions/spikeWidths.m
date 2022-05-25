function spike_widths = spikeWidths(t,y,stim_indices,frac_amp,width_mode,baseline_wind,varargin)
%SPIKEWIDTHS Compute spike widths of multiple spikes within train, included
%in single trace
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
in.spline_interp = 0; 
in.spline_sampling_factor = 50; % factor above actual sampling rate for 
                                % spline interpolation
in.plot_figs = 0;                                 
in = sl.in.processVarargin(in,varargin);                                
num_stim = length(stim_indices);
if nargin < 5
    width_mode = 1; % 1 - use baseline and frac_amp of first spike to calculate
              % width of all spikes in train (nFWHM from Cho 2020)
              % 2 - use local baseline to compute amplitude of each spike, 
              % calculate width at frac_amp of each spike              
end
% Upsample trace with cubic spline interpolation
if in.spline_interp    
    [t,y] = splineInterp(t,y,in.spline_sampling_factor);
    stim_indices = stim_indices*in.spline_sampling_factor - in.spline_sampling_factor; 
end
if nargin < 6
    baseline_wind = min(diff(stim_indices)); % only applies to mode 2
end
spike_widths = zeros(num_stim,1);
inds = [1,stim_indices,length(y)];
if width_mode == 1  % 1 - use baseline and frac_amp of first spike to calculate
                    % width of all spikes in train (nFWHM from Cho 2020)
    for i = 2:num_stim+1
        % get width of first AP
        ti = t(inds(i-1):inds(i+1)); % get trace from start to 2nd stim
        yi = y(inds(i-1):inds(i+1));
        stim_index = 1+inds(i)-inds(i-1); 
        if i == 2
            [spike_widths(i-1),width_val] = spikeWidth(ti,yi,stim_index,...
                                                    frac_amp,in.plot_figs);
            continue
        end
        spike_widths(i-1) = spikeWidth2(ti,yi,stim_index,width_val,in.plot_figs);
    end
elseif width_mode == 2 
    % 2 - use local baseline to compute amplitude of each spike, 
    % calculate width at individual frac_amp of each spike  
    for i = 2:num_stim+1
        ti = t(inds(i-1):inds(i+1));
        yi = y(inds(i-1):inds(i+1));        
        stim_index = 1+inds(i)-inds(i-1); 
        if baseline_wind >= stim_index
            % start from beginning of trace for this spike, forced to be 
            % after last stim to minimize impact of previous spikes
            baseline_windi = stim_index-1; 
        else
            baseline_windi = baseline_wind; 
        end
        bsline = mean(yi(stim_index-baseline_windi:stim_index));
        yi = (yi - bsline)/abs(bsline); % re-normalize to local baseline
        spike_widths(i-1) = spikeWidth(ti,yi,stim_index,frac_amp,in.plot_figs);
    end
end
end