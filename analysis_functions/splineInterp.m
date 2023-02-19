function [t_interp,y_interp] = splineInterp(t,y,spline_sampling_factor,varargin)
%SPLINEINTERP Generate cubic spline interpolation of input trace 
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
in.mode = 'cubic';
in = sl.in.processVarargin(in,varargin);
 dt = mode(t(2)-t(1)); % time step of input vector
if strcmp(in.mode,'cubic')
    t_interp = (t(1):(dt/spline_sampling_factor):t(end))'; % upsample by spline_sampling_factor
    y_interp = zeros(length(t_interp),size(y,2));
    for i = 1:size(y,2)
        y_interp(:,i) = spline(t,y(:,i),t_interp);
    end
elseif strcmp(in.mode,'quadratic')
    t_interp = (t(1):(dt/spline_sampling_factor):t(end))'; % upsample by spline_sampling_factor    
    y_interp = zeros(length(t_interp),size(y,2));
    for i = 1:size(y,2)
        y_spline = spapi(3,t,y(:,i)); % quadratic spline
        y_interp(:,i) = fnval(y_spline,t_interp);    
    end
end