function [tout,yout,pk_ind] = peakAlignTraces(t,y,stim_index,varargin)
% PEAKALIGNTRACES - align array of stim-aligned recordings to peaks
if nargin < 3 || isempty(stim_index)
    stim_index = 1; % search full trace
end
in.stim_wind = size(y,1) - stim_index; 
in.align_to = 'max'; % 'max' or 'min'
in = sl.in.processVarargin(in,varargin);
stim_wind_inds = stim_index:(stim_index+in.stim_wind); 

t_all = zeros(length(t),size(y,2));
pk_inds = zeros(size(y,2),1);
if strcmp(in.align_to,'max')
    for i = 1:size(y,2)
        [~,max_ind]  = max(y(stim_wind_inds,i),[],1);   
        t_all(:,i) = t - t(stim_wind_inds(max_ind));       
        pk_inds(i) = max_ind+stim_wind_inds(1)-1;
    end
elseif strcmp(in.align_to,'min')
    for i = 1:size(y,2)
        [~,min_ind]  = min(y(stim_wind_inds,i),[],1);   
        t_all(:,i) = t - t(stim_wind_inds(min_ind));       
        pk_inds(i) = min_ind+stim_wind_inds(1)-1;
    end
end
min_t = min(t_all,[],'all');
max_t = max(t_all,[],'all');
dt = mode(diff(t));
tout = (min_t:dt:(max_t))';
pk_ind = value2ind(0,tout);
yout = nan(length(tout),size(y,2)); % align traces, leaving blank frames as nans
for i = 1:size(y,2)    
    indsi = (1:size(y,1)) + (pk_ind - pk_inds(i));
    yout(indsi,i) = y(:,i);
end
end