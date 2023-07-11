function out = analyze_DCmod_APwave_pol_data(data_or_data_params,amps,pol_amps,save_figs,varargin)
if nargin == 0
    data_or_data_params.exp_date = '230628';
    data_or_data_params.reporter = 'Archon';
    data_or_data_params.dish = 'dish2';    
    data_or_data_params.roiset_filename = 'RoiSet_pc_pos12';     
    amps = [-1,1];
    pol_amps = [-2,-1,1,2];
    save_figs = 0; 
end
in.plot_figs = 1:6; % 1 - Plot Waveforms averaged within condition/amp
                    % 2 - Plot widths at fractions of max
                    % 3 - Plot modulation of fwhm, peak, and ahp
                    % 4 - Plot polarization trials overlaid on last AP trial
                    % 5 - Plot polarization normalized to AP peak
in.data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
in.fig_fold = ''; % default set below
in.roi_func_mode = 'combine';
in.amp_cols = {'b','r'};
in.pol_cols = flipud([ 0.6445         0    0.1484 % for 8
%             0.8398    0.1875    0.1523
            0.9531    0.4258    0.2617
%             0.9883    0.6797    0.3789
%             0.6680    0.8477    0.9102
            0.4531    0.6758    0.8164
%             0.2695    0.4570    0.7031
            0.1914    0.2109    0.5820]);
in.norm_AP_peak = 0; 
in.align_AP_to = 'none';
in.inset_size = [0.4 0.2]; % works for 2 panels, AP figure
in.inset_y_scale_factor = 0.3; % works for 2 panels, AP figure
in.ap_fig_size = [7.2 6]; % inches, AP figure
in.dF_ss_wind = [0.3 0.5]; % window to compute steady state in polarization trials
in.ap_height_est = [60;120]; % mV - range of AP heights
in.E_per_mA = 87; % V/m per mA
in.spline_interp = 0; 
in.spline_sampling_factor = 5; 
in.plot_width = 0.5; 
in.pol_smooth_wind = 30; 
in.rise_fit_dur = 30; % duration in ms of polarization stimulus pulse to 
                      % use for fitting rise time constant 
in.decay_fit_dur = 50; % duration in ms of post-stim phase to 
                      % use for fitting decay time constant                        
in.tau_fit_order = 2; % order for rise/decay time constant fitting
in = sl.in.processVarargin(in,varargin);
%% Load data if necessary
if isfield(data_or_data_params,'AP_data')
    AP_data = data_or_data_params.AP_data; % input experiment data struct directly
    pol_data = data_or_data_params.pol_data; 
    exp_date = AP_data.exp_date;
    reporter = AP_data.reporter;
    dish = AP_data.dish; 
    roiset_filename_no_ext = AP_data.roiset_filename_no_ext; 
    exp_fold = fullfile(in.data_fold,exp_date,reporter,dish);
else % load using fields of data_or_data_params
    exp_date = data_or_data_params.exp_date;
    reporter = data_or_data_params.reporter;
    dish = data_or_data_params.dish;
    roiset_filename_no_ext = data_or_data_params.roiset_filename;   
    exp_fold = fullfile(in.data_fold,exp_date,reporter,dish);
    AP_data = load(fullfile(exp_fold,sprintf('%s_%s_%s_%s_%s_APwave.mat',exp_date,...
                                        reporter,dish,in.roi_func_mode,...
                                        roiset_filename_no_ext)));
    pol_data = load(fullfile(exp_fold,sprintf('%s_%s_%s_%s_%s_pol.mat',exp_date,...
                                            reporter,dish,in.roi_func_mode,...
                                            roiset_filename_no_ext)));
    fprintf('Loaded data\n');
end
if isempty(in.fig_fold)
    fig_fold = fullfile(exp_fold,['figs_' roiset_filename_no_ext]);
else
    fig_fold = in.fig_fold; 
