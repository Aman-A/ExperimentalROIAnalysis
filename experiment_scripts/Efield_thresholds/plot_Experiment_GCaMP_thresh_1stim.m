%% Script to plot threshold train experiment
% Single trial
data_fold = fullfile(getDataFold('aman_thor'),'Efield_thresh_experiments'); 
exp_date = '240718';
reporter = 'GCaMP8f_SynmRuby';
dish = 'dish4';
div = 16; 

roiset_filename = 'RoiSet_auto_pos3.mat';
ps = plotTrialSettings;
ps.spike_thresh = 3; % >6 x std
ps.spike_window = 0.06; % sec
ps.spike_min_amp = 0.02; % 3% deltaF/F
isolator_mA_per_V = 10; 

% Enter E-field calibration
E_per_mA = 67.1; % V/m per mA


pulse_dur_ms = 0.2; % pulse duration in ms  
trial_ind = 5; % trial index (within pulse duration)
sweep_ind = 5;  % sweep index (within trial, after separating concatenated recording)

num_sweeps = 10; 
ps.condition = sprintf('thresh_%gms_1stim/thresh_%gms_1stim_trial%g',...
                        pulse_dur_ms,pulse_dur_ms,trial_ind); % 
E_recs_fold = sprintf('thresh_%gms_1stim',pulse_dur_ms);

% NOTE: assume same sweep amps for all trials
stim_file = sprintf('%s/E_trial1_%04d-%04d.h5',E_recs_fold,1,num_sweeps); 
% img_name = sprintf('trial_trial%g_%g',trial_ind,sweep_ind);
img_name = sprintf('%s_sweep%g',reindexFileNameForAndor('trial',trial_ind),...
                    sweep_ind);
%
stim_wind = 0.4; % window
baseline_wind = 0.03; % frames before stim/s to take baseline
sampling_rate = 100; % sampling rate (frames/sec)

exp_settings_all = WaveSurferStim2ExpSettings(stim_file,sampling_rate,...
                                           stim_wind,baseline_wind,'E_per_mA',...
                                           E_per_mA,'isolator_mA_per_V',isolator_mA_per_V);
amps = [exp_settings_all.stim_amps];
if length(exp_settings_all) == num_sweeps
    exp_settings = exp_settings_all(sweep_ind);
else
    exp_settings = exp_settings_all(1); 
end
% Plot settings
exp_fold = fullfile(data_fold,exp_date,reporter,dish);
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.analysis_funcs = {'peaks','peak_times','successful_spikes'};
ps.show_diff_image = []; % can include [1,2,3]
ps.roi_func_mode = 'combine'; % 'combine' or 'separate'
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 0;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0'  
ps.blank_frame_inds = 1; 
ps.rem_pbleach = 1;
ps.close_img_after_save = 1; 
%makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),{'test'},exp_settings,'img_stack_name','diffimages');
%
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,fullfile(exp_fold,roiset_filename),...
                   trace_axis,ps);
% detect APs
successful_spike = detectSpikesAlignedTraces(datai.func_output.deltaF_F0_aligned,...
                                            exp_settings,ps.spike_thresh,...
                                            'spike_window',ps.spike_window,...
                                            'min_amp',ps.spike_min_amp);
hold on; 
plot(trace_axis,datai.func_output.trec(exp_settings.stim_vals(successful_spike)),...
    trace_axis.YLim(2)*0.95*ones(sum(successful_spike),1),'r*')
if successful_spike
    fprintf('Threshold for %g ms pulse below %.3f V/m (%.3f mA)\n',...
            pulse_dur_ms,...
            amps(sweep_ind)*exp_settings_all(sweep_ind).E_per_mA,...
            amps(sweep_ind))
else
     fprintf('Threshold for %g ms pulse above %.3f V/m (%.3f mA)\n',...
         pulse_dur_ms,...
         amps(sweep_ind)*exp_settings_all(sweep_ind).E_per_mA,...
         amps(sweep_ind))
end
%% Plot all sweeps, same trial
trial_ind = 1; 
num_sweeps = 10; 
ps.condition = sprintf('thresh_%gms_1stim/thresh_%gms_1stim_trial%g',...
                        pulse_dur_ms,pulse_dur_ms,trial_ind); % 
reindexFileNameForAndor('trial',trial_ind)
img_names = numericVec2chars(1:num_sweeps,sprintf('%s_sweep%%g',...
                reindexFileNameForAndor('trial',trial_ind)));

