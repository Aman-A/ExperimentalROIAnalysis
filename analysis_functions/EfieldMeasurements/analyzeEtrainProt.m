function out = analyzeEtrainProt(rec_file_base,sweep1,num_sweeps,stim_name,...
                                gain,iel,amp_per_V,plot_figs,save_figs,varargin)
in.rec_file_fold = '.';
in.fig_fold = 'figs';
in.filt_order = 0; 
in.filt_cutoffs = [59 61];
in.filt_type = 'stop';
in = sl.in.processVarargin(in,varargin);

rec_file = sprintf('%s_%04d-%04d',rec_file_base,sweep1,sweep1+num_sweeps-1);
s = ws.loadDataFile(fullfile(in.rec_file_fold,[rec_file '.h5'])); 
fs = s.header.AcquisitionSampleRate;
[V0,t] = formatWaveSurferSweeps(s); 
V = V0/gain; % actual voltage
if in.filt_order > 0    
    [b,a] = butter(in.filt_order,in.filt_cutoffs/(fs/2),in.filt_type);
    V = filtfilt(b,a,V); 
    fprintf('Applied %g order %s butterworth filter\n',in.filt_order,in.filt_type)
end
all_stim_names = cellstr(structfun(@(x) x.Name,s.header.StimulusLibrary.Stimuli,'UniformOutput',1));
stim_elem = find(strcmp(all_stim_names,stim_name));
stim = s.header.StimulusLibrary.Stimuli.(num2str(stim_elem,'element%g')).Delegate;
del = str2double(stim.Delay); 
pulse_dur = str2double(stim.PulseDuration);
dur = str2double(stim.Duration);
freq = 1/str2double(stim.Period);
amps = eval(sprintf('arrayfun(@(i) %s,1:%g,''UniformOutput'',1)',stim.Amplitude,s.header.NSweepsPerRun))';
amps_mA = amps*amp_per_V;
% amp = str2double(stim.Amplitude);
stim_vals = defineStimTrain(del,freq,dur);
exp_settings = ExperimentSettings(stim_vals,pulse_dur*2,pulse_dur/2,'sec',fs,...
                                   'stim_pulse_dur',pulse_dur);
exp_settings.convert2Frames(); 
align_out = calcStimAlignedResponses(V,exp_settings.stim_vals,...
                    exp_settings.baseline_wind,exp_settings.stim_wind);
V_aligned = align_out.mean_aligned;
bslines = mean(V_aligned(1:exp_settings.baseline_wind,:,:),1);
V_aligned_bs = V_aligned - bslines; % baseline subtracted voltage traces  
ta = 0:(1/fs):((size(V_aligned,1)-1)/fs);
ta = ta-ta(exp_settings.baseline_wind+1);
meanV = mean(V_aligned_bs(:,:,1:5),3,'omitnan');
% meanE = meanV/(iel*1e-3); % V/m  - Efield amplitude
ss_wind = exp_settings.baseline_wind + 1:(exp_settings.baseline_wind + exp_settings.stim_pulse_dur + 1);
ss_V = mean(meanV(ss_wind,:),1)';
% ss_E = mean(meanE(ss_wind,:),1);
ss_E = ss_V/(iel*1e-3); % V/m steady state E-field
[b,~,~,~,stats] = regress(ss_E,[ones(size(amps_mA)) amps_mA]); % center x at 0
Rsq = stats(1); 
p = stats(3); 
out = struct();
out.t = t;
out.V = V;
out.ta = ta;
out.meanV = meanV;
out.ss_wind = ss_wind;
out.ss_V = ss_V;
out.ss_E = ss_E;
out.E_slope = b(2); 
out.E_int = b(1); 
out.Rsq = Rsq;
out.p = p;
%% Plot
if plot_figs
    fig = figure('Position',[520         828        1418         454]); 
    plot(t,V0);
    xlabel('time (sec)'); ylabel('\Delta V (V)')
    legend(numericVec2chars(amps_mA,'%g mA'),'Box','off')
    title('Recorded V (not gain adjusted)'); box off; 
    xlim([t(1),t(end)])
    if save_figs
        printFig(fig,in.fig_fold,sprintf('%s_raw',rec_file));
    end
    %%
    fig2 = figure('Position',[475         134        1525         497]);
    subplot(1,2,1)
    plot(ta,meanV);
    xlabel('time (sec)'); ylabel('\Delta V (V)')
    box off;
    legend(numericVec2chars(amps_mA,'%g mA'),'Box','off','Location','NorthEast')
    title(sprintf('IEL = %g mm, gain = %gx',iel,gain))
    xlim([ta(1),ta(end)]);
    subplot(1,2,2)
    plot(amps_mA,ss_E,'o'); hold on;
    plot(amps_mA,b(1) + b(2)*amps_mA,'-','Color','r')
    xlabel('Current (mA)'); ylabel('Steady state |E| (V/m)')
    title(sprintf('%.2f V/m per mA. R^{2} = %.3f (p = %.3f)',...
                b(2),Rsq,p))
    box off;
    if save_figs
        printFig(fig2,in.fig_fold,sprintf('%s_meanV_E',rec_file));
    end
end