end
indicator_dir = AP_data.plot_settings.indicator_dir;
fs_pol = pol_data.exp_settings(1).sampling_rate; % Hz - sampling rate of polarization trials
pol_stim_pulse_dur_ms = 1e3*pol_data.exp_settings(1).stim_pulse_dur/fs_pol;
out = struct(); % output analyzed data
%%
% only average APs if AP successfully evoked
if isfield(AP_data,'successful_spikes')
    successful_spikes = cellfun(@squeeze,AP_data.successful_spikes,'UniformOutput',0); % [num_trains x num_AP]
else
    error('Need successful_spikes to compute averaged AP')
end
% Only average trials with successful AP 
meanAPs = cell(1,length(AP_data.deltaF_F0_aligned2_all));
for i = 1:length(AP_data.deltaF_F0_aligned2_all)
    si = successful_spikes{i}; 
    for j = 1:AP_data.exp_settings(1).num_trains
        meanAPs{i}(:,j) = indicator_dir*mean(AP_data.deltaF_F0_aligned2_all{i}(:,1,j,logical(si(j,:))),[2,3,4]);
        if any(~si(j,:))
            fprintf('%g missed spikes for amp %g, train %g of %g\n',sum(~si(j,:),'all'),...
                    amps(i),j,AP_data.exp_settings(1).num_trains); 
        end
    end        
end
% meanAPs = cellfun(@(x) squeeze(mean(x,[2,4])),AP_data.deltaF_F0_aligned2_all,...
%                 'UniformOutput',0);
tAP = 1e3*AP_data.exp_settings(1).getTimeVector(size(meanAPs{1},1));
tAP = tAP - tAP(AP_data.exp_settings(1).baseline_wind + 1);

mean_pols = cell2mat(cellfun(@(x) indicator_dir*squeeze(mean(x,[2,3])),pol_data.deltaF_F0_aligned_all,...
                'UniformOutput',0));
tpol = 1e3*pol_data.exp_settings(1).getTimeVector(size(mean_pols,1));
tpol = tpol - tpol(pol_data.exp_settings(1).baseline_wind + 1);
dF_ss_wind_inds = pol_data.exp_settings(1).baseline_wind + in.dF_ss_wind*fs_pol;
dF_ss = mean(mean_pols(dF_ss_wind_inds(1):dF_ss_wind_inds(2),:),1);

% normalize to AP peak
AP_trial_times = cellfun(@(x) max(x),AP_data.trial_times_all,'UniformOutput',1); 
pol_trial_times = cellfun(@(x) max(x),pol_data.trial_times_all,'UniformOutput',1);
[~,last_AP_cond_ind] = min(abs(AP_trial_times-min(pol_trial_times)));
% [~,last_AP_cond_ind] = max(cellfun(@(x) max(x),AP_data.rel_times_cond_starts,'UniformOutput',1));
% last_AP_cond_ind = 2;
normAP_trace = meanAPs{last_AP_cond_ind}(:,1); % control AP waveform of last DC mod trial
APpeak_norm = max(normAP_trace); % AP peak to use for normalization
dF_ss_norm = 100*dF_ss/APpeak_norm; % percent AP amplitude
pol_scaling_factor = in.ap_height_est/(max(normAP_trace)); % mV per deltaF/F0
dF_ss_norm_mV = dF_ss.*pol_scaling_factor;
[b,~,~,~,stats] = regress(dF_ss_norm',[ones(length(pol_amps),1),pol_amps']);
% [b,~,~,~,stats] = regress(dF_ss_norm',[pol_amps']);
% b = [0;b];
Rsq = stats(1); p = stats(3); 
pol_gain_mV_est = (in.ap_height_est/100)*b(2); % estimated polarization per mA
pol_gain_mV_est_E = pol_gain_mV_est/in.E_per_mA;
amp_labels = repmat({'depolarizing'},1,length(amps));
if b(2) < 0 % positive current hyperpolarizing
    amp_labels(amps > 0) = repmat({'hyperpolarizing'},1,sum(amps > 0));
else
    amp_labels(amps < 0) = repmat({'hyperpolarizing'},1,sum(amps < 0));
end
amp_labels(amps == 0) = repmat({''},1,sum(amps==0));

