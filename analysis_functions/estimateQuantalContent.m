function estimateQuantalContent(rec_names,roiset_files,exp_settings,varargin)
%ESTIMATEQUANTALCONTENT(rec_names,roiset_files,exp_settings,varargin) 
% Fit peak histogram of single boutons to multiguassian 
% to estimate amplitude of single vesicle release events
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
if nargin == 0
    rec_names = {'3mABi_0mAG/3mABi_0mAG.fits'};    
    roiset_files = {'RoiSet_auto_pos5_2.mat'};    
%     rec_names = {'3mABi_0mAG/3mABi_0mAG.fits','3mABi_0mAG/3mABi_0mAG.fits'};    
%     roiset_files = {'RoiSet_auto_pos5_2.mat','RoiSet_auto_pos5_2.mat'};    
    exp_settings = ExperimentSettings(0.5:0.5:30,0.4,0.15,...
                                      'sec',100); % automatically converts to frames
end
in.data_dir = '/Volumes/MyPassport/Dartmouth_data/Aman_Olympus/DC_mod_experiments/230117/GluSnFR3_SynmRuby/dish1/'; 
in.show_diff_image = []; 
in.load_processed_data = 1; 
in.save_processed_data = 0; 
in.save_figs = 0; 
in.std_threshold = 3.5; % threshold to consider peak success vs. failure, 
                      % defined as multiple of std of local baseline for
                      % each stimulus, i.e. peak > 4 x std(baseline) is
                      % success for in.std_threshold = 4. 
% in.min_width = [18e-3 60e-3]; % sec - min FWHM of stim evoked response to consider successful response (if >std_threshold)
in.min_width = 0; 
% histogram fitting parameters, adapted from Mendonca 2022 Quantal_Analysis.m
in.N_bootstrap = 1e5; 
in.alpha = 2;
in.num_bins_per_std_B = 4.5; 
in.Multi_Gauss_threshold = 6; 
in.plot_fits = 1;
in.alpha_fit_dx = 0.01; 
in.dx=0.001; % fit function x step
in.lw=2;      % line width of the fit
in.smooth_bs_dist = 0; % smooth bootstrapped peak distributions with 5 point moving average
in.include_sat_param = 0; % include parameter for saturation of indicator at higher quanta
in = sl.in.processVarargin(in,varargin);
%% Load recordings
if isempty(in.data_dir)
    in.data_dir = fileparts(rec_names{1});    
end
ps = plotTrialSettings;
ps.plot_func = '';
ps.roi_func_mode = 'separate';
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.show_diff_image = in.show_diff_image; 
ps.save_fig = in.save_figs; 
ps.show_roi_labels = 1;
ps.load_processed_data = in.load_processed_data;
peaks_all = cell(1,length(rec_names));
peaks_rois_successes = cell(1,length(rec_names));
successes_all = cell(1,length(rec_names));
if length(in.min_width) == 1
    in.min_width = [in.min_width inf]; % if specific min width only, add max width
end
for i = 1:length(rec_names)
    reci = Recording(fullfile(in.data_dir,rec_names{i}));
    roisi = ROIs(fullfile(in.data_dir,roiset_files{i}));
    datai = plotTrial(reci,exp_settings,roisi,[],ps);
    analysis_out = analyzeStimAlignedTraces(datai.func_output.deltaF_F0_aligned,exp_settings,...
                                        'funcs',{'peaks'},...
                                        'save_analysis',0,'load',0);
    peaksi = analysis_out.peaks; 
    std_baselinesi = squeeze(std(datai.func_output.deltaF_F0_aligned(1:exp_settings.baseline_wind,:,:),0,1));
    successesi = peaksi > in.std_threshold.*std_baselinesi; 
    peaks_all{i} = peaksi;
    % Extract successful peaks within each ROI (remove failures)
    peaks_rois_successes{i} = cell(roisi.num_rois,1);
    t = exp_settings.getTimeVector(size(datai.func_output.deltaF_F0_aligned,1));
    t = t - t(exp_settings.baseline_wind + 1);
    for j = 1:roisi.num_rois
        successesij = successesi(j,:);
        widthsij = zeros(1,length(successesij));
        if in.min_width(1) > 0           
            for k = find(successesij) % check width peaks > std threshold
                widthsij(k) = spikeWidth(t,datai.func_output.deltaF_F0_aligned(:,j,k),...
                                         exp_settings.baseline_wind+1,0.5,0);
            end
            successesij = successesij & widthsij > in.min_width(1) & widthsij < in.min_width(2);
        end        
        peaks_rois_successes{i}{j} = peaksi(j,successesij);
    end    
    successes_all{i} = successesi; 
end
num_rois = roisi.num_rois; 
% Convert to [num_rois x num_stim] matrix
% peaks_mat_all = cell2mat(peaks_all); % assumes same number of ROIs in each recording
successes_mat = cell2mat(successes_all);
Pr = mean(successes_mat,2); % [num_rois x 1] vector of release probabilities (>=1 SV)
peaks_rois_successes_all = cell(num_rois,1);
% Combine across recordings within ROI
for i = 1:length(rec_names)
    for j = 1:roisi.num_rois
        peaks_rois_successes_all{j} = [peaks_rois_successes_all{j},peaks_rois_successes{i}{j}];
    end
