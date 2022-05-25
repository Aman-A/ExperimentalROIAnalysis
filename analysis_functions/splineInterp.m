function [t_interp,y_interp] = splineInterp(t,y,spline_sampling_factor)
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
 dt = mode(t(2)-t(1)); % time step of input vector
t_interp = (t(1):(dt/spline_sampling_factor):t(end))'; % upsample by spline_sampling_factor
y_interp = spline(t,y,t_interp);