out.meanAPs = meanAPs;
out.tAP = tAP; 
out.mean_pols = mean_pols;
out.tpol = tpol; 
out.dF_ss = dF_ss; % steady state polarization at each current amplitude (dF/F0)
out.APpeak_norm = APpeak_norm; % AP peak amplitude (dF/F0)
out.dF_ss_norm = dF_ss_norm; % steady state polarization as percent of AP peak
out.pol_scaling_factor = pol_scaling_factor; % AP amplitude estimates in mV per dF/F0 (AP peak) (baseline to peak)
out.dF_ss_norm_mV = dF_ss_norm_mV; % steady state polarization as estimated mV using putative AP amps in mV and measured peak
out.pol_gain_mV_est = pol_gain_mV_est; % polarization sensitivity for current (mV per mA)
out.pol_gain_mV_est_E = pol_gain_mV_est_E; % polarization sensitivity for E-field (mV per V/m), using input E_per_mA for this elec pair
out.amp_labels = amp_labels;
%% Calculate FWHMs, peaks, and AHPs
frac_amps = 0.1:0.1:0.9;
% frac_amps = 0.5;
mean_widths = zeros(2,length(amps),length(frac_amps)); % [control; dc on]
% mean_fwhm = zeros(2,length(amps)); % [control; dc on]
stim_index0 = AP_data.exp_settings(1).baseline_wind + 1; 
AP_peaks = zeros(2,length(amps));
AHP_amps = zeros(2,length(amps));
AHP_inds = zeros(2,length(amps));
for j = 1:length(amps) % dc amp
    for i = 1:2    % [control, dc on]
        if in.spline_interp
            [t,y] = splineInterp(tAP*1e-3,meanAPs{j}(:,i),in.spline_sampling_factor);
            stim_index = stim_index0*in.spline_sampling_factor - in.spline_sampling_factor; 

        else
            t = tAP*1e-3;
            y = meanAPs{j}(:,i);
            stim_index = stim_index0; 
        end
        for k = 1:length(frac_amps) % frac amp
%             mean_widths(i,j,k) = 1e3*spikeWidth(tAP*1e-3,meanAPs{j}(:,i),stim_index,frac_amps(k),1);   
            mean_widths(i,j,k) = 1e3*spikeWidth(t,y,stim_index,frac_amps(k),0);                    
        end
        AP_peaks(i,j) = 100*max(meanAPs{j}(stim_index0:end,i)); % percent deltaF/F
%         [AHP_amps(i,j),AHP_inds(i,j)] = AHP_amp(tAP*1e-3,meanAPs{j}(:,i),stim_index0,0,[],...
%                                 'smooth_trace',1,'smooth_span',10);
        [AHP_amps(i,j),AHP_inds(i,j)] = AHP_amp(t,y,stim_index,0,[],...
                                'smooth_trace',1,...
                                'smooth_span',10*in.spline_sampling_factor,...
                                'max_ahp_wind',in.spline_sampling_factor*AP_data.exp_settings(1).convert2Frames(0.03)); % AHP max 30 ms
    end
end
if in.spline_interp
    AHP_inds = round((AHP_inds + in.spline_sampling_factor)/in.spline_sampling_factor);
end
% calculate change in width, AP peak, and AHP amp normalized to before DC
% waveform
plot_widths = mean_widths(:,:,frac_amps == in.plot_width);
norm_widths = 100*(plot_widths(2,:)-plot_widths(1,:))./plot_widths(1,:);
norm_AP_peaks = 100*(AP_peaks(2,:)-AP_peaks(1,:))./AP_peaks(1,:);
norm_AHP_amps = 100*(AHP_amps(2,:)-AHP_amps(1,:))./abs(AHP_amps(1,:));

out.frac_amps = frac_amps; 
out.mean_widths = mean_widths; 
out.AP_peaks = AP_peaks;
out.AHP_amps = AHP_amps;
out.AHP_inds = AHP_inds; 
out.spline_sampling_factor = in.spline_sampling_factor; 
%% Calculate rise and decay time constants

