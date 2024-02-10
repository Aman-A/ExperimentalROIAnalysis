function [data,exclude_rois] = qualityControlROIs(data,qc_settings,plot_inds)
%QUALITYCONTROLROIS ... 
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if isempty(qc_settings)
    qc_settings = struct(); 
    qc_settings.qc_snr_cutoff = 2; % peak/std(bsline) must be above this value in all trials 
    qc_settings.qc_peak_cutoff = 0.05; % peak deltaF/F0 must be above this value
    qc_settings.qc_bsline_btwn_trial_per = -15; % baseline must stay above -10% of initial value across trials
    qc_settings.qc_mean_peaks_before_per_diff = 60; % max deviation of mean peak within a trial from mean across trials
end
peaks = data.peaks_deltaF_F0_all;
dF_al2 = data.deltaF_F0_aligned2_all;     
% Quality control
%% SNR
bsline_windi = data.exp_settings(1).baseline_wind;
std_bslinesi = cellfun(@(x) permute(squeeze(std(x(1:bsline_windi,:,:,:,:),0,1)),[2 1 3 4]),...
                        dF_al2,'UniformOutput',0); % num_trains x num_rois x num_stim x num_trials
% mean of raw SNRs for every stim-evoked response
mean_snrsi = cell2mat(cellfun(@(x,y) squeeze(mean(x./y,[1 3 4]))',...
                        peaks,std_bslinesi,'UniformOutput',0)); % num_rois x num_lvls    
