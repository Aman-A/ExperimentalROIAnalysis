function out = analyzeThresholdLadderTrials(amps,successful_spikes_all,varargin)
%ANALYZETHRESHOLDLADDERTRIALS Fit P(firing) vs. amp to logistic function
%  
%   Inputs 
%   ------ 
%  amps : num_stim x 1
%         vector of stimulus intensity values
%  successful_spikes_all : num_stim x num_trials binary array 
%                          1 for AP, 0 for no AP
%   Optional Inputs 
%   --------------- 
%  E_per_mA : scalar
%             scaling factor for amps from current (in mA) to Efield (in V/m)
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.E_per_mA = []; 
in.link_fun = 'logit';
in.Constant = 'on';
in.plot_fig = 1; 
in.save_fig = 0; 
in.fig_fold = '.';
in.thresh_prob = 0.5; % threshold defined as >= 50% prob of AP
in.save_data = 0; 
in.data_fold = '';
in.data_filename = 'thresh_data'; 
in.print_level = 1; 
in = sl.in.processVarargin(in,varargin);

if ~isempty(in.E_per_mA)
    x = amps*in.E_per_mA;
    units = 'V/m';
else
    x = amps; 
    units = 'mA'; % assume current controlled stim, default units
end
x = abs(x); % make positive
num_trials = size(successful_spikes_all,2);
Y = [sum(successful_spikes_all,2),num_trials*ones(size(successful_spikes_all,1),1)];
% GLM fit to logistic function
[b,dev,stats] = glmfit(x,Y,'binomial','Link',in.link_fun,...
                        'Constant',in.Constant);
xfit = linspace(min(x),max(x),1e3);
yfit = glmval(b,xfit,in.link_fun,'constant','on');
% z = b(1) + x*b(2); % linear part of regression
% z = 1./(1 + exp(-z)); % logit link function
inv_logit = @(y,a,b,c) c - log(a./y - 1)/b;% inverted logit, input coeffs and y, outputs x
thresh = inv_logit(in.thresh_prob,1,b(2),-b(1)/b(2)); % a = 1, b = b(2), c = -b(1)/b(2) 

out = struct(); 
out.b = b;
out.dev = dev;
out.stats = stats;
out.inv_func = inv_logit; 
out.thresh = thresh;
out.thresh_prob = in.thresh_prob; 
out.xfit = xfit; 
out.yfit = yfit; 
if in.print_level > 0
    fprintf('Threshold (p>%g) = %.2f %s',in.thresh_prob,thresh,units)
    if strcmp(units,'V/m')
        out.thresh_mA = thresh/in.E_per_mA;
        fprintf(' (%.3f mA)\n',out.thresh_mA)
    else
        fprintf('\n');
    end
end
if in.plot_fig
    fig = figure; 
    l1 = plot(x,successful_spikes_all,'o','Color',0.4*[1 1 1]); hold on;
    mean_spike_prob = mean(successful_spikes_all,2); % mean across trials
    l2 = plot(x,mean_spike_prob,'k-o');
    l3 = plot(xfit,yfit,'r-');
    l4 = plot(thresh,in.thresh_prob,'ro','MarkerSize',16);
    box off; 
    xlabel('|E| (V/m)'); ylabel('P(AP)')
    legend([l1(1),l2,l3,l4],'Data','mean','fit',sprintf('P(%g) = %.1f %s',...
                                                in.thresh_prob,thresh,...
                                                units),'Box','off',...
                                                'Location','Best');
    xlim([min(x),max(x)]);
    if in.save_fig
        fig_name = 'threshold_curve';
        printFig(fig,in.fig_fold,fig_name);
    end
end
if in.save_data
    if isempty(in.data_fold)
        in.data_fold = in.fig_fold; 
    end
    data_filepath = fullfile(in.data_fold,[in.data_filename '.mat']);
    save(data_filepath,'-STRUCT','out')
    fprintf('Saved threshold data to %s\n',data_filepath);
end

