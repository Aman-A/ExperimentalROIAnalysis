function [out,data_out] = extractSubthreshPolResponses(data,stim_amps,dF_ss_wind,varargin)
%EXTRACTSUBTHRESHMODRESPONSES ... 
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   out : struct
%       processed data output
%   data_out : cell array of structs
%       original experiment data with ROIs failing SNR and R^2 criteria removed

%   Examples 
%   --------------- 
% Note: assumes uniform sampling rate across experiments
% AUTHOR    : Aman Aberra 
in.min_snr = 2; % minimum SNR : peak/std(baseline)
in.check_snr_amps = [-1 1]; % mA
in.pol_Rsq_cutoff = 0; % cutoff for regression R^2 (default don't exclude)
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
    dFi = indicator_dir*cell2mat(reshape(mean_deltaF_F0_aligned_all{i},1,1,[]));     
    dF_ss = squeeze(mean(dFi(dF_ss_wind_inds(1):dF_ss_wind_inds(2),:,:),1))';    
    std_bsline = squeeze(std(dFi(1:data{i}.exp_settings(1).baseline_wind,:,:),0,1))';
    snri = abs(dF_ss)./std_bsline;
    if data{i}.rois_all{1}{1}.num_rois == 1 || strcmp(data{i}.plot_settings.roi_func_mode,'combine')
        dF_ss = dF_ss'; % transpose to [num_amps x num_rois]
        snri = snri'; 
    end  
    pol_dF_all{i} = dFi;
    pol_dF_ss_all{i} = dF_ss;
    pol_snr_all{i} = snri; 
    if in.min_snr > 0
        % exclude rois with SNR < min_snr    
        [~,~,check_amp_inds] = intersect(in.check_snr_amps,stim_amps{i});
        if isempty(check_amp_inds) % use highest amplitudes available from this dish
            [~,min_ind] = min(stim_amps{i});
            [~,max_ind] = max(stim_amps{i});
            check_amp_inds = [min_ind,max_ind];
            fprintf('Dish %g: Using %g and %g mA for SNR check\n',...
                    i,stim_amps{i}(min_ind),stim_amps{i}(max_ind));
        end
        exclude_rois_pol{i} = any(snri(check_amp_inds,:) < in.min_snr,1);     
        if any(exclude_rois_pol{i})
            fprintf('dish %g: excluding %g of %g polarization ROIs with any SNR < %g\n',...
                    i,sum(exclude_rois_pol{i}),length(exclude_rois_pol{i}),in.min_snr);
        end
    end
end
%% Get slopes of polarization vs. current in each ROI and determine polarity
pol_slopes = cell(num_dishes,1);
pol_Rsqs = cell(num_dishes,1);
pol_pvals = cell(num_dishes,1);

for i = 1:num_dishes
    xi = stim_amps{i}; 
    pol_slopes{i} = nan(1,size(pol_dF_ss_all{i},2));
    pol_Rsqs{i} = nan(1,size(pol_dF_ss_all{i},2));
    pol_pvals{i} = nan(1,size(pol_dF_ss_all{i},2));
    for j = 1:size(pol_dF_ss_all{i},2)
        yij = pol_dF_ss_all{i}(:,j);
        [b,~,~,~,stats] = regress(yij,[ones(size(yij)),xi']);
        Rsqij = stats(1); pij = stats(3); 
        pol_Rsqs{i}(j) = Rsqij;
        pol_pvals{i}(j) = pij;
        if length(xi) > 2
            if Rsqij > in.pol_Rsq_cutoff 
                pol_slopes{i}(j) = 100*b(2); % percent deltaF/F0 per mA steady state polarization
            else               
                % fprintf('Dish %g, pol ROI %g R^2 = %.3f, p = %.3f\n',...
                %         i,j,Rsqij,pij)
            end
        else % R^2/p value can't be calculated for regression with 2 pts
            pol_slopes{i}(j) = 100*b(2); % percent deltaF/F0 per mA steady state polarization
        end
    end
    new_excluded_roisi = setdiff(find(isnan(pol_slopes{i})),find(exclude_rois_pol{i}));
    if ~isempty(new_excluded_roisi)
        fprintf('Dish %g, excluding %g additional ROIs with R^2 < %.2f\n',...
                i,length(new_excluded_roisi),in.pol_Rsq_cutoff)
    end
    exclude_rois_pol{i} = exclude_rois_pol{i} | isnan(pol_slopes{i}); % exclude due to snr or weak correlation 
    pol_dF_all{i} = pol_dF_all{i}(:,~exclude_rois_pol{i},:);
    pol_dF_ss_all{i} = pol_dF_ss_all{i}(:,~exclude_rois_pol{i}); 
    pol_snr_all{i} = pol_snr_all{i}(:,~exclude_rois_pol{i});   
    pol_slopes{i} = pol_slopes{i}(~exclude_rois_pol{i});   
    pol_Rsqs{i} = pol_Rsqs{i}(~exclude_rois_pol{i});
    pol_pvals{i} = pol_pvals{i}(~exclude_rois_pol{i});   
end
% Remove ROIs from experiment data structures (based on SNR and R^2 of
% regression)
data_out = cellfun(@(x,y) removeROIsExpData(x,y,'print_level',0),...
                            data,exclude_rois_pol,'UniformOutput',0); 

out = struct(); 
out.pol_dF_all = pol_dF_all;
out.pol_dF_ss_all = pol_dF_ss_all; 
out.pol_snr_all = pol_snr_all; 
out.exclude_rois_pol = exclude_rois_pol; 
out.pol_slopes = pol_slopes; 
out.pol_Rsqs = pol_Rsqs;
out.pol_p_vals = pol_pvals;