end
% Use last trial to get std of full trace for setting bin size
deltaF_F0 = datai.func_output.deltaF_F0;
std_all = std(deltaF_F0,0,1);
gauss_fit_params = zeros(3,num_rois); % 3 parameters
% [amplitude; mean; st dev] 
for i = 1:num_rois
    gauss_fit_params(:,i) = fitHistSingleGaussian(datai.func_output.deltaF_F0(:,i),10); % 10 bins per std    
end
%% Detect events with detecMinis function
% presets = detectMinisPresets('thor_100Hz',100);
% presets.num_frames_skip_start_end = 30; 
% presets.plot_filt_output_roi_index = 19; 
% presets.threshold = 6; 
% mini_out = detectMinis(datai.func_output.mean,100,presets);
%%
if in.plot_fits
    [Nrows,Ncols] = getSubplotDimensions(num_rois);
    fig = figure('Units','normalized','Position',[0.1 0.2 0.8 0.6]);
end
rng(100) % set random number generator seed
for i = 1:num_rois
    roi_tracei = datai.func_output.deltaF_F0(:,i); % use last recording (temporary)
    peaks_roi = peaks_rois_successes_all{i};
%     peaks_roi = mini_out.mini_peaks_deltaF_F{i}; 
    std_tracei = std_all(i);
    sigmai = gauss_fit_params(3,i);
    noisei = in.alpha*sigmai;     
    if length(peaks_roi) <= 5
        fprintf('Only %g events in ROI %g, skipping...\n',length(peaks_roi),i)
        continue;
    elseif length(peaks_roi) < in.Multi_Gauss_threshold
        n_G=1;
    else
        n_G=3;
    end
    % Bootstrap peaks
    peaks_roi_bs = bootstrapEvents(peaks_roi,in.N_bootstrap,noisei);
    % Find peaks of bootstrapped distribution
    binsize = std_tracei/in.num_bins_per_std_B;
    nbin_bs = round((max(roi_tracei)-min(roi_tracei))/binsize);
    [ycount_bs,bins_bs] = histcounts(peaks_roi_bs,nbin_bs);
    if in.smooth_bs_dist
        ycount_bs = smooth(ycount_bs); % smooth with 5 pt moving average
    end
    bins_bs = [bins_bs(1),bins_bs(end)]; 
    bins_bs = linspace(bins_bs(1),bins_bs(2),length(ycount_bs)); 
    [pk_y,pk_x] = findpeaks(ycount_bs,bins_bs); % peaks
    % Fit to multigaussian distribution
    max_ycount_bs = pk_y(1); 
    loc_max_ycount_bs = pk_x(1); 
    param0 = [max_ycount_bs(1);
                max_ycount_bs(1)/2;
                max_ycount_bs(1)/4;
                loc_max_ycount_bs;
                0.1];
    estim_noise = sigmai;
    if in.include_sat_param
        param0 = [param0; 1];
        fit_func = @Multimodal_GaussianSat;        
    else
        fit_func = @Multimodal_Gaussian;        
    end
    param_multimodal_bs = nlinfit(bins_bs,ycount_bs,fit_func,param0);
    
%     xbin_new = linspace(0,1.5*max(bins_bs),200);   
%     distrib_fit = Multimodal_Gaussian(param_multimodal_bs,xbin_new);
    if in.plot_fits
        % Plot
        max_x = max(peaks_roi);
        edges = 0:binsize:max_x;        
        ax = subplot_tight(Nrows,Ncols,i);
        h = histogram(peaks_roi,edges,'FaceColor',0.6*[1 1 1],'LineStyle','none');
        hold on;
        bins_limits=h.BinLimits;
        ycount_data=h.Values;
        x_bins = linspace(bins_limits(1),bins_limits(2),length(ycount_data)); % on average in the middle of the bin but not exactly
        ycount_GP = fit_func(param_multimodal_bs,x_bins);
        alpha_fit=1:in.alpha_fit_dx:10000;                
        % Perform numerical fitting - best match for non-zero elements of the real histogram
        Fit_error=zeros(size(alpha_fit));
        Idx_non_zero=find(ycount_data>0);
        % normalize using point with minimum error between fit and bootstrapped data
        for k=1:length(alpha_fit) 
            Fit_error(k)=sum((ycount_GP(Idx_non_zero)/alpha_fit(k)-ycount_data(Idx_non_zero)).^2);
        end
        [~,index_alpha]=min(Fit_error);
        norm1=alpha_fit(index_alpha); 
        x=0:in.dx:max(peaks_roi);
        y0 = fit_func(param_multimodal_bs,x);
        y0 = y0/norm1; 
        plot(ax,x,y0,'k','LineWidth',in.lw);
        hold(ax,'on');
        A1i = param_multimodal_bs(1); 
        A2i = param_multimodal_bs(2);
        A3i = param_multimodal_bs(3);        
        mui = param_multimodal_bs(4); 
        sigmai = param_multimodal_bs(5);
        if in.include_sat_param
            sati = param_multimodal_bs(6);
        else
            sati = 1; 
        end
        % [amplitude; mean; st dev] 
        if n_G >= 1
            y1 = SingleGaussian([abs(A1i),abs(mui),estim_noise^2+sigmai^2],x)/norm1; 
            plot(x,y1,'k--','LineWidth',in.lw/1.5);
        end
        if n_G >= 2
            y2 = SingleGaussian([abs(A2i),abs(mui)+sati*abs(mui),estim_noise^2+sigmai^2],x)/norm1; 
            plot(x,y2,'k--','LineWidth',in.lw/1.5);
        end
        if n_G >= 3
            y3 = SingleGaussian([abs(A3i),abs(mui)+sati*abs(mui)+sati^2*abs(mui),...
                                estim_noise^2+sigmai^2],x)/norm1; 
            plot(x,y3,'k--','LineWidth',in.lw/1.5);
        end        

        xlim(ax,[0 max_x]);
        title(sprintf('ROI %g',i));
        if i > (Nrows-1)*Ncols
        xlabel(ax,'Amplitude')
        end
        box(ax,'off');
    end
