function stim_times = defineStimTrain(delay,freq,dur)
%DEFINESTIMTRAIN Output stimulus times
%  
%   Inputs 
%   ------ 
%   delay : double
%          Delay in sec
%   freq : double
%          Frequency (aka repetition rate) in Hz
%   dur : double
%         Duration of train in sec  
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
stim_times = delay:(1/freq):(delay+dur);
% if stim_times(end) == delay+dur
%    stim_times(end) = []; % remove last stimulus if falls on final time step 
% end