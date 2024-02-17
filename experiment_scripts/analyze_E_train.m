% Analyze E-field recordings saved with WaveSurfer
% Typical format is pulse trains applied at increasing amplitude with each
% sweep. Pulse train parameters extracted from saved data file, besides
% parameters specified below. 
% Recording settings
rec_file_base = '10Hz_50ms_PW_train_gain51x';
stim_name = '50ms_pulse_train_var_amp';
sweep1 = 1;
num_sweeps = 3; 
gain = 51; % amplifier gain
iel = 4.5; % mm- interelectrode length
amp_per_V = 1; % mA/V gain on stimulus isolator
plot_figs = 1;
save_figs = 0;
%% Analyze data
out = analyzeEtrainProt(rec_file_base,sweep1,num_sweeps,stim_name,gain,iel,...
                        amp_per_V,plot_figs,save_figs,'fig_fold','Efield_figs',...
                        'filt_order',2); 
E_slope =  out.E_slope; % V/m per mA