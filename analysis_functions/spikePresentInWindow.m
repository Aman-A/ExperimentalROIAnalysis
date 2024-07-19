function spike = spikePresentInWindow(trace,baseline_wind,thresh,peak_window,...
                                       peak,min_amp)
%SPIKEPRESENT simple threshold checking based on baseline variance 
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
% find peak within post-stim window defined by peak_window
if nargin < 6
    min_amp = []; 
end
if nargin < 5
    peak = max(trace(baseline_wind+2:baseline_wind+peak_window+2)); 
end
std_baseline = std(trace(1:baseline_wind));
if peak > thresh*std_baseline
    spike = true;
    if ~isempty(min_amp) && peak < min_amp        
        spike = false;
    end
else
    spike  = false;
end