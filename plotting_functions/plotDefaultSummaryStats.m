function plotDefaultSummaryStats(peaks_deltaF_F0_all,poststim_ints_all,peak_times_all,...
                                 baselines_all,decay_fits_all,rel_times_cond_starts,...
                                 conditions,exp_date,reporter,dish,...
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
in.roi_set_filename = ''; 
in.summary_fig_dir = ''; 
in.title_on = 1;
in.fig_pos = [17.9652    3.3338   20.9550   12];
in.fig_units = 'centimeters';
in.successful_spikes = {}; 
in.rsq_cutoff = 0.8; % cutoff to exlcude tau decay fits with low R^2 
in.save_fig = 1; 
in = sl.in.processVarargin(in,varargin); 
if ~isempty(in.successful_spikes)
    assert(isequal(size(in.successful_spikes),size(peaks_deltaF_F0_all)),...
            'successful_spikes should be cell array with same dimensions as input data\n')
    for i = 1:length(peaks_deltaF_F0_all)
        peaks_deltaF_F0_all{i}(~in.successful_spikes{i}) = nan;
        poststim_ints_all{i}(~in.successful_spikes{i}) = nan;    
        peak_times_all{i}(~in.successful_spikes{i}) = nan;
    end
    % decay fits already skips traces with no evoked response
    fprintf('Removed data points with no evoked response\n')
end
if isempty(in.summary_fig_dir)
    data_fold = getDataFold(); 
    roiset_filename_no_ext = getROIset_name(in.roi_set_filename,...
                                            plot_settings.transform_type,...
                                            plot_settings.registration_rec);  
    summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                               ['figs_' roiset_filename_no_ext '_' plot_settings.roi_func_mode]);     
else
    summary_fig_dir = in.summary_fig_dir;
end

% Peak deltaF/F0
if any(in.plot_inds == 1)
    figure('Units',in.fig_units,'Position',in.fig_pos); 
    plotSummaryStats(peaks_deltaF_F0_all,rel_times_cond_starts,conditions,...
                    'Peak \Delta F / F_{0}','','save_fig',in.save_fig,...
                    'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                    'fig_dir',summary_fig_dir,'title_on',in.title_on);
end
% Integrals
if any(in.plot_inds == 2)
    figure('Units',in.fig_units,'Position',in.fig_pos); 
    plotSummaryStats(poststim_ints_all,rel_times_cond_starts,conditions,...
                    'Post-stim integral','sec','save_fig',in.save_fig,...
                    'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                    'fig_dir',summary_fig_dir,'title_on',in.title_on);
end            
% Peak times
if any(in.plot_inds == 3)
    figure('Units',in.fig_units,'Position',in.fig_pos); 
    % convert to ms and subtract mean peak time of control to get change timing
    % peak_time_rel_mean_control = cellfun(@(x) 1e3*(x - mean(peak_times_all{1})),...
    %                                      peak_times_all,...
    %                                      'UniformOutput',0);
    peak_time_rel_mean_control = cellfun(@(x) 1e3*x,peak_times_all,'UniformOutput',0); % convert to ms

    plotSummaryStats(peak_time_rel_mean_control,...
                     rel_times_cond_starts,conditions,...
                     'Peak time','ms','save_fig',in.save_fig,...
                     'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                     'fig_dir',summary_fig_dir);
end
% Baselines            
if any(in.plot_inds == 4)
    figure('Units',in.fig_units,'Position',in.fig_pos.*[1 1 1 1.7]); 
    subplot(2,1,1)
    plotSummaryStats(baselines_all,[],conditions,...
                    'Baseline','a.u.','save_fig',0,... % skip save until 2nd subplot
                    'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                    'fig_dir',summary_fig_dir,'title_on',in.title_on);            
    subplot(2,1,2)
    baselines_all_rel = cellfun(@(x) 100*((mean(x,2:4)-mean(baselines_all{1},2:4))./mean(baselines_all{1},2:4)),...
                                baselines_all,'UniformOutput',0);
    plotSummaryStats(baselines_all_rel,rel_times_cond_starts,conditions,...
                    'Baseline','% change','save_fig',in.save_fig,...
                    'exp_date',exp_date,'reporter',reporter,'dish',dish,... 
                    'fig_dir',summary_fig_dir,'title_on',in.title_on); 
end
% Fast decay time constants
if any(in.plot_inds == 5) && ~isempty(decay_fits_all)
    figure('Units',in.fig_units,'Position',in.fig_pos); 
    taud1_all = cellfun(@(x) x.taud1,decay_fits_all,'UniformOutput',0);    
    fprintf('Removing fits with R^2 < %.2f\n',in.rsq_cutoff);
    % remove fits with R^2 < 0.5
    for i = 1:length(taud1_all)
        taud1_all{i}(decay_fits_all{i}.rsquare < in.rsq_cutoff) = nan; 
    end
    % normalize to mean control
%     taud1_all = cellfun(@(x) x./mean(taud1_all{1},2),taud1_all,'UniformOutput',0); 
    plotSummaryStats(taud1_all,rel_times_cond_starts,conditions,...
                    'Fast decay \tau','sec','save_fig',in.save_fig,...
                    'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                    'fig_dir',summary_fig_dir,'title_on',in.title_on);
end
% Slow decay time constants
if any(in.plot_inds == 6) && ~isempty(decay_fits_all)
    if isfield(decay_fits_all{1},'taud2')
        figure('Units',in.fig_units,'Position',in.fig_pos); 
        taud2_all = cellfun(@(x) x.taud2,decay_fits_all,'UniformOutput',0);        
        fprintf('Removing fits with R^2 < %.2f\n',in.rsq_cutoff);
        % remove fits with R^2 < 0.5
        for i = 1:length(taud2_all)
            taud2_all{i}(decay_fits_all{i}.rsquare < in.rsq_cutoff) = nan; 
        end
        % normalize to mean control
    %     taud1_all = cellfun(@(x) x./mean(taud1_all{1},2),taud1_all,'UniformOutput',0); 
        plotSummaryStats(taud2_all,rel_times_cond_starts,conditions,...
                        'Slow decay \tau','sec','save_fig',in.save_fig,...
                        'exp_date',exp_date,'reporter',reporter,'dish',dish,...
                        'fig_dir',summary_fig_dir,'title_on',in.title_on);
    else
        fprintf('Decay was fit to monoexponential, skipping slow decay time constant...\n')
    end
end