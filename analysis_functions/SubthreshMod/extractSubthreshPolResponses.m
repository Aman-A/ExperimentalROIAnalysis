function out = extractSubthreshPolResponses(data,stim_amps,dF_ss_wind,varargin)
%EXTRACTSUBTHRESHMODRESPONSES ... 
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
% Note: assumes uniform sampling rate across experiments
% AUTHOR    : Aman Aberra 
in.min_snr = 2; % minimum SNR : peak/std(baseline)
in.check_snr_amps = [-1 1]; % mA
in = sl.in.processVarargin(in,varargin);
if isstruct(data) % reformat to cell array
    data = {data};
    stim_amps = {stim_amps};
    num_dishes = 1;
else
    num_dishes = length(data);
end
% get mean stim-aligned deltaF/F0 traces
indicator_dir = data{1}.plot_settings.indicator_dir;
dF_ss_wind_inds = dF_ss_wind*data{1}.exp_settings(1).sampling_rate; % window to calculate SS in
mean_deltaF_F0_aligned_all = cellfun(@(x) x.mean_deltaF_F0_aligned_all,data,...
                                    'UniformOutput',0);
pol_dF_all = cell(num_dishes,1);
pol_dF_ss_all = cell(num_dishes,1);
pol_snr_all = cell(num_dishes,1);
exclude_rois_pol = cell(num_dishes,1); % rois to exclude from polarization rois
% Get polarization data and exclude ROIs with low SNR
for i = 1:num_dishes
    % mean deltaF/F traces: num_timepoints x num_rois x num_amps
    dFi = cell2mat(reshape(mean_deltaF_F0_aligned_all{i},1,1,[]));     
    dF_ss = squeeze(indicator_dir*mean(dFi(dF_ss_wind_inds(1):dF_ss_wind_inds(2),:,:),1))';    
    std_bsline = squeeze(std(dFi(1:data{i}.exp_settings(1).baseline_wind,:,:),0,1))';
    snri = abs(dF_ss)./std_bsline;
    if data{i}.rois_all{1}{1}.num_rois == 1
        dF_ss = dF_ss'; % transpose to [num_amps x num_rois]
        snri = snri'; 
    end  
    pol_dF_all{i} = dFi;
    pol_dF_ss_all{i} = dF_ss;
    pol_snr_all{i} = snri; 
    % exclude rois with SNR < min_snr    
    [~,~,check_amp_inds] = intersect(in.check_snr_amps,stim_amps{i});
    if isempty(check_amp_inds) % use highest amplitudes available from this dish
        [~,min_ind] = min(stim_amps{i});
        [~,max_ind] = max(stim_amps{i});
        check_amp_inds = [min_ind,max_ind];
        fprintf('Dish %g: Using %g and %g mA for SNR check\n',...
                i,stim_amps{i}(min_ind),stim_amps{i}(max_ind));
    end
    exclude_rois_pol{i} = all(snri(check_amp_inds,:) < in.min_snr,1);     
    if any(exclude_rois_pol{i})
        fprintf('dish %g: excluding %g of %g polarization ROIs with all SNR < %g\n',...
                i,sum(exclude_rois_pol{i}),length(exclude_rois_pol{i}),in.min_snr);
    end
    
end
out = struct(); 
out.pol_dF_all = pol_dF_all;
out.pol_dF_ss_all = pol_dF_ss_all; 
out.pol_snr_all = pol_snr_all; 