% Extract time vectors
t_decay = tpol(tpol>=pol_stim_pulse_dur_ms & tpol<=(pol_stim_pulse_dur_ms + in.decay_fit_dur)); % time vector for decay
t_decay = t_decay - pol_stim_pulse_dur_ms; 
t_rise = tpol(tpol>=0 & tpol <= in.rise_fit_dur); % time vector for decay
% Initialize data vectors
% decay
tau_d1s = zeros(1,length(pol_amps)); % decay time constants
tau_d2s = zeros(1,length(pol_amps)); % decay time constants
rsq_ds = zeros(1,length(pol_amps)); % decay time constants - R^2
decay_fitobjs = cell(1,length(pol_amps)); % fit objects for rise
p_ds = zeros(1,length(pol_amps)); % proportion of decay fit given by fast time constant
pol_decay = zeros(length(t_decay),length(pol_amps)); % portion of polarization traces used for fitting
% rise
tau_r1s = zeros(1,length(pol_amps)); % rise fast time constants 
tau_r2s = zeros(1,length(pol_amps)); % rise slow time constants
rsq_rs = zeros(1,length(pol_amps)); % rise time constants - R^2
rise_fitobjs = cell(1,length(pol_amps)); % fit objects for rise
p_rs = zeros(1,length(pol_amps)); % proportion of rise fit given by fast time constant
pol_rise = zeros(length(t_rise),length(pol_amps));
pol_snrs = zeros(1,length(pol_amps));
for i = 1:length(pol_amps)    
    if in.pol_smooth_wind > 0
        yi = smooth(mean_pols(:,i),in.pol_smooth_wind); 
    else
        yi = mean_pols(:,i);
    end
    % extract decay/rise portion of curve
%     yi_decay = yi(tpol>=pol_stim_pulse_dur_ms);
    yi_decay = yi(tpol>=pol_stim_pulse_dur_ms & tpol<=(pol_stim_pulse_dur_ms + in.decay_fit_dur));
    yi_rise = yi(tpol>=0 & tpol <= in.rise_fit_dur);
    % if hyperpolarizing, decay is positive, rise is negative, flip 
    yi_decay = sign(dF_ss(i))*yi_decay;
    yi_rise = sign(dF_ss(i))*yi_rise;
%     yi_rise = yi_rise - yi_rise(1); % start at 0
    % store 
    pol_decay(:,i) = yi_decay; 
    pol_rise(:,i) = yi_rise;       

    pol_snr = abs(dF_ss(i))/std(yi(1:pol_data.exp_settings(1).baseline_wind),0);
    pol_snrs(i) = pol_snr;
    if pol_snr > 3
        % fit decay (flip if hyperpolarized)
        decay_fit = fitExpDecay(t_decay,yi_decay,in.tau_fit_order,'max_taud',1e3,'align_traces',0);
        tau_d1s(i) = decay_fit.taud1; % decay time constant in ms
        
        rsq_ds(i) = decay_fit.rsquare; 
        decay_fitobjs{i} = decay_fit.fitobjs{1};
        % fit rise (flip if hyperpolarized)
        rise_fit = fitExpRise(t_rise,yi_rise,in.tau_fit_order,'max_taur',1e3,'align_traces',0);
        tau_r1s(i) = rise_fit.taur1; % decay time constant in ms
        if in.tau_fit_order == 2
            p_ds(i) = decay_fit.p;
            p_rs(i) = rise_fit.p;
            tau_d2s(i) = decay_fit.taud2; % decay time constant in ms
            tau_r2s(i) = rise_fit.taur2; % decay time constant in ms
        end
        rsq_rs(i) = rise_fit.rsquare; 
        rise_fitobjs{i} = rise_fit.fitobjs{1};       
    else
        tau_d1s(i) = nan;
        tau_d2s(i) = nan;
        rsq_ds(i) = nan;
        tau_r1s(i) = nan;
        tau_r2s(i) = nan;
        rsq_rs(i) = nan;
        p_ds(i) = nan;
        p_rs(i) = nan; 
        fprintf('SNR of %g (<3) for %g mA, skipping fit \n',pol_snr,pol_amps(i))
    end 