end
fprintf('Done\n')
%% Single Gaussian function
    function y = SingleGaussian(params,x) % [amplitude; mean; st dev]
        y=params(1).*exp(-(x-params(2)).^2/(2*params(3)));
    end
%% Multimodal Gaussian function
    function y = Multimodal_Gaussian(param,x) % without saturation factor
            
            switch n_G
                case 1
            
                    A1=param(1); % amplitude of 1st gaussian
                    A2=0; % amplitude of 2nd gaussian
                    A3=0; % amplitude of 3rd gaussian
                    mu=param(4); % quantal size (mean of gaussian)
                    sigma=param(5); % std of gaussian                    
                    adj_factor = A1>=0;
                case 2                                
                    A1=param(1);
                    A2=param(2);
                    A3=0;
                    mu=param(4);
                    sigma=param(5);
                    adj_factor = (A1>=0)*(A2>=0)*(A1>A2); % adjustment factor to help fit
                case 3            
                    A1=param(1);
                    A2=param(2);
                    A3=param(3);
                    mu=param(4);
                    sigma=param(5);                 
                    adj_factor = (A1>=0)*(A2>=0)*(A3>=0)*(A1>A3); % adjustment factor to help fit
            end
            y = (abs(A1).*exp(-(x - abs(mu)).^2/(2*(estim_noise^2 + sigma.^2)))+...
                abs(A2).*exp(-(x - 2*abs(mu)).^2/(2*(estim_noise^2 + sigma.^2)))+...
                abs(A3).*exp(-(x - 3*abs(mu)).^2/(2*(estim_noise^2 + sigma.^2))))...
                *adj_factor;    
    end
% with saturation factor
    function y = Multimodal_GaussianSat(param,x) 
        
        switch n_G
            case 1
        
                A1 = param(1); % amplitude of 1st gaussian
                A2 = 0; % amplitude of 2nd gaussian
                A3 = 0; % amplitude of 3rd gaussian
                mu = param(4); % quantal size (mean of gaussian)
                sigma = param(5); % std of gaussian
                sat = param(6)*0; % adjustment factor for saturation of indicator  
                adj_factor = A1>=0; % adjustment factor to help fit
            case 2
                A1 = param(1); % amplitude of 1st gaussian
                A2 = param(2); % amplitude of 2nd gaussian
                A3 = 0; % amplitude of 3rd gaussian
                mu = param(4); % quantal size (mean of gaussian)
                sigma = param(5); % std of gaussian
                sat = param(6); % adjustment factor for saturation of indicator
                adj_factor = (sat>=0.5)*(sat<=1.1)*(A1>=0)*(A2>=0)*(A1>A2); % adjustment factor to help fit
            case 3
        
                A1 = param(1);
                A2 = param(2);
                A3 = param(3);
                mu = param(4);
                sigma = param(5);
                sat = param(6);        
                adj_factor = (sat>=0.5)*(sat<=1.1)*(A1>=0)*(A2>=0)*(A3>=0)*(A1>A3); % adjustment factor to help fit
        
        end
        y = (abs(A1).*exp(-(x - abs(mu)).^2/(2*(estim_noise^2+1*sigma.^2)))+...
            abs(A2).*exp(-(x - abs(mu) - sat*abs(mu)).^2/(2*(estim_noise^2 + 1*sigma.^2)))+...
            abs(A3).*exp(-(x - abs(mu) - sat*abs(mu) - sat^2*abs(mu)).^2/(2*(estim_noise^2+1*sigma.^2))))...
            *adj_factor;        
    end    
end