mean_snrsi = mean_snrsi(:,plot_inds);
% SNR of mean stim-averaged dF trace
% mean_dF_al2i = cellfun(@(x) mean(x,[3 4 5]),dF_al2i,'UniformOutput',0); % mean dF trace across all trials/stim within amp for each roi
% std_bslinesi_mean_dF = cell2mat(cellfun(@(x) squeeze(std(x(1:bsline_windi,:)))',mean_dF_al2i,'UniformOutput',0)); %num_rois x num_lvls
% std_bslinesi_mean_dF = std_bslinesi_mean_dF(:,plot_data_inds{i});
% spike_windi = data{i}.exp_settings(1).convert2Frames(data{i}.plot_settings.spike_window);
% peaksi_mean_dF = cell2mat(cellfun(@(x) max(x(bsline_windi+1:bsline_windi+1+spike_windi,:),[],1)',...
%                     mean_dF_al2i,'UniformOutput',0));
% peaksi_mean_dF = peaksi_mean_dF(:,plot_data_inds{i});
% mean_snrsi_mean_dF = peaksi_mean_dF./std_bslinesi_mean_dF; 

exclude_rois_snr = any(mean_snrsi < qc_settings.qc_snr_cutoff,2);
fprintf('%g/%g ROIs with mean SNR < %.2f\n',sum(exclude_rois_snr),...
        length(exclude_rois_snr),qc_settings.qc_snr_cutoff);    
%% Peak amplitude with and without E-field
mean_peaksi = cell2mat(cellfun(@(x) squeeze(mean(x,[1 3 4]))',peaks,'UniformOutput',0));
mean_peaksi = mean_peaksi(:,plot_inds);
exclude_rois_peak = any(mean_peaksi < qc_settings.qc_peak_cutoff,2); % ROIs failing peak quality criterion    
fprintf('%g/%g ROIs (%g additional) with mean peak < %.2f\n',...
       sum(exclude_rois_peak),length(exclude_rois_snr),...
       sum(exclude_rois_peak & ~exclude_rois_snr),qc_settings.qc_peak_cutoff);
exclude_rois = exclude_rois_peak | exclude_rois_snr; % ROIs failing at least 1 quality criterion
% Baseline stability across trials    
trial1_times = cellfun(@(x) x(1),data.trial_times_all,'UniformOutput',1); % extract 1st trial within condition
[~,trial1_ind] = min(trial1_times(plot_inds)); 
% trial2_times = cellfun(@(x) x(end),data{i}.trial_times_all,'UniformOutput',1); % extract last trial within condition
% [~,trial2_ind] = max(trial2_times(plot_data_inds{i}));       
mean_bslinesi = cellfun(@(x) squeeze(mean(x,[2 3])),data.baselines_all,'UniformOutput',0);
mean_bslinesi = mean_bslinesi(plot_inds);
mean_bslinesi = cell2mat(reshape(mean_bslinesi,1,1,length(mean_bslinesi)));
% change in baseline relative to first trial
mean_bslinesi_per_diff = 100*(mean_bslinesi - mean_bslinesi(:,1,trial1_ind))./mean_bslinesi(:,1,trial1_ind);               
exclude_rois_bsline_btwn_trial = any(mean_bslinesi_per_diff < qc_settings.qc_bsline_btwn_trial_per,[2 3]); % ROIs failing bseline fluctuation between trials quality criterion    
fprintf('%g/%g ROIs (%g additional) with baseline change < %.2f %% \n',...
        sum(exclude_rois_bsline_btwn_trial),length(exclude_rois),...
        sum(exclude_rois_bsline_btwn_trial & ~exclude_rois),qc_settings.qc_bsline_btwn_trial_per);
exclude_rois = exclude_rois | exclude_rois_bsline_btwn_trial; 
%% Baseline stability within trial (DC off)
% std of baselines within trial (stim and trains), take max between
% trials
% std_bslinesi = cellfun(@(x) squeeze(std(x(:,:,1,:),0,[2 3])),data{i}.baselines_all,'UniformOutput',0); 
% std_bslinesi = std_bslinesi(plot_data_inds{i});
% std_bslinesi = cell2mat(reshape(std_bslinesi,1,1,length(std_bslinesi)));
% cv_bslinesi = std_bslinesi./mean_bslinesi; 
% tic;
% dF_smooth = cellfun(@(x) calcBaselineMat(x,30,1e-4),data{i}.deltaF_F0_all,'UniformOutput',0); 
% toc
% exclude_rois_bsline_range_win_trial = any(cv_bslinesi < s.qc_bsline_range_win_trial,[2 3]); % ROIs failing bseline fluctuation between trials quality criterion    
% fprintf('%g/%g additional ROIs with baseline change < %.2f %% \n',sum(exclude_rois_bsline_range_win_trial & ~exclude_rois),...
%         length(exclude_rois_snr),s.qc_bsline_range_win_trial);
% exclude_rois = exclude_rois | exclude_rois_bsline_range_win_trial; 
%% Stable peak amplitude across trials
mean_peaks_beforei = cell2mat(cellfun(@(x) squeeze(mean(x(1,:,:,:),[1 3 4]))',...
                                peaks,'UniformOutput',0));
mean_peaks_beforei = mean_peaks_beforei(:,plot_inds);
% cv_peaks_beforei = std(mean_peaks_beforei,0,2)./mean(mean_peaks_beforei,2);    
mean_peaks_before_per_diffi = abs(100*(mean_peaks_beforei - mean(mean_peaks_beforei,2))./mean(mean_peaks_beforei,2));
exclude_rois_peak_diff = any(mean_peaks_before_per_diffi > qc_settings.qc_mean_peaks_before_per_diff,2); % ROIs failing peak quality criterion    
fprintf('%g/%g ROIs (%g additional) with >=1 trial mean peak before DC < %.1f %% different from mean across trials\n',...
        sum(exclude_rois_peak_diff),length(exclude_rois),...
        sum(exclude_rois_peak_diff & ~exclude_rois),...
        qc_settings.qc_mean_peaks_before_per_diff);
exclude_rois = exclude_rois | exclude_rois_peak_diff; 

%% Remove ROIs from data and output
data = removeROIsExpData(data,exclude_rois);
end
% function Fout = calcBaselineMat(Fin,smoothness_param,asym_param)
%     Fout = zeros(size(Fin)); 
%     for i = 1:size(Fin,2)
%         for j = 1:size(Fin,3)
%             Fout(:,i,j) = asLS_baseline(Fin(:,i,j),smoothness_param,asym_param);
%         end
%     end
% end