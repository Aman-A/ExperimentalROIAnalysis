%% Script to plot threshold train experiment
% Single trial
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240626';
reporter = 'GCaMP8f_SynmRuby';
dish = 'dish7';
div = 15; 

roiset_filename = 'RoiSet_pc_pos4.zip';
ps = plotTrialSettings;

E_per_mA = 55.567; % V/m per mA 
trial_ind = 1; 

stim_file = sprintf('E_recs_thresh/E_trial_%04d.h5',trial_ind);
ps.condition = 'test_thresh'; % 
img_name = reindexFileNameForAndor('1ms_ladder',trial_ind);

% amps = getThreshLadderSettings(expected_thresh,per_step_size,num_steps)
% amps = getThreshLadderSettings(7,2.5,16)*E_per_mA % expected thresh of 7 mA, 5%
% steps, 16 steps
%
stim_wind = 0.4; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
sampling_rate = 100; % sampling rate (frames/sec)

exp_settings = WaveSurferStim2ExpSettings(stim_file,sampling_rate,...
                                           stim_wind,baseline_wind,'E_per_mA',...
                                           E_per_mA);
% Plot settings
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.analysis_funcs = {'peaks','peak_times','successful_spikes'};
ps.show_diff_image = []; % can include [1,2,3]
ps.roi_func_mode = 'combine'; % 'combine' or 'separate'
ps.save_processed_data = 1;
ps.load_processed_data = 0;
ps.save_fig = 2;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0'  
ps.blank_frame_inds = 1; 
ps.rem_pbleach = 1;
%makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),{'test'},exp_settings,'img_stack_name','diffimages');
%
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
% detect APs
std_thresh = 6;
successful_spikes = detectSpikesAlignedTraces(datai.func_output.deltaF_F0_aligned,...
                                            exp_settings,std_thresh,'spike_window',0.06);
hold on; 
plot(datai.func_output.trec(exp_settings.stim_vals(successful_spikes)),...
    trace_axis.YLim(2)*0.95*ones(sum(successful_spikes),1),'r*')
amps = exp_settings.stim_amps; 
above_thresh_amps = amps(successful_spikes);
above_thresh_amps_inds = find(successful_spikes);
threshE = above_thresh_amps(1)*exp_settings.E_per_mA;
lower_lim_threshE = amps(above_thresh_amps_inds(1)-1)*exp_settings.E_per_mA;
thresh_window_per_size = 100*(threshE - lower_lim_threshE)./lower_lim_threshE; 
fprintf('Threshold for %g ms pulse between %.3f to %.3f V/m (%.2f %% window)\n',...
        stim_pulse_dur*1e3,lower_lim_threshE,threshE,thresh_window_per_size)
%% Plot multiple trials, same condition
% ps.condition = 'test_thresh'; % +G direction
% trial_inds = 2:11; 
% stim_files = numericVec2chars(trial_inds,'E_recs_thresh/E_trial_%04d.h5');

ps.condition = 'test_thresh_negG'; % -G direction
trial_inds = 1:10; 
stim_files = numericVec2chars(trial_inds,'E_recs_thresh/E_trial_negG_%04d.h5');

img_names = numericVec2chars(trial_inds-1,'1ms_ladder_%g');
exp_settings_all = cellfun(@(x) WaveSurferStim2ExpSettings(x,sampling_rate,...
                                           stim_wind,baseline_wind,'E_per_mA',...
                                           E_per_mA),stim_files,'UniformOutput',1);

ps.spike_thresh = 6; % 6 x std
ps.spike_window = 0.06; % sec
% img_names = {}; % use all images in condition folder
ps.load_processed_data = 0;
ps.save_fig = 0;
ps.overlay_trials = 0; 
trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
successful_spikes_all = squeeze(trials_data.analysis.successful_spikes);
%% Plot threshold figs
thresh_out = analyzeThresholdLadderTrials(exp_settings.stim_amps,successful_spikes_all,...
                                'E_per_mA',E_per_mA,'plot_fig',1,...
                                'save_fig',1,'fig_fold',fullfile(ps.condition,...
                                                        ['figs_',trials_data.roiset_filename_no_ext]),...
                                'save_data',1,'data_filename',...
                                sprintf('thresh_data_%s',trials_data.roiset_filename_no_ext));
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
