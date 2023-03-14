function [ahp_amp,ahp_ind] = AHP_amp(t,y,stim_index,plot_fig,peak_ind,varargin)
%AHP_AMP Get amplitude and time of trough of after-hyperpolarization (amp)
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
in.smooth_trace = 0;
in.smooth_span = 10;
in.smooth_method = 'sgolay';
in = sl.in.processVarargin(in,varargin);
if nargin < 4
    plot_fig = 0; 
end
if nargin < 5 || isempty(peak_ind)
    [peak_val,peak_ind] = max(y(stim_index-1:end),[],1,'omitnan'); % get max after stim_index (in case extraneous peak occurs before stim)
    peak_ind = peak_ind + stim_index - 2; % re-index to full vector 
else % input peak index (helps with noisy traces)
    peak_val = y(peak_ind); 
end
bsline = mean(y(1:stim_index-1),'omitnan'); % mean in baseline window
peak_amp = peak_val - bsline; 
% Get min after peak
if in.smooth_trace    
    y = smooth(y,in.smooth_span,in.smooth_method);  
%     fprintf('Smoothing trace with %g window %s filter before detecting AHP trough\n',...
%             in.smooth_span,in.smooth_method);
end
% [ahp_val,ahp_ind] = min(y(peak_ind:end));
[ahp_val,ahp_ind] = findpeaks(-(y(peak_ind:end))/peak_amp,'MinPeakProminence',0.05);
if ~isempty(ahp_val)
    ahp_val = ahp_val(1)*peak_amp;
    ahp_ind = ahp_ind(1) + peak_ind - 1; 
    ahp_amp = ahp_val - bsline; 
else
    ahp_val = nan; 
    ahp_amp = 0;
    ahp_ind = nan;
    return; 
end
if plot_fig
    figure;
    plot(t,y);
    hold on; box off; 
    plot(t(peak_ind),peak_val,'go')
    plot(t(ahp_ind),-ahp_val,'ro');
    legend('trace','peak','ahp')
end