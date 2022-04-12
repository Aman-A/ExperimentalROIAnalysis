function spike_widths = spikeWidths(t,y,stim_indices,frac_amp,mode,baseline_wind)
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
num_stim = length(stim_indices);
if nargin < 5
    mode = 1; % 1 - use baseline and frac_amp of first spike to calculate
              % width of all spikes in train
              % 2 - use local baseline to compute amplitude of each spike, 
              % calculate width at frac_amp of each spike              
end
if nargin < 6
    baseline_wind = min(diff(stim_indices)); % only applies to mode 2
end
spike_widths = zeros(num_stim,1);
inds = [1,stim_indices,length(y)];
if mode == 1    
    for i = 2:num_stim+1
        % get width of first AP
        ti = t(inds(i-1):inds(i+1)); % get trace from start to 2nd stim
        yi = y(inds(i-1):inds(i+1));
        stim_index = 1+inds(i)-inds(i-1); 
        if i == 2
            [spike_widths(i-1),width_val] = spikeWidth(ti,yi,stim_index,frac_amp);
            continue
        end
        spike_widths(i-1) = spikeWidth2(ti,yi,stim_index,width_val);
    end
else   
    for i = 2:num_stim+1
        ti = t(inds(i-1):inds(i+1));
        yi = y(inds(i-1):inds(i+1));        
        stim_index = 1+inds(i)-inds(i-1); 
        bsline = mean(yi(stim_index-baseline_wind:stim_index));
        yi = (yi - bsline)/abs(bsline); % re-normalize to local baseline
        spike_widths(i-1) = spikeWidth(ti,yi,stim_index,frac_amp);
    end
end
end