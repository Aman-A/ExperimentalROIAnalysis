function [p_during,p_after,peak_ci,diff_ci_diff_during,diff_ci_diff_after,...
            diff_ci_during,diff_ci_after] = testPeakModBootstrap(peaks_before,...
                                                    peaks_during,peaks_after,...
                                                    varargin)
in.alpha = 0.05;
in.M = 1e3;
in.nbins = 20; % histogram bins

in = sl.in.processVarargin(in,varargin);
if isempty(peaks_after)
    include_after = 0;
    p_after = []; 
    diff_ci_diff_after = []; 
     diff_ci_after = []; 
else
   include_after = 1; 
end
num_amps = length(peaks_before);
num_rois = size(peaks_before{1},1);
p_during = nan(num_rois,num_amps);

% 95% conf intervals
% bootstrapped peaks
if include_after
    peak_ci = nan(num_rois,num_amps,2,3); % peaks - num_rois x num_amps x lower, upper conf interval x before, during, after
else
    peak_ci = nan(num_rois,num_amps,2,2); % peaks - num_rois x num_amps x lower, upper conf interval x before, during
end
peak_ci_diff_during = nan(num_rois,num_amps); % 1 if CIs of means dont overlap
% bootstrapped difference of means
diff_ci_during = nan(num_rois,num_amps,2); % differences of mean - num_rois x num_amps x lower, upper conf interval
diff_ci_diff_during = nan(num_rois,num_amps);
if include_after
    p_after = nan(num_rois,num_amps);
    peak_ci_diff_after = nan(num_rois,num_amps);
    diff_ci_after = nan(num_rois,num_amps,2); % differences of mean - num_rois x num_amps x lower, upper conf interval
    diff_ci_diff_after = nan(num_rois,num_amps);
