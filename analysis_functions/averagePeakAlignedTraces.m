function [tout,meany] = averagePeakAlignedTraces(t,y,stim_index,dim,...
                                            varargin)
% only works for <4 dim
in.stim_wind = size(y,1) - stim_index;
in.align_to = 'max';
in = sl.in.processVarargin(in,varargin);
ydims = size(y); 
dim_inds = 2:length(ydims);
ntraces = prod(ydims(dim_inds(dim_inds~=dim)));
t_all = cell(ydims(dim_inds(dim_inds~=dim)));
y_all = cell(ydims(dim_inds(dim_inds~=dim)));
pk_inds = zeros(ydims(dim_inds(dim_inds~=dim)));
for i = 1:ntraces
    [indi,indj] = ind2sub(ydims(dim_inds(dim_inds~=dim)),i); % subscripts of this trace    
%     yindsi = {indi,indj}; % build indexing array for y_all
    indsi = arrayfun(@(x) 1:x,ydims(2:end),'UniformOutput',0); % build indexing arrays
    indsi(dim_inds~=dim) = {indi,indj};
    yi = squeeze(y(:,indsi{:}));
    [ti,yia,pk_indi] = peakAlignTraces(t,yi,stim_index,'stim_wind',in.stim_wind,...
                              'align_to',in.align_to);
    t_all{i} = ti; 
    y_all{i} = mean(yia,2,'omitnan'); 
    pk_inds(i) = pk_indi;
end
% keep min shared time points across traces
nbefore = min(cellfun(@(x,y) length(x(1:y-1)),t_all,num2cell(pk_inds),...
                    'UniformOutput',1),[],'all');
nafter = min(cellfun(@(x,y) length(x(y+1:end)),t_all,num2cell(pk_inds),...
                        'UniformOutput',1),[],'all');
% make shared time base
tout = t_all{1}((pk_inds(1)-nbefore):(pk_inds(1)+nafter));
meany = cellfun(@(x,y) x(y-nbefore:y+nafter,:),...
                            y_all,num2cell(pk_inds),'UniformOutput',0);
meany = squeeze(cell2mat(reshape(meany,1,size(meany,1),[])));
end