end
% decay data
out.t_decay = t_decay;
out.pol_decay = pol_decay; 
out.tau_d1s = tau_d1s;
out.tau_d2s = tau_d2s;
out.rsq_ds = rsq_ds;
out.p_ds = p_ds;
% rise data
out.t_rise = t_rise;
out.pol_rise = pol_rise;
out.tau_r1s = tau_r1s;
out.tau_r2s = tau_r2s;
out.rsq_rs = rsq_rs;
out.p_rs = p_rs; 
out.rise_fitobjs = rise_fitobjs;
out.pol_snrs = pol_snrs; 
%% Plot Waveforms averaged within condition/amp
stim_wind_inds = stim_index0:length(tAP);
if any(in.plot_figs == 1)
    fig = figure('Units','inches');
    fig.Position = [0.5 0.5 in.ap_fig_size];
    for i = 1:length(amps)
        ax = subplot(length(amps),1,i);
        if in.norm_AP_peak
            yi = meanAPs{i}./max(meanAPs{i},[],1);        
            ylabel('\Delta F/F_{0} (norm.)')
            y_sbar_len = 0.4; % 40 % peak
        else
            yi = meanAPs{i}*100;
            y_sbar_len = 5; % 5 % deltaF/F
            ylabel('\Delta F/F_{0} (%)')
        end
        if strcmp(in.align_AP_to,'max')        
            [~,max_inds] = max(yi(stim_wind_inds,:),[],1);
            ti = zeros(length(tAP),size(yi,2));
            for j = 1:size(yi,2)
                ti(:,j) = tAP - tAP(stim_wind_inds(max_inds(j))); % set t = 0 to max
            end   
            x_lim2 = [-2,8];
        else
            ti = tAP;
            x_lim2 = [-1 8];
        end
        y_ax2 = ax.Position(2) + ax.Position(4)*in.inset_y_scale_factor;
        lhands = plotTracesOverlaid(ti,yi,'cols',{'k';in.amp_cols{i}},...
                                    'inset_pos',[0.4 y_ax2 in.inset_size],'add_xlabel',0,...
                                    'x_lim2',x_lim2,'x_sbar_len2',1,...
                                    'y_sbar_len1',y_sbar_len,'y_sbar_len2',y_sbar_len,...
                                    'x_lim',[-5,40],'x_sbar_len1',5);
    %     l = plot(tAP,yi);
    %     l(1).Color = 'k';
    %     l(2).Color = in.amp_cols{i}; 
        box off; 
        xlim(ax,[-5,40]); 
        if i == length(amps)
            xlabel(ax,'time (ms)') 
        end       
        title(ax,amp_labels{i},'FontWeight','normal')
    %     title(sprintf('DC amp = %g mA',amps(i)));    
        hold on;
        if ~any(isnan(AHP_inds))
            plot(ax,tAP(AHP_inds(1,i)),yi(AHP_inds(1,i),1),'ko','MarkerSize',12);
            plot(ax,tAP(AHP_inds(2,i)),yi(AHP_inds(2,i),2),'o','Color',in.amp_cols{i},'MarkerSize',12);
        end
        legend(ax,lhands,'Before',sprintf('%g mA',amps(i)),'Box','off')
    end
    if save_figs
        printFig(fig,fig_fold,sprintf('meanAP_traces_norm%g_align_to_%s',in.norm_AP_peak,in.align_AP_to))
    end