% ps.condition = sprintf('thresh_%gms_1stim',pulse_dur_ms); % 
% img_names = numericVec2chars(1:num_sweeps,sprintf('%s_sweep_%%g',...
%                         reindexFileNameForAndor('trial',trial_ind)));
% img_names = {}; % use all images in condition folder
ps.load_processed_data = 0;
ps.save_fig = 0;
ps.show_diff_image = []; 
ps.overlay_trials = 1;
trials_data = plotTrials(img_names,exp_settings_all,fullfile(exp_fold,roiset_filename),ps);
successful_spikes = squeeze(trials_data.analysis.successful_spikes)';
above_thresh_amps = amps(successful_spikes);
above_thresh_amps_inds = find(successful_spikes);
if isempty(above_thresh_amps)
    fprintf('Threshold for %g ms pulse above %.3f V/m (%.3f mA)\n',...
            pulse_dur_ms,amps(end)*E_per_mA,amps(end))
elseif above_thresh_amps_inds(1) == 1
    fprintf('Threshold for %g ms pulse below %.3f V/m (%.3f mA)\n',...
            pulse_dur_ms,amps(1)*E_per_mA,amps(1))
else
    threshE = above_thresh_amps(1)*E_per_mA;
    lower_lim_threshE = amps(above_thresh_amps_inds(1)-1)*E_per_mA;
    thresh_window_per_size = 100*(threshE - lower_lim_threshE)./lower_lim_threshE; 
    fprintf('Threshold for %g ms pulse between %.3f to %.3f V/m \n(%.2f %% window, %.3f mA, %.3f V)\n',...
        pulse_dur_ms,lower_lim_threshE,threshE,thresh_window_per_size,...
        amps(above_thresh_amps_inds(1)),amps(above_thresh_amps_inds(1))/isolator_mA_per_V)
    fprintf('getThreshLadderSettings(%g,2.5,10);\n',round(amps(above_thresh_amps_inds(1))/isolator_mA_per_V,2))
    [~,start_amp,step_size] = getThreshLadderSettings(round(amps(above_thresh_amps_inds(1))/isolator_mA_per_V,2),2.5,10);
    fprintf('%g + %g*i\n',start_amp,step_size);
end
%% Plot all sweeps, all trials
pulse_dur_ms = 10;
num_trials = 5; 
num_sweeps = 10; 
E_recs_fold = sprintf('thresh_%gms_1stim',pulse_dur_ms);
stim_file = sprintf('%s/E_trial1_%04d-%04d.h5',E_recs_fold,1,num_sweeps); 
exp_settings_all = WaveSurferStim2ExpSettings(stim_file,sampling_rate,...
                                           stim_wind,baseline_wind,'E_per_mA',...
                                           E_per_mA,'isolator_mA_per_V',isolator_mA_per_V);

amps = [exp_settings_all.stim_amps]';
conditions = numericVec2chars(1:num_trials, ...
    sprintf('thresh_%gms_1stim/thresh_%gms_1stim_trial%%g',pulse_dur_ms,pulse_dur_ms));
img_names_all = arrayfun(@(x) numericVec2chars(1:num_sweeps,...
                                            sprintf('%s_sweep%%g',...
                                            reindexFileNameForAndor('trial',x))),...
                        1:num_trials,'UniformOutput',0);
ps.load_processed_data = 0;
ps.plot_func = 'deltaF_F0';
ps.save_fig = 1; 
roiset_filename_no_ext = getROIset_name(roiset_filename,'none');
summary_datafile = sprintf('%s_%s_%s_%s_%s_%gms_1stim',exp_date,reporter,dish,ps.roi_func_mode,...
                                    roiset_filename_no_ext,pulse_dur_ms);
out = plotTrials_multipleConditions(conditions,ps,exp_settings_all,...
                                    fullfile(exp_fold,roiset_filename),...
                                    'plot_overlaid',0,'summary_datafile',...
                                    summary_datafile,'img_names',img_names_all);
% convert to num_stim x num_trials array
successful_spikes_all = cell2mat(cellfun(@(x) x',out.successful_spikes,'UniformOutput',0)); 

% Plot threshold figs
cond_fold = sprintf('thresh_%gms_1stim',pulse_dur_ms); 
thresh_out = analyzeThresholdLadderTrials(amps,successful_spikes_all,...
                                'E_per_mA',E_per_mA,'plot_fig',1,...
                                'save_fig',1,'fig_fold',fullfile(cond_fold,...
                                                        ['figs_',trials_data.roiset_filename_no_ext]),...
                                'save_data',1,'data_filename',...
                                sprintf('thresh_data_%s',trials_data.roiset_filename_no_ext),...
                                'data_fold',cond_fold); % save to first trial folder
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
