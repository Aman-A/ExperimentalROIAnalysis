data_fold = fullfile(getDataFold('aman_thor'),'Efield_thresh_experiments'); 
exp_date = '240718';
reporter = 'GCaMP8f_SynmRuby';
dish = 'dish4';

% pulse_durs_ms = [0.1]; % pulse durations in ms
% trial_inds = {5}; 
pulse_durs_ms = [0.05,0.1,0.2,0.5,1,5,10]; % pulse durations in ms
trial_inds  = {1:5,1:5,1:5,1:5,1:5,1:5,1:5};
trial_len = 100; % length of individual trial 

%% Loop
exp_fold = fullfile(data_fold,exp_date,reporter,dish);

for i = 1:length(pulse_durs_ms)
    pulse_dur_ms = pulse_durs_ms(i);
    cond_foldi = sprintf('thresh_%gms_1stim',pulse_dur_ms);
    trial_indsi = trial_inds{i};
    for j = 1:length(trial_indsi)
        trial_ind = trial_indsi(j); 
        cond_suff = sprintf('trial%g',trial_ind); % repeating order of trials and suffixes
        output_fold_ij = fullfile(cond_foldi,sprintf('%s_%s',cond_foldi,cond_suff));
        rec_names = {[reindexFileNameForAndor('trial',trial_ind) '.fits']};
        separateMultiTrialRecordingsFunc(exp_fold,cond_foldi,{output_fold_ij},...
                                        rec_names,trial_len);
    end
end