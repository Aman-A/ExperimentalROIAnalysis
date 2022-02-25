function plotTracesOverlaidGridArray(t,traces_all_arr,err_all_arr,varargin)
% PLOTTRACESOVERLAIDGRIDARRAY Helper function for plotTracesOverlaidGrid,
% takes 3D matrix input instead of cell array 
%  
%   Inputs 
%   ------ 
%   t : vector
%      time vector for all traces
%   traces_all : num_time_points x num_rois x num_conditions
%                Trace values input as 3D array
%   err_all : num_time_points x num_rois x num_conditions
%                 Corresponding error values input as 3D array, CURRENTLY
%                 NOT USED
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
traces_all_cell = mat2cell(traces_all_arr,size(traces_all_arr,1),size(traces_all_arr,2),...
                                      ones(1,size(traces_all_arr,3))); 
if nargin > 2 && ~isempty(err_all_arr)                                   
    err_all_cell = mat2cell(err_all_arr,size(err_all_arr,1),size(err_all_arr,2),...
                                      ones(1,size(err_all_arr,3)));   
else
    err_all_cell = []; 
end
plotTracesOverlaidGrid(t,traces_all_cell,err_all_cell,varargin{:})                                  