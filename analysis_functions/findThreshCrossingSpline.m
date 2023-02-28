function [thresh_times,y_splines] = findThreshCrossingSpline(t,y,thresh,bsline_wind,...
                                                            dir,peak_interv)
%FINDTHRESHCROSSINGSPLINE(t,y,thresh,bsline_wind,dir) 
%  Find time traces cross threshold by fitting to cubic spline
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if nargin < 5
   dir = 1; % positive going
end
if nargin < 6
    peak_interv = [t(1),t(end)];  % window to find peak, in time units  
end
num_traces = size(y,2);
thresh_times = zeros(1,num_traces);
y_splines = cell(1,num_traces);
for i = 1:num_traces
    y_spline = spapi(3,t,y(:,i)); % quadratic splines
    y_splines{i} = y_spline; 
    dy_spline = fnder(y_spline); % first deriv in time
    [smax, tpeak] = fnmin(fncmb(y_spline,-dir),peak_interv);  % time of the peak 
    if thresh == 1 
        thresh_times(i) = tpeak; % just use peak time
    else
        sbase = mean(fnval(y_spline, bsline_wind));  % average baseline frames
        spline2 = fncmb(fncmb(y_spline, '-', sbase), abs(1/(smax - sbase))); % scale the spline
        tmp = fnzeros(fncmb(spline2, '-', thresh*dir));  % find the threshold-crossings
        xsigns = sign(fnval(dy_spline, tmp(1,:))); % sort by direction
        tmp = tmp(1, xsigns*dir > 0);  % only keep the ones in the desired direction
        
        if ~isempty(tmp)
            [~, indx] = min(abs(tmp - tpeak)); % find the one closest to the peak
            thresh_times(i) = tmp(indx);
        else
            thresh_times(i) = NaN;
        end
    end
end