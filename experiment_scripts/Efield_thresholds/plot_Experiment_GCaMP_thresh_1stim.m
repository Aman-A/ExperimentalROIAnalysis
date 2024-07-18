%% Script to plot threshold train experiment
% Single trial
data_fold = fullfile(getDataFold('aman_thor'),'Efield_thresh_experiments'); 
exp_date = '240715';
reporter = 'GCaMP8f_SynmRuby';
dish = 'dish1';
div = 20; 

roiset_filename = 'RoiSet_pc_pos0_soma.zip';
ps = plotTrialSettings;
ps.spike_thresh = 6; % 6 x std
ps.spike_window = 0.1; % sec

pulse_dur_ms = 1; % pulse duration in ms  
E_per_mA = 68.524; % V/m per mA 
% E_per_mA = 65.27;
isolator_mA_per_V = 10; 
trial_ind = 1; 
sweep_ind = 7; 
num_sweeps = 10; 
E_recs_fold = sprintf('E_recs_%gms_1stim',pulse_dur_ms);
ps.condition = sprintf('thresh_%gms_1stim_trial%g',pulse_dur_ms,trial_ind); % 

stim_file = sprintf('%s/E_trial_%04d-%04d.h5',E_recs_fold,1,num_sweeps);
img_name = sprintf('trial_trial%g_%g',trial_ind,sweep_ind);

% stim_pulse_durs: 50 us, 100 us, 200 us, 500 us, 1 ms, 5 ms
% expected thresholds: _, _, _, _, 7 mA, _
% amps = getThreshLadderSettings(expected_thresh,per_step_size,num_steps)
% amps = getThreshLadderSettings(7,2.5,16)*E_per_mA % expected thresh of 7 mA, 5%
% steps, 16 steps
%
stim_wind = 0.38; % window
baseline_wind = 0.1; % frames before stim/s to take baseline
sampling_rate = 100; % sampling rate (frames/sec)

exp_settings_all = WaveSurferStim2ExpSettings(stim_file,sampling_rate,...
                                           stim_wind,baseline_wind,'E_per_mA',...
                                           E_per_mA,'isolator_mA_per_V',isolator_mA_per_V);
if length(exp_settings_all) == num_sweeps
    exp_settings = exp_settings_all(sweep_ind);
else
    exp_settings = exp_settings_all(1); 
end
% Plot settings
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.analysis_funcs = {'peaks','peak_times','successful_spikes'};
ps.show_diff_image = [4]; % can include [1,2,3]
ps.roi_func_mode = 'combine'; % 'combine' or 'separate'
ps.save_processed_data = 1;
ps.load_processed_data = 0;
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0'  
ps.blank_frame_inds = 1; 
ps.rem_pbleach = 1;
ps.close_img_after_save = 1; 
%makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),{'test'},exp_settings,'img_stack_name','diffimages');
%
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
% detect APs
successful_spikes = detectSpikesAlignedTraces(datai.func_output.deltaF_F0_aligned,...
                                            exp_settings,ps.spike_thresh,...
                                            'spike_window',ps.spike_window);
hold on; 
plot(trace_axis,datai.func_output.trec(exp_settings.stim_vals(successful_spikes)),...
    trace_axis.YLim(2)*0.95*ones(sum(successful_spikes),1),'r*')

%%
% amps = [exp_settings.stim_amps]; 
% above_thresh_amps = amps(successful_spikes);
% above_thresh_amps_inds = find(successful_spikes);
% threshE = above_thresh_amps(1)*exp_settings.E_per_mA;
% lower_lim_threshE = amps(above_thresh_amps_inds(1)-1)*exp_settings.E_per_mA;
% thresh_window_per_size = 100*(threshE - lower_lim_threshE)./lower_lim_threshE; 
% fprintf('Threshold for %g ms pulse between %.3f to %.3f V/m (%.2f %% window)\n',...
%         stim_pulse_dur*1e3,lower_lim_threshE,threshE,thresh_window_per_size)
%% Plot multiple trials, same condition
trial_ind = 1; 
ps.condition = sprintf('thresh_%gms_1stim_trial%g',pulse_dur_ms,trial_ind); % 
img_names = numericVec2chars(1:num_sweeps,sprintf('trial_trial%g_%%g',trial_ind));
% img_names = {}; % use all images in condition folder
ps.load_processed_data = 0;
ps.save_fig = 0;
ps.show_diff_image = []; 
ps.overlay_trials = 1;
trials_data = plotTrials(img_names,exp_settings_all,roiset_filename,ps);
successful_spikes_all = squeeze(trials_data.analysis.successful_spikes)';
%% Plot multiple trials of all amps
num_trials = 2; 
conditions = numericVec2chars(1:num_trials, sprintf('thresh_%gms_1stim_trial%%g',pulse_dur_ms));
out = plotTrials_multipleConditions(conditions,ps,exp_settings_all,roiset_filename,...
                                    'plot_overlaid',0);
% convert to num_stim x num_trials array
successful_spikes_all = cell2mat(cellfun(@(x) x',out.successful_spikes,'UniformOutput',0)); 

%% Plot threshold figs
thresh_out = analyzeThresholdLadderTrials([exp_settings_all.stim_amps],successful_spikes_all,...
                                'E_per_mA',E_per_mA,'plot_fig',1,...
                                'save_fig',1,'fig_fold',fullfile(ps.condition,...
                                                        ['figs_',trials_data.roiset_filename_no_ext]),...
                                'save_data',1,'data_filename',...
                                sprintf('thresh_data_%s',trials_data.roiset_filename_no_ext),...
                                'data_fold',ps.condition);
threshE = thresh_out.thresh;
% fit to logistic regression
% amps_all = cell2mat(arrayfun(@(x) x.stim_amps',exp_settings_all,'UniformOutput',0));
% x = amps_all(:,1)*E_per_mA;
% y = mean_spike_prob;
% fit_eqn = 'a./(1 + exp(-b*(x - c)))'; 
% upper_bounds = [1 1e3 max(x)];
% lower_bounds = [0.001 0 min(x)];
% start_points = [1.1*max(y,[],'all'),1,mean(x)];
% s = fitoptions('Method','NonlinearLeastSquares',...
%             'Lower',lower_bounds,...
%             'Upper',upper_bounds,...
%             'Startpoint',start_points);
% f = fittype(fit_eqn,'options',s);
% [fitobj,gof,~] = fit(x,y,f);
% inv_logit = @(y,a,b,c) c - log(a./y - 1)/b;% inverted logit, input coeffs and y, outputs x
% thresh1 = inv_logit(0.5,fitobj.a,fitobj.b,fitobj.c);
