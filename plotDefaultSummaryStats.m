function plotDefaultSummaryStats(peaks_deltaF_F0_all,poststim_ints_all,peak_times_all,...
                                 baselines_all,rel_times_cond_starts,...
                                 conditions,exp_date,reporter,dish,roi_set_filename,...
                                 plot_settings,varargin)
%PLOTDEFAULTSUMMARYSTATS Plots and saves default summary stats figures
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
in.plot_inds = [1,2,3,4];
in.summary_fig_dir = ''; 
in = sl.in.processVarargin(in,varargin); 
if isempty(in.summary_fig_dir)
    data_fold = getDataFold(); 
    if isfield(plot_settings,'transform_type') && strcmp(plot_settings.transform_type,'displace')
        [~,reg_rec_name,~] = fileparts(plot_settings.registration_rec);
        summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
            sprintf('figs_%s_%s_displace',roi_set_filename,...
            reg_rec_name));
    else
        summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
            ['figs_',roi_set_filename]);
    end
else
    summary_fig_dir = in.summary_fig_dir;
end
fig_pos = [17.9652    3.3338   20.9550   12];
fig_units = 'centimeters';
% Peak deltaF/F0
if any(in.plot_inds == 1)
    figure('Units',fig_units,'Position',fig_pos); 
    plotSummaryStats(peaks_deltaF_F0_all,rel_times_cond_starts,conditions,...
                    'Peak \Delta F / F_{0}','','save_fig',plot_settings.save_fig,...
                    'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                    'fig_dir',summary_fig_dir);
end
% Integrals
if any(in.plot_inds == 2)
    figure('Units',fig_units,'Position',fig_pos); 
    plotSummaryStats(poststim_ints_all,rel_times_cond_starts,conditions,...
                    'Post-stim integral','sec','save_fig',plot_settings.save_fig,...
                    'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                    'fig_dir',summary_fig_dir);
end            
% Peak times
if any(in.plot_inds == 3)
    figure('Units',fig_units,'Position',fig_pos); 
    % convert to ms and subtract mean peak time of control to get change timing
    % peak_time_rel_mean_control = cellfun(@(x) 1e3*(x - mean(peak_times_all{1})),...
    %                                      peak_times_all,...
    %                                      'UniformOutput',0);
    peak_time_rel_mean_control = cellfun(@(x) 1e3*x,peak_times_all,'UniformOutput',0); % convert to ms

    plotSummaryStats(peak_time_rel_mean_control,...
                     rel_times_cond_starts,conditions,...
                     'Peak time','ms','save_fig',plot_settings.save_fig,...
                     'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                     'fig_dir',summary_fig_dir);
end
% Baselines            
if any(in.plot_inds == 4)
    figure('Units',fig_units,'Position',fig_pos.*[1 1 1 1.7]); 
    subplot(2,1,1)
    plotSummaryStats(baselines_all,[],conditions,...
                    'Baseline','a.u.','save_fig',0,... % skip save until 2nd subplot
                    'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                    'fig_dir',summary_fig_dir);            
    subplot(2,1,2)
    baselines_all_rel = cellfun(@(x) 100*(x-mean(baselines_all{1}))./mean(baselines_all{1}),...
                                baselines_all,'UniformOutput',0);
    plotSummaryStats(baselines_all_rel,rel_times_cond_starts,conditions,...
                    'Baseline','% change','save_fig',plot_settings.save_fig,...
                    'exp_date',exp_date,'reporter',reporter,'dish',dish,... 
                    'fig_dir',summary_fig_dir); 
end