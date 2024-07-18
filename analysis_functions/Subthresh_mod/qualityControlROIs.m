function [data,exclude_rois] = qualityControlROIs(data,qc_settings,plot_inds,varargin)
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
in.exclude_rois = [];
in.print_level = 1; 
in = sl.in.processVarargin(in,varargin);
if isempty(qc_settings)
    qc_settings = struct(); 
    qc_settings.snr_cutoff = 2; % peak/std(bsline) must be above this value in all trials 
    qc_settings.all_peak_cutoff = 0; % peak deltaF/F0 before, during, and after stim must be above this value
    qc_settings.before_peak_cutoff = 0.05; % peak deltaF/F0 before stim must be above this value
    qc_settings.bsline_btwn_trial_per = -15; % baseline must stay above -10% of initial value across trials
    qc_settings.mean_peaks_before_per_diff = 60; % max deviation of mean peak within a trial from mean across trials
elseif strcmp(qc_settings,'off')
    exclude_rois = []; 
    % fprintf('Skipping quality control...\n')
    return; 
end
peaks = data.peaks_deltaF_F0_all;
dF_al2 = data.deltaF_F0_aligned2_all;  
peaksi = peaks(plot_inds);
dF_al2i = dF_al2(plot_inds);
exclude_rois = false(data.rois_all{1}{1}.num_rois,1);
% Quality control
%% SNR
if qc_settings.snr_cutoff > 0
    bsline_windi = data.exp_settings(1).baseline_wind;
    std_bslinesi = cellfun(@(x) permute(squeeze(std(x(1:bsline_windi,:,:,:,:),0,1)),[2 1 3 4]),...
                            dF_al2i,'UniformOutput',0); % num_trains x num_rois x num_stim x num_trials
    % mean of raw SNRs for every stim-evoked response
    mean_snrsi = cell2mat(cellfun(@(x,y) squeeze(mean(x./y,[3 4]))',...
                            peaksi,std_bslinesi,'UniformOutput',0)); % num_rois x num_lvls    
    
    
    % SNR of mean stim-averaged dF trace
    % mean_dF_al2i = cellfun(@(x) mean(x,[3 4 5]),dF_al2i,'UniformOutput',0); % mean dF trace across all trials/stim within amp for each roi
    % std_bslinesi_mean_dF = cell2mat(cellfun(@(x) squeeze(std(x(1:bsline_windi,:)))',mean_dF_al2i,'UniformOutput',0)); %num_rois x num_lvls
    % std_bslinesi_mean_dF = std_bslinesi_mean_dF(:,plot_data_inds{i});
    % spike_windi = 3;
    % peaksi_mean_dF = cell2mat(cellfun(@(x) max(x(bsline_windi+1:bsline_windi+1+spike_windi,:),[],1)',...
    %                     mean_dF_al2i,'UniformOutput',0));
    % mean_snrsi_mean_dF = peaksi_mean_dF./std_bslinesi_mean_dF; 
    
    exclude_rois_snr = all(mean_snrsi < qc_settings.snr_cutoff,2);
    exclude_rois = exclude_rois_snr | exclude_rois;
    if in.print_level > 0
        fprintf('%g/%g ROIs with mean SNR < %.2f in all trials/stim trains\n',sum(exclude_rois_snr),...
                length(exclude_rois_snr),qc_settings.snr_cutoff);    
    end
end
%% Peak amplitude with and without E-field
if qc_settings.all_peak_cutoff > 0
    mean_peaksi = cell2mat(cellfun(@(x) squeeze(mean(x,[3 4]))',peaksi,'UniformOutput',0));
    % mean_peaksi = cell2mat(cellfun(@(x) squeeze(mean(x,[1 3 4]))',peaks,'UniformOutput',0));
    % mean_peaksi = mean_peaksi(:,plot_inds);
    exclude_rois_peak = all(mean_peaksi < qc_settings.all_peak_cutoff,2); % ROIs failing peak quality criterion    
    if in.print_level > 0
        fprintf('%g/%g ROIs (%g additional) with mean peaks in all trials/stim trains < %.2f\n',...
               sum(exclude_rois_peak),length(exclude_rois),...
               sum(exclude_rois_peak & ~exclude_rois),qc_settings.all_peak_cutoff);
    end
    exclude_rois = exclude_rois_peak | exclude_rois; % ROIs failing at least 1 quality criterion
end
%% Peak amplitude before E-field
if qc_settings.before_peak_cutoff > 0
    mean_peaks_beforei_alltrials = cell2mat(cellfun(@(x) squeeze(mean(x(1,:,:,:),[1 3])),...
                                    peaksi,'UniformOutput',0)); % num_rois x num_trials (all amplitudes)
    mean_peaks_beforei = mean(mean_peaks_beforei_alltrials,2); % average across trials
    exclude_rois_peak_before = all(mean_peaks_beforei < qc_settings.before_peak_cutoff,2); % ROIs failing peak quality criterion    
    if in.print_level > 0
        fprintf('%g/%g ROIs (%g additional) with mean peaks before DC in all trials < %.2f\n',...
               sum(exclude_rois_peak_before),length(exclude_rois),...
               sum(exclude_rois_peak_before & ~exclude_rois),qc_settings.before_peak_cutoff);
    end
    exclude_rois = exclude_rois_peak_before | exclude_rois; % ROIs failing at least 1 quality criterion
end
%% Baseline stability across trials    
if qc_settings.bsline_btwn_trial_per ~= 0 && qc_settings.bsline_btwn_trial_per > -inf
    trial1_times = cellfun(@(x) x(1),data.trial_times_all,'UniformOutput',1); % extract 1st trial within condition
    [~,trial1_ind] = min(trial1_times(plot_inds)); 
    % trial2_times = cellfun(@(x) x(end),data{i}.trial_times_all,'UniformOutput',1); % extract last trial within condition
    % [~,trial2_ind] = max(trial2_times(plot_data_inds{i}));       
    mean_bslinesi = cellfun(@(x) squeeze(mean(x,[2 3])),data.baselines_all(plot_inds),'UniformOutput',0);    
    ntrials = cellfun(@(x) size(x,2),mean_bslinesi,'UniformOutput',1);
    if any(ntrials < max(ntrials))
        for i = 1:length(mean_bslinesi)
            if ntrials(i) < max(ntrials)
                % Pad with nans if fewer trials
                mean_bslinesi{i} = cat(2,mean_bslinesi{i},nan(size(mean_bslinesi{i},1),...
                                        max(ntrials)-size(mean_bslinesi{i},2)));            
            end
        end
    end
    mean_bslinesi = cell2mat(reshape(mean_bslinesi,1,1,length(mean_bslinesi)));
    % change in baseline relative to first trial
    mean_bslinesi_per_diff = 100*(mean_bslinesi - mean_bslinesi(:,1,trial1_ind))./mean_bslinesi(:,1,trial1_ind);               
    exclude_rois_bsline_btwn_trial = any(mean_bslinesi_per_diff < qc_settings.bsline_btwn_trial_per,[2 3]); % ROIs failing bseline fluctuation between trials quality criterion    
    if in.print_level > 0
        fprintf('%g/%g ROIs (%g additional) with baseline change < %.2f %% \n',...
                sum(exclude_rois_bsline_btwn_trial),length(exclude_rois),...
                sum(exclude_rois_bsline_btwn_trial & ~exclude_rois),qc_settings.bsline_btwn_trial_per);
    end
    exclude_rois = exclude_rois | exclude_rois_bsline_btwn_trial; 
end
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
% NOTE: will throw error if only 1 trial in one condition
% cv_peaks_beforei = std(mean_peaks_beforei,0,2)./mean(mean_peaks_beforei,2);    
if qc_settings.mean_peaks_before_per_diff > 0 && qc_settings.mean_peaks_before_per_diff < inf
    ntrials = cellfun(@(x) size(x,4),peaksi,'UniformOutput',1);
    if ~exist('mean_peaks_beforei_alltrials','var')
        mean_peaks_beforei_alltrials = cellfun(@(x) squeeze(mean(x(1,:,:,:),[1 3])),...
                                    peaksi,'UniformOutput',0); 
        if any(ntrials==1)
            mean_peaks_beforei_alltrials(ntrials==1) = cellfun(@(x) x',...
                                mean_peaks_beforei_alltrials(ntrials==1),...
                                'UniformOutput',0);                    
        end 
        % num_rois x num_trials (all amplitudes)
        mean_peaks_beforei_alltrials = cell2mat(mean_peaks_beforei_alltrials);
    end
    mean_peaks_before_per_diffi = abs(100*(mean_peaks_beforei_alltrials - mean(mean_peaks_beforei_alltrials,2))./mean(mean_peaks_beforei_alltrials,2));
    exclude_rois_peak_diff = any(mean_peaks_before_per_diffi > qc_settings.mean_peaks_before_per_diff,2); % ROIs failing peak quality criterion    
    if in.print_level > 0
        fprintf('%g/%g ROIs (%g additional) with >=1 trial mean peak before DC > %.1f %% different from mean across trials\n',...
                sum(exclude_rois_peak_diff),length(exclude_rois),...
                sum(exclude_rois_peak_diff & ~exclude_rois),...
                qc_settings.mean_peaks_before_per_diff);
    end
    exclude_rois = exclude_rois | exclude_rois_peak_diff; 
end

%% Remove ROIs from data and output
% combine exclude_rois from QC with input exclude_rois
if ~isempty(in.exclude_rois)
    exclude_rois_input = false(length(exclude_rois),1); % handles vector indices or logical vector
    exclude_rois_input(in.exclude_rois) = true;                
    if in.print_level > 0
    fprintf('%g/%g ROIs (%g additional) excluded based on input\n',...
            sum(exclude_rois_input),length(exclude_rois),...
            sum(exclude_rois_input & ~exclude_rois));
    end
    exclude_rois = exclude_rois | exclude_rois_input;    
end
data = removeROIsExpData(data,exclude_rois,'print_level',in.print_level);
end
% function Fout = calcBaselineMat(Fin,smoothness_param,asym_param)
%     Fout = zeros(size(Fin)); 
%     for i = 1:size(Fin,2)
%         for j = 1:size(Fin,3)
%             Fout(:,i,j) = asLS_baseline(Fin(:,i,j),smoothness_param,asym_param);
%         end
%     end
% end