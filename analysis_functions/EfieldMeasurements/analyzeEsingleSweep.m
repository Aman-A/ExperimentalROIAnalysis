function out = analyzeEsingleSweep(rec_file,stim_name,...
                            gain,iel,amp_per_V,plot_figs,save_figs,varargin)

if nargin == 0
    rec_file_base = 'test_10sec_trial';
    sweep_num = 1;
    rec_file = sprintf('%s_%04d',rec_file_base,sweep_num);
    stim_name = '10sec_DC';
    gain = 1; 
    iel = 4.5; % mm 
    amp_per_V = 1; % mA/V
end
in.rec_file_fold = '.';
in.fig_fold = 'figs';
in.filt_order = 0; 
in.filt_cutoffs = [59 61];
in.filt_type = 'stop';
in.ss_wind_frac = 0.5; % fraction of pulse to start calculation of steady state 
                       % value, e.g. 0.5 is last half of stimulus pulse, 0
                       % is full pulse duration
in.chan_ind = 1;                       
in = sl.in.processVarargin(in,varargin);

[~,~,ext] = fileparts(rec_file);
if ~strcmp(ext,'.h5') % missing extension, try adding .h5
    rec_file = [rec_file '.h5'];
end
s = ws.loadDataFile(fullfile(in.rec_file_fold,rec_file)); 
fs = s.header.AcquisitionSampleRate;
[V0,t] = formatWaveSurferSweeps(s); 
V = V0/gain;

if in.filt_order > 0  
    [b,a] = butter(in.filt_order,in.filt_cutoffs/(fs/2),in.filt_type);
    V = filtfilt(b,a,V);
    fprintf('Applied %g order %s butterworth filter\n',in.filt_order,in.filt_type)
end
stim_elems = s.header.StimulusLibrary.Stimuli;
stim_elem_names = fieldnames(stim_elems);
all_stim_names = cellstr(structfun(@(x) x.Name,s.header.StimulusLibrary.Stimuli,'UniformOutput',1));
stim_elem_ind = strcmp(all_stim_names,stim_name);
% for i = 1:length(stim_elem_names)
%     if strcmp(stim_elems.(stim_elem_names{i}).Name,stim_name)
%         stim_elem = stim_elems.(stim_elem_names{i});
%     end
% end
stim_elem = stim_elems.(stim_elem_names{stim_elem_ind});
stim = stim_elem.Delegate;
% stim = s.header.StimulusLibrary.Stimuli.(num2str(stim_elem,'element%g')).Delegate;
del = str2double(stim.Delay); 
pulse_dur = str2double(stim.Duration);
amp = str2double(stim.Amplitude); 
amp_mA = amp*amp_per_V;
exp_settings = ExperimentSettings(del,pulse_dur,del/2,'sec',fs,...
                                   'stim_pulse_dur',pulse_dur);
exp_settings.convert2Frames(); 
%% analyze trace
bsline = mean(V(exp_settings.baseline_wind_inds,:),1);
V_bs = V - bsline; % baseline subtracted voltage
ss_wind = (exp_settings.stim_vals(1) + round(exp_settings.stim_pulse_dur*in.ss_wind_frac)):...
         (exp_settings.stim_vals(1) + exp_settings.stim_pulse_dur + 1);
ss_V = mean(V_bs(ss_wind,in.chan_ind)); % steady state voltage in channel to analyze
ss_E = ss_V/(iel*1e-3); % V/m steady state E-field
fprintf('|E| = %.2f V/m (%.1f V/m per mA)\n',ss_E,ss_E/amp);
out = struct(); 
out.t = t;
out.V = V; 
out.V_bs = V_bs; 
out.ss_wind = ss_wind; 
out.amp_mA = amp_mA; 
out.ss_V = ss_V; 
out.ss_E  = ss_E; 
%% Plot
if plot_figs
    fig = figure('Position',[520         828        1418         454]); 
    plot(t,V/(iel*1e-3));
    xlabel('time (sec)'); 
%     label('\Delta V (V)');
    ylabel('|E| (V/m)')
    title(sprintf('E = %.2f V/m. I = %.3f mA. IEL = %g mm, gain = %gx',...
            ss_E,amp_mA,iel,gain))
    box off; 
    if size(V,2) > 1
        legend('Subthreshold','Suprathreshold current','Box','off')
    end
    if save_figs
        printFig(fig,in.fig_fold,sprintf('%s_V_vs_t',rec_file));
    end
end
end