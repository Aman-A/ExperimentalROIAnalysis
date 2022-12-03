function [spike_width,width_val,start_time,end_time] = spikeWidth(t,y,stim_index,frac_amp,plot_fig) %#codegen
%SPIKEWIDTH Computes spike width at desired fraction of spike amplitude
% assumes single well-defined peak in trace and stim at t = 0
%  
%   Inputs 
%   ------ 
%   t : vector
%       time points in sec
%   y : vector
%       recording values (e.g. fluorescence, voltage)
%   stim_index : scalar
%       index of time point at which stimulus is applied, used to compute
%       baseline (assume entire trace before stim_index is baseline)
%   frac_amp : scalar
%       fraction of amplitude at which to compute width, e.g. 0.5 for FWHM
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
%   For full-width at half-max (FWHM):
%   fwhm = spikeWidth(t,y,stim_index,0.5); % default without 3rd argument is 0.5

% AUTHOR    : Aman Aberra 
if nargin < 4
    frac_amp = 0.5; 
end
if nargin < 5
    plot_fig = 0;
end
max_width = 0.05; % sec - max allowed spike width 20 ms
 
%% Get peak amplitude
[peak_val,peak_ind] = max(y,[],1,'omitnan');
% Get baseline
bsline = sum(y(1:stim_index-1),'omitnan')/(stim_index-1); % mean in baseline window
amp = peak_val - bsline; 
% std_bsline = std(y(1:stim_index-1),0);
% if amp < (bsline + std_bsline)
%    spike_width = nan;
%    fprintf('Peak < std(baselin)*mean(baseline), skipping\n');
%    return;
% end
width_val = amp*frac_amp + bsline; % value at which to find width
onset_found = 0;
offset_found = 0;
for i = stim_index:length(y)
    if ~onset_found 
        if y(i) >= width_val && (t(peak_ind) - t(i)) < max_width/2
            onset_index = i; 
            onset_found = 1;
        end
    end
    if onset_found && ~offset_found
        if y(i) <= width_val
            offset_index = i;
            offset_found = 1;
            break;
        end
    end
end
if onset_found && offset_found % linear interpolation between samples to find value at frac_amp
%     fprintf('onset %g, y(onset_index) = %g, width_val %f\n',onset_index,y(onset_index),width_val);
    slope_onset = (y(onset_index)-y(onset_index-1))/(t(onset_index)-t(onset_index-1));
%     if slope_onset < 0
%         % calculate slope from onset to peak
%         slope_onset = (y(peak_ind)-y(onset_index-1))/(t(peak_ind)-t(onset_index-1));
%     end
%     start_time = (amp*frac_amp - y(onset_index-1))/slope_onset + t(onset_index-1);    
    start_time = (width_val - y(onset_index-1))/slope_onset + t(onset_index-1);    
    slope_offset = (y(offset_index)-y(offset_index-1))/(t(offset_index)-t(offset_index-1));
%     end_time = (amp*frac_amp - y(offset_index-1))/slope_offset + t(offset_index-1); 
    end_time = (width_val - y(offset_index-1))/slope_offset + t(offset_index-1); 
    spike_width = end_time - start_time; 
else % no spike present
    spike_width = nan; 
    width_val = nan; 
    start_time = nan;
    end_time = nan; 
    return; 
end
%% Test plot
if plot_fig
    figure;
    plot(t,y);
    hold on;
    plot([t(1),t(end)],bsline*[1 1],'--k','DisplayName','baseline');
    plot([t(1),t(end)],width_val*[1 1],'--r','DisplayName',sprintf('%g %% max',frac_amp*100));
    plot(t(onset_index-1:onset_index),y(onset_index-1:onset_index),'o','DisplayName','Onset')
    plot(t(offset_index-1:offset_index),y(offset_index-1:offset_index),'o','DisplayName','Offset')
    plot([start_time,end_time],width_val*[1 1],'-go','DisplayName','Interpolated width')
    box off; 
    xlabel('time'); ylabel('amplitude'); 
    legend('Box','off')
%     xlim([0.09 0.12])    
end
end
