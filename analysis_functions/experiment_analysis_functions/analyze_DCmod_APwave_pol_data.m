function analyze_DCmod_APwave_pol_data(data_or_data_params,amps,pol_amps,save_figs,varargin)
if nargin == 0
    data_or_data_params.exp_date = '230628';
    data_or_data_params.reporter = 'Archon';
    data_or_data_params.dish = 'dish2';    
    data_or_data_params.roiset_filename = 'RoiSet_pc_pos12';     
    amps = [-1,1];
    pol_amps = [-2,-1,1,2];
    save_figs = 0; 
end
in.data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
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
fig_fold = fullfile(exp_fold,['figs_' roiset_filename_no_ext]);

%%
meanAPs = cellfun(@(x) squeeze(mean(x,[2,4])),AP_data.deltaF_F0_aligned2_all,...
                'UniformOutput',0);
tAP = 1e3*AP_data.exp_settings(1).getTimeVector(size(meanAPs{1},1));
tAP = tAP - tAP(AP_data.exp_settings(1).baseline_wind + 1);

mean_pols = cell2mat(cellfun(@(x) squeeze(mean(x,[2,3])),pol_data.deltaF_F0_aligned_all,...
                'UniformOutput',0));
tpol = 1e3*pol_data.exp_settings(1).getTimeVector(size(mean_pols,1));
tpol = tpol - tpol(pol_data.exp_settings(1).baseline_wind + 1);
dF_ss_wind_inds = in.dF_ss_wind*pol_data.exp_settings(1).sampling_rate;
dF_ss = mean(mean_pols(dF_ss_wind_inds(1):dF_ss_wind_inds(2),:),1);

% normalize to AP peak
AP_trial_times = cellfun(@(x) max(x),AP_data.trial_times_all,'UniformOutput',1); 
pol_trial_times = cellfun(@(x) max(x),pol_data.trial_times_all,'UniformOutput',1);
[~,last_AP_cond_ind] = min(abs(AP_trial_times-min(pol_trial_times)));
% [~,last_AP_cond_ind] = max(cellfun(@(x) max(x),AP_data.rel_times_cond_starts,'UniformOutput',1));
% last_AP_cond_ind = 2;
normAP_trace = meanAPs{last_AP_cond_ind}(:,1); % control AP waveform of last DC mod trial
dF_ss_norm = 100*dF_ss/max(normAP_trace); % percent AP amplitude
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
%% Plot Waveforms averaged within condition/amp
stim_wind_inds = stim_index0:length(tAP);
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
        y_sbar_len = 5; % 1 % deltaF/F
        ylabel('\Delta F/F_{0} (%)')
    end
    if strcmp(in.align_AP_to,'max')        
        [~,max_inds] = max(yi(stim_wind_inds,:),[],1);
        ti = zeros(length(tAP),size(yi,2));
        for j = 1:size(yi,2)
            ti(:,j) = tAP - tAP(stim_wind_inds(max_inds(j))); % set t = 0 to max
        end   
    else
        ti = tAP;
    end
    y_ax2 = ax.Position(2) + ax.Position(4)*in.inset_y_scale_factor;
    lhands = plotTracesOverlaid(ti,yi,'cols',{'k';in.amp_cols{i}},...
                                'inset_pos',[0.4 y_ax2 in.inset_size],'add_xlabel',0,...
                                'x_lim2',[-2,8],'x_sbar_len2',1,...
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
%% Plot widths at fractions of max
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
%% Modulation of fwhm, peak, and ahp

plot_widths = mean_widths(:,:,frac_amps == in.plot_width);
norm_widths = 100*(plot_widths(2,:)-plot_widths(1,:))./plot_widths(1,:);
norm_AP_peaks = 100*(AP_peaks(2,:)-AP_peaks(1,:))./AP_peaks(1,:);
norm_AHP_amps = 100*(AHP_amps(2,:)-AHP_amps(1,:))./abs(AHP_amps(1,:));
% x_vals = amps;
[~,amp_inds_mod,amp_inds] = intersect(amps,pol_amps); % get corresponding current amps from polarization trials
x_vals = dF_ss_norm(amp_inds);
if any(amps == 0)
    amp_inds_mod = [amp_inds_mod(amps(amp_inds_mod)<0);find(amps==0);amp_inds_mod(amps(amp_inds_mod)>0)];
    x_vals = [x_vals(pol_amps(amp_inds)<0),0,x_vals(pol_amps(amp_inds)>0)];
end
fig = figure('Units','inches'); 
fig.Position = [10 0.5 7  8.5];
subplot(3,1,1)
plot(x_vals,norm_widths(amp_inds_mod),'-ko'); box off; hold on;
plot([x_vals(1),x_vals(end)],[0 0],'--k');
if in.plot_width == 0.5
    ylabel('\Delta FWHM (%)');
else
    ylabel(sprintf('\\Delta width at %g %% (%%)',100*in.plot_width))
end
% ylim([0.8 1.2])
% xlim(max(abs(x_vals))*[-1 1])
xlim([min(x_vals),max(x_vals)])
subplot(3,1,2)
plot(x_vals,norm_AP_peaks(amp_inds_mod),'-ko'); box off; hold on;
plot([x_vals(1),x_vals(end)],[0 0],'--k');
ylabel('\Delta Peak (%)')
% ylim([0.6 1.4])
% xlim(max(abs(x_vals))*[-1 1])
xlim([min(x_vals),max(x_vals)])
subplot(3,1,3)
plot(x_vals,norm_AHP_amps(amp_inds_mod),'-ko'); box off; hold on;
plot([x_vals(1),x_vals(end)],[0 0],'--k');
ylabel('\Delta AHP amp (%)')
sgtitle('Modulation of AP FWHM, amplitude, and AHP by DC')
% xlabel('Current amplitude (mA)')
xlabel('Polarization (% AP peak)')
% ylim([0.6 1.2])
% xlim(max(abs(x_vals))*[-1 1])
xlim([min(x_vals),max(x_vals)])
if save_figs
    if in.plot_width == 0.5
        fig_name = sprintf('AP_fwhm_peak_ahp_mod_sp%g',in.spline_interp);
    else
        fig_name = sprintf('AP_width%gp_peak_ahp_mod_sp%g',in.plot_width*100,in.spline_interp);
    end
    printFig(fig,fig_fold,fig_name)
end
%% Overlay polarization trials on last AP trial
% smooth_wind = 20; 
fig = figure; 
plot(tAP,100*normAP_trace,'Color',0.4*[1 1 1]);
hold on;
for i = 1:length(pol_amps)
    plot(tpol,100*mean_pols(:,i),'Color',in.pol_cols(i,:),'LineWidth',0.5);
    plot([0,1e3*pol_data.exp_settings(1).stim_pulse_dur/pol_data.exp_settings(1).sampling_rate],...
        dF_ss(i)*[100 100],'--','Color',in.pol_cols(i,:),'LineWidth',2);
end
box off; 
xlabel('time (ms)') 
xlim([-5 100])
% xlim([-5,100]);
ylabel('\Delta F/F_{0} (%)')
if save_figs
    printFig(fig,fig_fold,'AP_polarization_overlaid')
end
%% Plot polarization normalized to AP peak
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