%% Plot strength duration curve
data_fold = fullfile(getDataFold('aman_thor'),'Efield_thresh_experiments'); 
exp_date = '240715';
reporter = 'GCaMP8f_SynmRuby';
dish = 'dish2';
roiset_filename = 'RoiSet_pc_pos0b.zip';
roi_func_mode = 'combine';
save_fig = 1;
pulse_durs_ms = [50e-3,100e-3,200e-3,500e-3,1,5,10]; % pulse durations in ms
cond_folds = numericVec2chars(pulse_durs_ms,'thresh_%gms');

num_pulse_durs = length(pulse_durs_ms);
[~,roiset_filename_no_ext] = fileparts(roiset_filename);   
exp_fold = fullfile(data_fold,exp_date,reporter,dish);
threshEs = zeros(num_pulse_durs,1); 
for i = 1:num_pulse_durs
    threshdatai = load(fullfile(exp_fold,cond_folds{i},...
                    sprintf('thresh_data_%s',roiset_filename_no_ext)));
    threshEs(i) = threshdatai.thresh;     
end
%% Estimate time constant and rheobase 
mode = 1; % 1 - chronaxie (Weiss) 2 - time constant (Lapicque)
[tau,rb,rsq,fitobjs] = calcStrDurTimeConstants(pulse_durs_ms,threshEs,mode);
pulse_durs_fit = linspace(pulse_durs_ms(1),pulse_durs_ms(end),1e3);
threshEs_fit = fitobjs(pulse_durs_fit);

% Plot
E_per_mA = 68.524; % V/m per mA 
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
if mode == 1
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
    fig_name = sprintf('str_dur_curve_mode%g',mode);
    printFig(fig,fig_fold,fig_name)
end