function [ab,a,b] = compareEventTimes(traina,trainb,dist)
%COMPAREEVENTTIMES Compare events (e.g. spikes) between two vectors (a and b) and
%return events in both, events in a but not b, and events in b but not a
%  
%   Inputs 
%   ------ 
%   traina : vector
%   trainb : vector
%   dist : scalar
%           window around events considered matching, e.g. events at 4 and 4.5
%           would be matching if dist = 1, but not if dist = 0.4 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
% Uses algorithm from Cai 2021, doi: 10.1371/journal.pcbi.1008806

% AUTHOR    : Aman Aberra 
if nargin < 3
    dist = eps; % default require to be identical (within numerical precision)
end
ab = []; % events both train a and b
a = []; % events in train a only
b = []; % events in train b only
% Deal with empty inputs
if isempty(traina) || isempty(trainb)
    ab = []; 
    a = traina;
    b = trainb; 
    return
end
if isrow(traina); traina = traina'; end % convert to column vectors 
if isrow(trainb); trainb = trainb'; end
% Greedy matching algorithm
while ~isempty(traina) && ~isempty(trainb)
    dists_ab = abs(traina(1) - trainb);
    [min_dist,min_ind] = min(dists_ab);
    if min_dist <= dist
%         fprintf('Mini at frame %g (A) or %g (B, element %g) match, removing\n',...
%                 traina(1),trainb(min_ind),min_ind);
        ab = [ab;traina(1)];
        traina(1) = []; 
        trainb(min_ind) = [];          
    else
%         fprintf('Mini at frame %g (A) does not match any in B, removing\n',...
%                 traina(1));
        a = [a;traina(1)];
        traina(1) = [];
    end   
end
a = [a;traina]; % add remaining unmatched
b = [b;trainb]; 
end