end
for i = 1:num_amps % loop over intensity
    peaks_beforei = peaks_before{i};
    peaks_duringi = peaks_during{i};
    if include_after
        peaks_afteri = peaks_after{i};
    end
    for j = 1:num_rois % loop over boutons
        if ~all(isnan(peaks_beforei(j,:)))
            peaks_beforeij = peaks_beforei(j,~isnan(peaks_beforei(j,:)));
            peaks_duringij = peaks_duringi(j,~isnan(peaks_duringi(j,:)));            
            % Empirical peak distributions
            % max_pkij = max([peaks_beforeij,peaks_duringij,peaks_afterij],[],'omitnan');
            % edgesij = linspace(0,max_pkij,in.nbins);
            % Nb_ij = histcounts(peaks_beforeij,edgesij,'Normalization','probability');
            % Nd_ij = histcounts(peaks_afterij,edgesij,'Normalization','probability');
            % Na_ij = histcounts(peaks_duringij,edgesij,'Normalization','probability');
            % Test statistic on actual data
            % distribution test
            % D0_ij = Nd_ij-Nb_ij; % during - before
            % D0a_ij = Na_ij-Nb_ij; % after - before
            % difference of means
            M0_ij = mean(peaks_duringij) - mean(peaks_beforeij);            
            npks = length(peaks_beforeij); % number of peaks in each epoch
            % resample peaks and recalculate test statistic
            M0_ij_bs = zeros(in.M,1); % mean peak during - before (bootstrapped)            
            % Nb_ij_bs = zeros(in.M,length(edgesij)-1);
            % Nd_ij_bs = zeros(in.M,length(edgesij)-1);
            % Na_ij_bs = zeros(in.M,length(edgesij)-1);
            if include_after
                peaks_afterij = peaks_afteri(j,~isnan(peaks_afteri(j,:)));            
                M0a_ij = mean(peaks_afterij) - mean(peaks_beforeij);
                M0a_ij_bs = zeros(in.M,1); % mean peak after - before (bootstrapped)
            end
            for m = 1:in.M
                % randomly draw npks peaks from all peaks measured for this ROI at
                % this DC intensity and assign to before, during, and after
                if include_after
                    pm = datasample([peaks_beforeij,peaks_duringij,peaks_afterij],npks*3);
                else
                    pm = datasample([peaks_beforeij,peaks_duringij],npks*2);
                end
                % assign to before, during, and after
                pmb = pm(1:npks); pmd = pm(npks+1:npks*2); 
                
                % get peak distributions
                % Nb_ij_bs(m,:) = histcounts(pmb,edgesij,'Normalization','probability');
                % Nd_ij_bs(m,:) = histcounts(pmd,edgesij,'Normalization','probability');
                % Na_ij_bs(m,:) = histcounts(pma,edgesij,'Normalization','probability');
                % recalculate test statistics on random sample of data m
                % D0m = Ndm - Nbm;
                % D0am = Nam - Nbm;
                M0_ij_bs(m) = mean(pmd) - mean(pmb); % during - before
                if include_after
                    pma = pm(2*npks+1:npks*3);
                    M0a_ij_bs(m) = mean(pma) - mean(pmb); % after - before
                end
            end
            % during - before
            p_ijp = mean(M0_ij_bs >= M0_ij); % upper 1 sided p value
            p_ijn = mean(M0_ij_bs <= M0_ij); % lower 1 sided p value
            p_during(j,i) = min([1,2*p_ijp,2*p_ijn]);
            % p_during(j,i) = 2*mean(abs(M0_ij_bs) >= abs(M0_ij));
            
            % p_after(j,i) = 2*mean(abs(M0a_ij_bs) >= abs(M0a_ij));
            % 95% Confidence intervals of peaks
            if include_after
                peak_ci(j,i,:,:) = bootci(in.M,@mean,[peaks_beforeij',peaks_duringij',peaks_afterij']);                        
            else
                peak_ci(j,i,:,:) = bootci(in.M,@mean,[peaks_beforeij',peaks_duringij']);                        
            end
            % test if conf intervals of peaks don't overlap (sig different)
            peak_ci_diff_during(j,i) = peak_ci(j,i,1,2) > peak_ci(j,i,2,1) || peak_ci(j,i,2,2) < peak_ci(j,i,1,1);            
            % 95% Conf intervals of differences of mean
            diff_ci_during(j,i,:) = bootci(in.M,@(x,y) mean(x)-mean(y),peaks_duringij',peaks_beforeij');            
            diff_ci_diff_during(j,i) = sign(diff_ci_during(j,i,1)) == sign(diff_ci_during(j,i,2));            
            if include_after
                % after - before
                p_ijp = mean(M0a_ij_bs >= M0a_ij); % upper 1 sided p value
                p_ijn = mean(M0a_ij_bs <= M0a_ij); % lower 1 sided p value
                p_after(j,i) = min([1,2*p_ijp,2*p_ijn]);
                peak_ci_diff_after(j,i) = peak_ci(j,i,1,3) > peak_ci(j,i,2,1) || peak_ci(j,i,2,3) < peak_ci(j,i,1,1);
                diff_ci_after(j,i,:) = bootci(in.M,@(x,y) mean(x)-mean(y),peaks_afterij',peaks_beforeij');
                diff_ci_diff_after(j,i) = sign(diff_ci_after(j,i,1)) == sign(diff_ci_after(j,i,2));
            end
        end
    end
    fprintf('%g: %g/%g (%.1f %%) ROIs modulated during DC\n',i,...
        sum(p_during(:,i)<in.alpha,'omitnan'),sum(~all(isnan(peaks_duringi),2),1),...
        100*mean(p_during(:,i)<in.alpha,'omitnan'));
    if include_after
        fprintf('%g: %g/%g (%.1f %%) ROIs modulated after DC\n',i,...
            sum(p_after(:,i)<in.alpha,'omitnan'),num_rois,...
            100*mean(p_after(:,i)<in.alpha,'omitnan'));
    end
end

end