function out = analyzeEtrainProt(rec_file_base,sweep1,num_sweeps,...
                                gain,iel,amp_per_V,plot_figs,save_figs,varargin)
in.rec_file_fold = '.';
in.fig_fold = 'figs';
in.filt_order = 0; 
in.filt_cutoffs = [59 61];
in.filt_type = 'stop';
in.ss_wind_frac = 0.5; % fraction of pulse to start calculation of steady state 
                       % value, e.g. 0.5 is last half of stimulus pulse, 0
                       % is full pulse duration
in = sl.in.processVarargin(in,varargin);

rec_file = sprintf('%s_%04d-%04d',rec_file_base,sweep1,sweep1+num_sweeps-1);
s = ws.loadDataFile(fullfile(in.rec_file_fold,[rec_file '.h5'])); 
fs = s.header.AcquisitionSampleRate;
[V0,t,time_stamps] = formatWaveSurferSweeps(s); 
V = V0/gain; % actual voltage
if in.filt_order > 0        
    [b,a] = butter(in.filt_order,in.filt_cutoffs/(fs/2),in.filt_type);
    V = filtfilt(b,a,V); 
    fprintf('Applied %g order %s butterworth filter\n',in.filt_order,in.filt_type)
end
stim_elem_ind = s.header.StimulationTriggerIndex;
stim = s.header.StimulusLibrary.Stimuli.(num2str(stim_elem_ind,'element%g')).Delegate;
del = str2double(stim.Delay); 
dur = str2double(stim.Duration);
end_time = str2double(stim.EndTime);
if strcmp(stim.TypeString,'SquarePulse')
    pulse_dur = dur; 
    stim_vals = del;
    exp_settings = ExperimentSettings(stim_vals,min(end_time,pulse_dur*2),...
                                    min(del,pulse_dur/2),'sec',fs,...
                                    'stim_pulse_dur',pulse_dur);
elseif strcmp(stim.TypeString,'SquarePulseTrain')
    pulse_dur = str2double(stim.PulseDuration);    
    freq = 1/str2double(stim.Period);    
    stim_vals = defineStimTrain(del,freq,dur);
    exp_settings = ExperimentSettings(stim_vals,min(end_time,pulse_dur*2),...
                                       min(del,pulse_dur/2),'sec',fs,...
                                       'stim_pulse_dur',pulse_dur);
elseif strcmp(stim.TypeString,'File') % single pulse defind in file
    pulse_dur = dur; 
    stim_vals = del; 
    exp_settings = ExperimentSettings(stim_vals,pulse_dur,del,'sec',fs,...
                                   'stim_pulse_dur',pulse_dur);
end
exp_settings.convert2Frames();

amps = eval(sprintf('arrayfun(@(i) %s,1:%g,''UniformOutput'',1)',stim.Amplitude,num_sweeps))';
amps_mA = amps*amp_per_V;
% amp = str2double(stim.Amplitude);

exp_settings.convert2Frames(); 
align_out = calcStimAlignedResponses(V,exp_settings.stim_vals,...
                    exp_settings.baseline_wind,exp_settings.stim_wind);
V_aligned = align_out.mean_aligned;
bslines = mean(V_aligned(1:exp_settings.baseline_wind,:,:),1,'omitnan');
V_aligned_bs = V_aligned - bslines; % baseline subtracted voltage traces  
ta = 0:(1/fs):((size(V_aligned,1)-1)/fs);
ta = ta-ta(exp_settings.baseline_wind+1);
meanV = mean(V_aligned_bs,3,'omitnan');
% meanE = meanV/(iel*1e-3); % V/m  - Efield amplitude
% use part of pulse defind by ss_wind_frac
ss_wind = (exp_settings.baseline_wind + round(exp_settings.stim_pulse_dur*in.ss_wind_frac) + 1):...
         (exp_settings.baseline_wind + exp_settings.stim_pulse_dur + 1);
ss_V = mean(meanV(ss_wind,:),1)';
% ss_E = mean(meanE(ss_wind,:),1);
ss_E = ss_V/(iel*1e-3); % V/m steady state E-field

out = struct();
out.t = t;
out.V = V;
out.ta = ta;
out.meanV = meanV;
out.ss_wind = ss_wind;
out.amps_mA = amps_mA; 
out.ss_V = ss_V;
out.ss_E = ss_E;
if length(unique(amps_mA)) > 1
    [b,~,~,~,stats] = regress(ss_E,[ones(size(amps_mA)) amps_mA]); % center x at 0
    Rsq = stats(1); 
    p = stats(3); 
    out.E_slope = b(2); 
    out.E_int = b(1); 
    out.Rsq = Rsq;
    out.p = p;
else
    out.E_slope = ss_E./amps_mA; 
end
%% Plot
if plot_figs
    if in.filt_order > 0
        if strcmp(stim.TypeString,'SquarePulse')
            fig1_title_str = 'Recorded V (gain adjusted, filtered, baseline subtracted)';
        else
            fig1_title_str = 'Recorded V (gain adjusted and filtered)';
        end
    else
        fig1_title_str = 'Recorded V (gain adjusted)';
    end
    if length(unique(amps_mA)) > 1
        fig = figure('Position',[520         828        1418         454]); 
        plot(t,V);
        xlabel('time (sec)'); ylabel('\Delta V (V)')
        legend(numericVec2chars(amps_mA,'%g mA'),'Box','off')
        title(fig1_title_str); box off; 
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
    else
        if num_sweeps > 5
            plot_sweep_inds = round(linspace(1,num_sweeps,5));
        else
            plot_sweep_inds = 1:num_sweeps; 
        end
        fig = figure('Position',[520         828        1418         454]); 
        if strcmp(stim.TypeString,'SquarePulse')
            plot(ta,V_aligned_bs(:,plot_sweep_inds));
            xlim([ta(1),ta(end)])
        else
            plot(t,V(:,plot_sweep_inds));
            xlim([t(1),t(end)])
        end
        xlabel('time (sec)'); ylabel('\Delta V (V)')
        legend(numericVec2chars(plot_sweep_inds,'sweep %g'),'Box','off')
        title(fig1_title_str); box off;         
        if save_figs
            printFig(fig,in.fig_fold,sprintf('%s_raw',rec_file));
        end
        %% 
        fig2 = figure('Position',[475         134        1525         497]);
%         plot_E = ss_E./amps_mA;
%         ylabel_str = '|E| (V/m per mA)';
        plot_E = ss_E; 
        ylabel_str = '|E| (V/m)';
        plot(time_stamps-time_stamps(1),plot_E,'-ko');
%         xlabel('Sweep number');
        xlabel('time (sec)')
        ylabel(ylabel_str)
        title(sprintf('I = %g mA, IEL = %g mm, gain = %gx',amps_mA(1),iel,gain))
        box off;
        ax = gca;
        ylim1 = ax.YLim; 
        yyaxis right; 
%         plot(1:num_sweeps,100*ss_E/(ss_E(1)),'-ko');
%         ylim([0 max(ss_E)*1.2])
        ax2 = gca; ax2.YColor = 'k';
        box off;
        ax2.YLim = 100*(ylim1-abs(plot_E(1)))/(abs(plot_E(1)))';
        ylabel('% change vs. first sweep')
        if save_figs
            printFig(fig2,in.fig_fold,sprintf('%s_E_vs_sweep',rec_file));
        end
    end
end