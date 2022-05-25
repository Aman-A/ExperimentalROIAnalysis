function [t_align,F_align] = alignPeaks(t,F,stim_wind_inds,align_to)
%ALIGNPEAKS Align waveforms to peaks 
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
Ntraces = length(F); 
if nargin < 4
    align_to = 'max';
end
if nargin < 3 || isempty(stim_wind_inds) % use entire trace
    stim_wind_inds = cellfun(@(x) 1:size(x,1),F,'UniformOutput',0);
else
    if isvector(stim_wind_inds) % single vector of indices
        stim_wind_inds = repmat({stim_wind_inds},Ntraces,1); % repeat for all traces    
    end
end
if ~iscell(F) % convert to cell array
    F = mat2cell(F,size(F,1),ones(1,size(F,2)));
end
if ~iscell(t)
    t = repmat({t},1,Ntraces);
end
t_all = cell(1,Ntraces);
align_to_inds = zeros(Ntraces,1);
if strcmp(align_to,'max')
    for i = 1:Ntraces
        [~,max_inds]  = max(F{i}(stim_wind_inds{i},:),[],1); % use 1st stim
        align_to_inds(i) = max_inds(1); 
        t_all{i} = zeros(length(t{i}),size(F{i},2));
        for j = 1:size(F{i},2) % handles multiple traces per cell element, but unnecessary for now
            t_all{i}(:,j) = t{i} - t{i}(stim_wind_inds{i}(max_inds(j))); % set t = 0 to max
        end
    end
elseif strcmp(align_to,'min')
    for i = 1:Ntraces
        [~,min_inds]  = min(F{i}(stim_wind_inds{i},:),[],1); % use 1st stim
        align_to_inds(i) = min_inds(1); 
        t_all{i} = zeros(length(t{i}),size(F{i},2));
        for j = 1:size(F{i},2)
            t_all{i}(:,j) = t{i} - t{i}(stim_wind_inds{i}(min_inds(j))); % set t = 0 to max
        end
    end
end
%% get aligned time/F vectors
dt = mode(diff(t{1})); % assume uniform sampling rate
t_align = (cellfun(@min,t_all):dt:cellfun(@max,t_all))';
t_align(value2ind(0,t_align)) = 0; % set to 0
peak_ind = find(t_align == 0);
F_align = nan(length(t_align),Ntraces);
for i = 1:Ntraces
    inds = 1:length(F{i});
    inds2 = inds + (peak_ind - align_to_inds(i));
    inds(inds2 < 1) = [];
    inds(inds2 > size(F_align,1)) = [];
    inds2(inds2 < 1) = []; 
    inds2(inds2 > size(F_align,1)) = []; 
    F_align(inds2,i) = F{i}(inds);
end
end

