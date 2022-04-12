function stim_times = defineStimTrains(delay,freq,dur,num_trains,train_interval)
%DEFINESTIMTRAINS Output stimulus times for multiple pulse trains
%  
%   Inputs 
%   ------ 
%   delay : double
%          Delay in sec for first pulse within trains
%   freq : double
%          Frequency (aka repetition rate) in Hz
%   dur : double
%         Duration of train in sec  
%   num_trains : int
%              Number of pulse trains 
%   train_interval : double
%                    Time between trains in sec
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
train_dur = delay+dur; 
if nargin < 5
    train_interval = train_dur; % assume train repeats immediately after 
                                % last pulse in train
end
if nargin < 4
    num_trains = 1;
end
stim_times = delay:(1/freq):train_dur;
if stim_times(1) == 0
   stim_times(1) = [];  
end
if stim_times(end) == train_dur
   stim_times(end) = []; % remove last stimulus if falls on final time step 
end

train_start_times = 0:(train_interval):(num_trains-1)*(train_interval);
stim_times = repmat(stim_times,num_trains,1);
stim_times = stim_times + train_start_times';
end