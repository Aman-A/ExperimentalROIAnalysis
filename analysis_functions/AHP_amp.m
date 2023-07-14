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
in.max_ahp_wind = []; 
in.ahp_ind = []; 
in = sl.in.processVarargin(in,varargin);
if nargin < 4
    plot_fig = 0; 
end
if isempty(in.max_ahp_wind)
    end_ind = size(y,1);
else
    end_ind = min(size(y,1),stim_index + in.max_ahp_wind);
end
if nargin < 5 || isempty(peak_ind)
    [peak_val,peak_ind] = max(y(stim_index-1:end_ind),[],1,'omitnan'); % get max after stim_index (in case extraneous peak occurs before stim)
    peak_ind = peak_ind + stim_index - 2; % re-index to full vector 
else % input peak index (helps with noisy traces)
    peak_val = y(peak_ind); 
end
bsline = mean(y(1:stim_index-1),'omitnan'); % mean in baseline window
peak_amp = peak_val - bsline; 
% Get min after peak
if in.smooth_trace    
    y_smooth = smooth(y,in.smooth_span,in.smooth_method);
    bsline_smooth = mean(y_smooth(1:stim_index-1),'omitnan'); % mean in baseline window
    peak_amp_smooth = max(y_smooth(stim_index-1:end)) - bsline_smooth; 
%     fprintf('Smoothing trace with %g window %s filter before detecting AHP trough\n',...
%             in.smooth_span,in.smooth_method);
    % [ahp_val,ahp_ind] = min(y(peak_ind:end));
    y_search = y_smooth;
    peak_amp_search = peak_amp_smooth;
else
    y_search = y; 
    peak_amp_search = peak_amp;
end

if isempty(in.ahp_ind)
    [ahp_val,ahp_ind] = findpeaks(-(y_search(peak_ind:end_ind))/peak_amp_search,'MinPeakProminence',0.05);   
else % extract amp at input in.ahp_ind
    ahp_ind = in.ahp_ind; 
    ahp_val = y_search(ahp_ind);
    ahp_amp = ahp_val - bsline; 
    return
end

if ~isempty(ahp_ind)
    [~,min_ind] = max(ahp_val); % flipped for findpeaks
    ahp_ind = ahp_ind(min_ind) + peak_ind - 1;
%     ahp_val = ahp_val(1)*peak_amp;
%     ahp_ind = ahp_ind(1) + peak_ind - 1; 
    ahp_val = y_search(ahp_ind);
    ahp_amp = ahp_val - bsline; 
else
    [ahp_val,ahp_ind] = min(y_search(peak_ind:end_ind)); % just take min after AP within search window
    ahp_ind = ahp_ind + peak_ind - 1;
    ahp_amp = ahp_val - bsline; 
%     ahp_val = nan; 
%     ahp_amp = 0;
%     ahp_ind = nan;
%     return; 
end
if plot_fig
    figure;
    plot(t,y,'DisplayName','trace'); hold on; 
    if in.smooth_trace
        plot(t,y_smooth,'DisplayName','smoothed trace')
    end
    hold on; box off; 
    plot(t(peak_ind),peak_val,'go','DisplayName','peak')
    plot(t(ahp_ind),ahp_val,'ko','DisplayName','AHP','MarkerSize',8,'MarkerFaceColor','k');
    legend()
end
end