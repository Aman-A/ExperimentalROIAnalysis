function [snr,sig,noise] = spikeSNR(y,exp_settings)
%SPIKESNR ... 
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
exp_settings.convert2Frames(); 
baseline_wind = exp_settings.baseline_wind; % first stim
noise = std(y(1:baseline_wind),0,1); % std of baseline
sig = max(y(baseline_wind+1:end),[],1,'omitnan'); % signal must occur after stim
snr = sig/noise; 
