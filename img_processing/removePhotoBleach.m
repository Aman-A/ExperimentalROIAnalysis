function [Fc,pbleach] = removePhotoBleach(F,varargin)
%REMOVEPHOTOBLEACH Removes photobleaching from fluorescence traces

%   Inputs 
%   ------ 
%   F : N x num_rois array 
%       Fluorescence traces in each ROI
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.method = 1;
in.interp_interval = [];
in.skip_initial_frames = 3;
in = sl.in.processVarargin(in,varargin);
if in.skip_initial_frames > 0
    F(1:in.skip_initial_frames,:) = nan;
end
if in.method == 1    
    %  Removes photobleaching by taking the minimum value within sliding
    %  window of length interp_interval and then smooths with moving
    %  average to compute photobleaching trace.
    % The raw intensity is divided element-wise by the photobleaching trace.
    % This function removes any baseline drift, not just photobleaching.
    % The smoothing window should exceed the interval between stimuli.
    %  Adapted from rep_pbleach.m written by Adam E Cohen 
    
    pbleach = imerode(mean(F,2,'omitnan'), ones(in.interp_interval,1));
    pbleach = smooth(pbleach, in.interp_interval); 
%     pbleach = imerode(F, ones(in.interp_interval,1));
%     for i = 1:size(F,2)
%         pbleach(:,i) = smooth(pbleach(:,i), in.interp_interval); 
%     end
%     window_size = 5;
%     b = (1/window_size)*ones(1,window_size);
%     a = 1;
%     pbleach = filter(b,a,pbleach)
    Fc = F./pbleach;
elseif in.method == 2
    error('Not implemented yet')
%     meanF = mean(F,2,'omitnan');
%     meanF = smooth(meanF,in.interp_interval); % smooth with moving average
%     fit_eqn = 'a*exp(-x/b)';    
%     upper_bounds = [max(meanF),10]; % max photobleaching time constant 10 sec
%     lower_bounds = [0,0];
%     start_points = [max(meanF)/2,0.05];
%     s = fitoptions('Method','NonlinearLeastSquares',...
%                            'Lower',lower_bounds,...
%                            'Upper',upper_bounds,...
%                            'Startpoint',start_points);
%     f = fittype(fit_eqn,'options',s); 
%     t_fit = (1:size(meanF,1))'-1;
%     [fitobj,gof,~] = fit(t_fit,meanF,f);
%     pbleach = fitobj(t_fit);
%     Fc = F./pbleach; 
end

end