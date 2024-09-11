%% Plot strength duration curve
data_fold = fullfile(getDataFold('aman_thor'),'Efield_thresh_experiments'); 
exp_date = '240718';
reporter = 'GCaMP8f_SynmRuby';
dish = 'dish4';

roiset_filename = 'RoiSet_pc_pos1.zip';
roi_func_mode = 'combine';
E_per_mA = 67; % V/m per mA 

save_fig = 1;
pulse_durs_ms = [0.05,0.1,0.2,0.5,1,5,10]; % pulse durations in ms
% pulse_durs_ms = [0.05,0.1,0.2,0.5,1]; % pulse durations in ms
cond_folds = numericVec2chars(pulse_durs_ms,'thresh_%gms_1stim');

num_pulse_durs = length(pulse_durs_ms);
[~,roiset_filename_no_ext] = fileparts(roiset_filename);   
exp_fold = fullfile(data_fold,exp_date,reporter,dish);
threshEs = zeros(num_pulse_durs,1); 
peak_times_all = cell(1,num_pulse_durs);
peak_times_thresh = zeros(1,num_pulse_durs);
logit_slopes = zeros(1,num_pulse_durs);
for i = 1:num_pulse_durs
    threshdatai = load(fullfile(exp_fold,cond_folds{i},...
                    sprintf('thresh_data_%s',roiset_filename_no_ext)));
    threshEs(i) = threshdatai.thresh;    
    logit_slopes(i) = threshdatai.b(2); 
    summary_datafilei = sprintf('%s_%s_%s_%s_%s_%gms_1stim',exp_date,reporter,dish,roi_func_mode,...
                                    roiset_filename_no_ext,pulse_durs_ms(i));
    outi = load(summary_datafilei);
    peak_timesi = cell2mat(cellfun(@(x) x',outi.peak_times_all,'UniformOutput',0));   
    successful_spikes_alli = cell2mat(cellfun(@(x) x',outi.successful_spikes,'UniformOutput',0));     
    peak_timesi(~successful_spikes_alli) = nan; 
    peak_times_all{i} = peak_timesi; 
    % get peak time at threshold amp
    peak_time_threshi = zeros(1,size(peak_timesi,2));
    for j = 1:size(peak_timesi,2)
        % peak response at lowest suprathreshold amp
        peak_time_threshi(j) = peak_timesi(find(successful_spikes_alli(:,j),1),j); 
    end
    peak_times_thresh(i) = mean(peak_time_threshi);
end
fprintf('Loaded threshold data\n')
%% Estimate time constant and rheobase 
sd_mode = 1; % 1 - chronaxie (Weiss) 2 - time constant (Lapicque)
[tau,rb,rsq,fitobjs] = calcStrDurTimeConstants(pulse_durs_ms,threshEs,sd_mode);
pulse_durs_fit = linspace(pulse_durs_ms(1),pulse_durs_ms(end),1e3);
threshEs_fit = fitobjs(pulse_durs_fit);

% Plot

% E_per_mA = threshdatai.E_per_mA;
fig = figure; 
plot(pulse_durs_ms,threshEs,'o'); hold on;
hold on;
plot(pulse_durs_fit,threshEs_fit,'r-');
legend('data',sprintf('fit (R^{2} = %.3f)',rsq),'Box','off');
box off; grid on;
ax = gca;
ax.XScale = 'log';
ax.YScale = 'log';
xlabel('Pulse duration (ms)')
ylabel('Threshold E (V/m)')
if sd_mode == 1
    title_str = sprintf('\\tau_{ch} = %.1f \\mu s, E_{rh} = %.2f V/m (%.2f mA)',...
                        tau*1e3,rb,rb/E_per_mA);
else 
    title_str = sprintf('\\tau = %.1f \\mu s, E_{rh} = %.2f V/m (%.2f mA)',...
                        tau*1e3,rb,rb/E_per_mA);
end
title(title_str)
if save_fig
    fig_fold = fullfile(exp_fold,sprintf('figs_%s_%s_%s',reporter,...
                            roiset_filename_no_ext,roi_func_mode));
    fig_name = sprintf('str_dur_curve_mode%g',sd_mode);
    printFig(fig,fig_fold,fig_name)
end
%% Peak timing
fig = figure; 
plot(pulse_durs_ms,peak_times_thresh*1e3,'-ko');
box off; grid on;
ax = gca;
ax.XScale = 'log';
xlabel('Pulse duration (ms)')
ylabel('Peak time at threshold (ms)')
% ax.YLim(1) = 0; 
if save_fig
    fig_fold = fullfile(exp_fold,sprintf('figs_%s_%s_%s',reporter,...
                            roiset_filename_no_ext,roi_func_mode));
    'mean_peak_time_at_thresh_vs_dur';
    printFig(fig,fig_fold,fig_name)
end
%% Logistic function fit slope
fig = figure; 
plot(pulse_durs_ms,logit_slopes,'-ko');
box off; grid on;
ax = gca;
% ax.XScale = 'log';
xlabel('Pulse duration (ms)')
ylabel('Logit slope')
% ax.YLim(1) = 0; 
if save_fig
    fig_fold = fullfile(exp_fold,sprintf('figs_%s_%s_%s',reporter,...
                            roiset_filename_no_ext,roi_func_mode));
    fig_name = 'logit_slope_vs_dur';
    printFig(fig,fig_fold,fig_name)
end