function spike = spikePresent(trace,baseline_wind,thresh,peak)
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
if nargin < 4
    peak = max(trace);
end
std_baseline = std(trace(1:baseline_wind));
if peak > thresh*std_baseline
    spike = true;
else
    spike  = false;
end