end
%% Plot widths at fractions of max
if any(in.plot_figs == 2)
    fig = figure('Units','inches');
    fig.Position = [0.5 0.5 in.ap_fig_size];
    for j = 1:length(amps)
        ax = subplot(length(amps),1,j);
        for k = 1:length(frac_amps)
            bar(k-0.1,mean_widths(1,j,k)','FaceColor','k','BarWidth',0.2); hold on;
            bar(k+0.1,mean_widths(2,j,k)','FaceColor','r','BarWidth',0.2); 
        end
        box off; 
        title(sprintf('%g mA (%s)',amps(j),amp_labels{j}))
        ax.XTick = 1:length(frac_amps);
        ax.XTickLabel = frac_amps; 
        ylabel('Width (ms)')
    end
    xlabel('Fraction of amplitude')
    legend('Control','DC on','Box','off')
    if save_figs
        if in.spline_interp
            fig_name = sprintf('AP_widths_bar_spline1_fac%g',in.spline_sampling_factor); 
        else
            fig_name = 'AP_widths_bar_spline0';
        end
        printFig(fig,fig_fold,fig_name)
    end
end
%% Plot modulation of fwhm, peak, and ahp
% x_vals = amps;
[~,amp_inds_mod,amp_inds] = intersect(amps,pol_amps); % get corresponding current amps from polarization trials
if isempty(amp_inds)
%     pol_x_vals = b(1) + b(2)*amps;
%     xlabel_str = 'Polarization (% AP peak - est)';
    pol_x_vals = amps; 
    amp_inds_mod = find(amps~=0);
    xlabel_str = 'Current (mA)';
else
    pol_x_vals = dF_ss_norm(amp_inds);
    xlabel_str = 'Polarization (% AP peak)';
end
if any(amps == 0)
    amp_inds_mod = [amp_inds_mod(amps(amp_inds_mod)<0);find(amps==0);amp_inds_mod(amps(amp_inds_mod)>0)];
    if isempty(amp_inds)
        pol_x_vals = [pol_x_vals(amps<0),0,pol_x_vals(amps>0)];
    else
        pol_x_vals = [pol_x_vals(pol_amps(amp_inds)<0),0,pol_x_vals(pol_amps(amp_inds)>0)];
    end
end
out.pol_x_vals = pol_x_vals; % polarization values normalized to AP peak (dF_ss_norm)
out.pol_inds = amp_inds; % indices of polarization trials with amplitudes matching AP trials
out.ap_inds = amp_inds_mod; % indices of AP trials with subthreshold modulation amplitudes corresponding to polarization trials
                                % used to match AP features to polarization
                                % amplitudes
if any(in.plot_figs == 3)
    fig = figure('Units','inches'); 
    fig.Position = [10 0.5 7  8.5];
    subplot(3,1,1)
    plot(pol_x_vals,norm_widths(amp_inds_mod),'-ko'); box off; hold on;
    plot([pol_x_vals(1),pol_x_vals(end)],[0 0],'--k');
    if in.plot_width == 0.5
        ylabel('\Delta FWHM (%)');
    else
        ylabel(sprintf('\\Delta width at %g %% (%%)',100*in.plot_width))
    end
    % ylim([0.8 1.2])
    % xlim(max(abs(x_vals))*[-1 1])
    xlim([min(pol_x_vals),max(pol_x_vals)])
    subplot(3,1,2)
    plot(pol_x_vals,norm_AP_peaks(amp_inds_mod),'-ko'); box off; hold on;
    plot([pol_x_vals(1),pol_x_vals(end)],[0 0],'--k');
    ylabel('\Delta Peak (%)')
    % ylim([0.6 1.4])
    % xlim(max(abs(x_vals))*[-1 1])
    xlim([min(pol_x_vals),max(pol_x_vals)])
    subplot(3,1,3)
    plot(pol_x_vals,norm_AHP_amps(amp_inds_mod),'-ko'); box off; hold on;
    plot([pol_x_vals(1),pol_x_vals(end)],[0 0],'--k');
    ylabel('\Delta AHP amp (%)')
    sgtitle('Modulation of AP width, amplitude, and AHP by DC')
    % xlabel('Current amplitude (mA)')
    xlabel(xlabel_str)
    % ylim([0.6 1.2])
    % xlim(max(abs(x_vals))*[-1 1])
    xlim([min(pol_x_vals),max(pol_x_vals)])
    if save_figs
        if in.plot_width == 0.5
            fig_name = sprintf('AP_fwhm_peak_ahp_mod_sp%g',in.spline_interp);
        else
            fig_name = sprintf('AP_width%gp_peak_ahp_mod_sp%g',in.plot_width*100,in.spline_interp);
        end
        printFig(fig,fig_fold,fig_name)
    end
end
%% Plot polarization trials overlaid on last AP trial
if any(in.plot_figs == 4)
    fig = figure; 
    plot(tAP,100*normAP_trace,'Color',0.4*[1 1 1]);
    ax = gca;
    hold(ax,'on')
    ax2 = axes('Position',[0.4 0.4 0.5 0.4]);
    % plot(ax2,tAP,100*normAP_trace,'Color',0.4*[1 1 1]);
    % fc = 100; % Hz
    % [b,a] = butter(1,fc/(fs_pol/2),'low');
    for i = 1:length(pol_amps)
        if in.pol_smooth_wind > 0
            yi = 100*smooth(mean_pols(:,i),in.pol_smooth_wind);
    %         yi = 100*filtfilt(b,a,mean_pols(:,i));
        else
            yi = 100*mean_pols(:,i);
        end
        plot(ax,tpol,yi,'Color',in.pol_cols(i,:),'LineWidth',1);
        plot(ax,[0,pol_stim_pulse_dur_ms],...
            dF_ss(i)*[100 100],'--','Color',in.pol_cols(i,:),'LineWidth',2);
        % Inset
    
        hold on;
        plot(ax2,tpol,yi,'Color',in.pol_cols(i,:),'LineWidth',1);
        plot(ax2,[0,pol_stim_pulse_dur_ms],...
            dF_ss(i)*[100 100],'--','Color',in.pol_cols(i,:),'LineWidth',2);
    end
    box(ax,'off')
    xlabel(ax,'time (ms)') 
    xlim(ax,[-5 100])
    % xlim([-5,100]);
    ylabel(ax,'\Delta F/F_{0} (%)')
    box(ax2,'off');
    ax2.XLim = [-50 pol_stim_pulse_dur_ms+100];
    ax2.YLim = max(abs(ax2.YLim))*[-1 1];
    plot(ax2,ax2.XLim,[0 0],'-','Color',0*[1 1 1],'LineWidth',0.5)
    if save_figs
        printFig(fig,fig_fold,sprintf('AP_polarization_overlaid_smooth%g',in.pol_smooth_wind))
    end
end
%% Plot polarization normalized to AP peak
if any(in.plot_figs == 5)
    est_cols = lines(2); 
    fig = figure('Units','inches'); 
    fig.Position = [3 2 12.5 6];
    ax = subplot(1,2,1);
    plot(pol_amps,dF_ss_norm,'ko'); hold on;
    plot(pol_amps,b(1) + b(2)*pol_amps,'--k');
    xlabel('Current amplitude (mA)');
    ylabel('Polarization (% AP amp)');
    box off; 
    title('Polarization normalized to AP amplitude','FontWeight','normal')
    if b(2) > 0
        text(ax.XLim(1) + 0.5*diff(ax.XLim),ax.YLim(1)+0.1*diff(ax.YLim),...
                sprintf('R^2 = %.3f, p = %.3f\n',Rsq,p),'FontSize',16)
    else
        text(ax.XLim(1) + 0.5*diff(ax.XLim),ax.YLim(1)+0.8*diff(ax.YLim),...
            sprintf('R^2 = %.3f, p = %.3f\n',Rsq,p),'FontSize',16)
    end
    subplot(1,2,2)
    l1 = plot(pol_amps,dF_ss_norm_mV,'*'); hold on;
    l2 = plot(pol_amps,(in.ap_height_est/100)*(b(1) + b(2)*pol_amps),'--k');
    l2(1).Color = est_cols(1,:);
    l2(2).Color = est_cols(2,:);
    ylabel('Estimated polarization (mV)');
    box off;
    xlabel('Current amplitude (mA)');
    title(sprintf('%.1f to %.1f mV per mA\n(est. AP amp of %g to %g mV)',...
            pol_gain_mV_est,in.ap_height_est),'FontWeight','normal')
    legend(l1,numericVec2chars(in.ap_height_est,'AP amp = %g mV'),'Box','off',...
           'Location','best')
    fprintf('R^2 = %.4f, p = %.4f\n',Rsq,p)
    fprintf('Estimated polarization sensitivity: %.1f to %.1f uV per V/m\n',...
             pol_gain_mV_est_E*1e3)
    fprintf('Y-intercept (%g %%), estimated range: %.1f to %.1f mV\n',b(1),...
        (in.ap_height_est(1)/100)*b(1),(in.ap_height_est(2)/100)*b(1))
    if save_figs
        printFig(fig,fig_fold,'Polarization_vs_current_est')
    end
end
%% Plot polarization rise and decay time constant fits fits
if any(in.plot_figs==6)
    fig = figure('Units','inches');
    fig.Position(3:4) = [15 7]; 
    for i = 1:length(pol_amps)
%         ax1 = subplot_tight(length(pol_amps),2,2*i-1,[0.1,0.1]);
        ax1 = subplot_tight(2,length(pol_amps),i,[0.1,0.1]);
        plot(ax1,t_rise,100*sign(dF_ss(i))*pol_rise(:,i),'k-'); hold(ax1,'on')
        if ~isempty(rise_fitobjs{i})
            plot(ax1,t_rise,100*sign(dF_ss(i))*rise_fitobjs{i}(t_rise),'r--');
        end
        title(ax1,sprintf('%g mA: rise',pol_amps(i)),'FontWeight','normal')        
%         ylabel(ax1,'\Delta F/F_{0} (%)')        
%         ax2 = subplot_tight(length(pol_amps),2,2*i,[0.1,0.1]);
        ax2 = subplot_tight(2,length(pol_amps),length(pol_amps)+i,[0.1,0.1]);
        plot(ax2,t_decay,100*sign(dF_ss(i))*pol_decay(:,i),'k-'); hold(ax2,'on');
        if ~isempty(decay_fitobjs{i})
            plot(ax2,t_decay,100*sign(dF_ss(i))*decay_fitobjs{i}(t_decay),'r--');        
        end
        title(ax2,sprintf('%g mA: decay',pol_amps(i)),'FontWeight','normal')
%         title('decay');
        box([ax1,ax2],'off')        
        % Add text with fit params
        if dF_ss(i) < 0 % hyperpolarizing
            text_y_pos1 = ax1.YLim(1) + range(ax1.YLim)*0.65;
            text_y_pos2 = ax2.YLim(1) + range(ax2.YLim)*0.1;
        else
            text_y_pos1 = ax1.YLim(1) + range(ax1.YLim)*0.2;
            text_y_pos2 = ax2.YLim(1) + range(ax2.YLim)*0.5;
        end
        text_x_pos1 = ax1.XLim(1) + 0.45*range(ax1.XLim);
        text_x_pos2 = ax2.XLim(1) + 0.4*range(ax2.XLim);
        if in.tau_fit_order == 2 && ~isnan(rsq_rs(i))
            rise_fit_text = sprintf('R^{2} = %.2f\n \\tau_{f} = %.1f (%.1f %%), \\tau_{s} = %.1f',...
                                    rsq_rs(i),tau_r1s(i),p_rs(i)*100,tau_r2s(i));
            decay_fit_text = sprintf('R^{2} = %.2f\n \\tau_{f} = %.1f (%.1f %%), \\tau_{s} = %.1f',...
                                    rsq_ds(i),tau_d1s(i),p_ds(i)*100,tau_d2s(i));
            text(ax1,text_x_pos1,text_y_pos1,rise_fit_text)
            text(ax2,text_x_pos2,text_y_pos2,decay_fit_text)
        else
            % Need to implement
        end        
        xlabel(ax2,'time (ms)');           
        if i == 1
            ylabel([ax1,ax2],'\Delta F/F_{0} (%)');           
        end
%         if i == length(pol_amps)
%             xlabel([ax1,ax2],'time (ms)');           
%         end      
%         ylim(ax1,100*max(abs(pol_rise),[],'all')*[-1.1 1.1]);
%         ylim(ax2,100*max(abs(pol_decay),[],'all')*[-1.1 1.1]);
    end
    if save_figs
        printFig(fig,fig_fold,sprintf('Polarization_tau_fits_smooth%g',in.pol_smooth_wind))
    end
end