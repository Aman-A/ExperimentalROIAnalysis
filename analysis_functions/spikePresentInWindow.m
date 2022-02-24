function spike = spikePresentInWindow(trace,baseline_wind,thresh,peak_window)
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
peak = max(trace(baseline_wind+2:baseline_wind+peak_window+2)); 
std_baseline = std(trace(1:baseline_wind));
if peak > thresh*std_baseline
    spike = true;
else
    spike  = false;
end