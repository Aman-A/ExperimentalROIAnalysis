function events_bs = bootstrapEvents(events,N_bootstrap,noise)
%BOOTSTRAPEVENTS events_bs = bootstrapEvents(events,N_bootstrap) 
%  
%   Inputs 
%   ------ 
%   events : N events vector
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra
N_events = length(events);
events_bs = zeros(N_bootstrap,1);
for n = 1:N_bootstrap
    a = randi([1 N_events]);
    events_bs(n) = events(a) + normrnd(0,noise); 
end