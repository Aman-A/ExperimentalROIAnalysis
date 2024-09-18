data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240826';
reporter = 'Archon';
dish = 'dish1';
div = 20; 

roiset_filename = 'RoiSet_pc';
roi_func_mode = 'combine';
transform_type = 'none';
registration_rec = '';

% pol_amps = [-200,-100,-50,50,100,200];
pol_amps = [-200,-100,-50,50,100,200]/51;
pol_cols = flipud([ 0.6445         0    0.1484 % for 8
            % 0.8398    0.1875    0.1523
            0.9531    0.4258    0.2617
            0.9883    0.6797    0.3789
            0.6680    0.8477    0.9102
            0.4531    0.6758    0.8164
            % 0.2695    0.4570    0.7031
            0.1914    0.2109    0.5820]);
dF_ss_wind = [0.3 0.5]; % window to compute steady state in polarization trials
ap_height_est = [60;120]; % mV - range of AP heights
E_per_mA = 51; % V/m per mA
%% Load data
exp_fold = fullfile(data_fold,exp_date,reporter,dish); 
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         transform_type,...
                                            registration_rec);  
AP_data = load(fullfile(exp_fold,sprintf('%s_%s_%s_%s_%s_APwave.mat',exp_date,...
                                        reporter,dish,roi_func_mode,...
                                        roiset_filename_no_ext)));
pol_data = load(fullfile(exp_fold,sprintf('%s_%s_%s_%s_%s_pol.mat',exp_date,...
                                        reporter,dish,roi_func_mode,...
                                        roiset_filename_no_ext)));
fprintf('Loaded data\n')
%%
save_figs = 0; 
all_data = struct();
all_data.AP_data = AP_data;
all_data.pol_data = pol_data;

opts = struct(); 
opts.plot_figs = [4];
opts.data_fold = data_fold;
opts.pol_cols = pol_cols; 
opts.E_per_mA = E_per_mA; 
opts.mean_AP_peak_align = 1; % peak align before averaging
opts.norm_AP_peak = 0; 
opts.align_AP_to = 'none'; % align averaged traces for visualization
opts.inset_size = [0.3 0.1];
opts.inset_y_scale_factor = 0.4; 
opts.ap_fig_size = [8.9 11.8]; % inches
opts.spline_interp = 1;
opts.spline_sampling_factor = 5; % 10 kHz
opts.pol_smooth_wind = 30; 
opts.tau_fit_order = 1; 
opts.tau_fit_offset_on = 0; 
opts.rise_fit_dur = 100; 
opts.decay_fit_dur = 100; 
% opts.plot_pol_x_vals = 'current';
opts.roi_func_mode = roi_func_mode;
opts.units = 'mA'; 

anal_out = analyze_DCmod_APwave_pol_data(all_data,0,pol_amps,save_figs,opts);
