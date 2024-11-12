function [params_gaussian_all,rsq_adj_all,varargout] = estimateQuantalContent(peaks_rois,...
                                                                deltaF_F0,varargin)
%ESTIMATEQUANTALCONTENT Fit peak histogram of single boutons to multiguassian 
% function to estimate amplitude of single vesicle release events
%  
%   Inputs 
%   ------ 
%   peaks_rois : 1 x num_rois cell array
%                cell array of event (mini/evoked release) amplitudes where
%                each element is a Nevent x 1 vector of amplitudes from a
%                single bouton (ROI)
%   deltaF_F0 : Nt x num_rois matrix 
%               Columns are deltaF/F0 traces from each ROI (bouton), e.g.
%               full recording from single trial within each ROI. Used to
%               extract signal variability
%               
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.plot_fits = 1; % Plot histograms for all ROIs
in.lw = 2;      % line width of the fit in plots
% histogram fitting parameters, adapted from Mendonca 2022 Quantal_Analysis.m
in.N_bootstrap = 1e5; % number of bootstrap events
in.alpha = 2; % scaling factor for STD of fluorescence signals to generate bootstrapped events
              % Higher alpha gives larger spread for a given signal
              % variance
in.num_bins_per_std_B = 4.5; % Number of histogram bins scaled by STD of fluorescence signals
in.Multi_Gauss_threshold = 6; % minimum number of events to try multi gaussian fitting
in.alpha_fit_dx = 0.01; % step size for test normalization values
in.dx = 0.001; % fit function x step
in.smooth_bs_dist = 0; % smooth bootstrapped peak distributions with 5 point moving average
in.include_sat_param = 1; % include parameter for saturation of indicator at higher quanta
in.n_G = 3; % # of Gaussians to fit
in.bsline_std_rois = []; % precalculated STD of baseline signal in each ROI
in = sl.in.processVarargin(in,varargin);
%% Get baseline variability
if isempty(in.bsline_std_rois)
    std_all = std(deltaF_F0,0,1,'omitnan');
else
    std_all = in.bsline_std_rois;
end
num_rois = length(peaks_rois);
gauss_fit_params = zeros(3,num_rois); % 3 parameters
% [amplitude; mean; st dev] 
for i = 1:num_rois
    [gauss_fit_params(:,i)] = fitHistSingleGaussian(deltaF_F0(:,i),in.num_bins_per_std_B); % 10 bins per std    
end
%%
fprintf('Fitting multigaussian to ROI peaks...\n')
if in.plot_fits
    [Nrows,Ncols] = getSubplotDimensions(num_rois);
    fig = figure('Units','normalized','Position',[0.1 0.2 0.8 0.6]);
end
rng(100) % set random number generator seed
if in.include_sat_param
    num_params = 6; 
else
    num_params = 5; 
end
params_gaussian_all = zeros(num_rois,num_params);
rsq_adj_all = zeros(num_rois,1);
for i = 1:num_rois    
    roi_tracei = deltaF_F0(:,i); % use last recording (temporary)
    peaks_roi = peaks_rois{i};
%     peaks_roi = mini_out.mini_peaks_deltaF_F{i}; 
    std_tracei = std_all(i);
    sigmai_sig = std_all(i);
%     sigmai_sig = gauss_fit_params(3,i);
%     noisei = in.alpha*sigmai_sig;          
    noisei = in.alpha*std_tracei; 
    if length(peaks_roi) <= 2
        fprintf('Only %g events in ROI %g, skipping...\n',length(peaks_roi),i)
        continue;
    elseif length(peaks_roi) < in.Multi_Gauss_threshold
        n_G=1;
    else
        n_G=in.n_G;
    end
    fprintf('Fitting ROI %g\n',i);
    % Bootstrap peaks
    peaks_roi_bs = bootstrapEvents(peaks_roi,in.N_bootstrap,noisei);
    % Find peaks of bootstrapped distribution
    binsize = std_tracei/in.num_bins_per_std_B;
    nbin_bs = round((max(roi_tracei,[],'omitnan')-min(roi_tracei,[],'omitnan'))/binsize);
    [ycount_bs,bins_bs] = histcounts(peaks_roi_bs,nbin_bs);
    if in.smooth_bs_dist
        ycount_bs = smooth(ycount_bs); % smooth with 5 pt moving average
    end
    bins_bs = [bins_bs(1),bins_bs(end)]; 
    bins_bs = linspace(bins_bs(1),bins_bs(2),length(ycount_bs))'; 
    [pk_y,pk_x] = findpeaks(ycount_bs,bins_bs,'MinPeakProminence',n_G,'NPeaks',n_G); % peaks
    % Fit to multigaussian distribution
    max_ycount_bs = pk_y(1); 
    loc_max_ycount_bs = pk_x(1);     
    estim_noise = sigmai_sig;
    if n_G == 1
        param0 = [max_ycount_bs(1);                
                loc_max_ycount_bs;
                sigmai_sig];
        fit_func = @SingleGaussian;
    else
        param0 = [max_ycount_bs(1);
                max_ycount_bs(1)/2;
                max_ycount_bs(1)/4;
                loc_max_ycount_bs;
                0.1];
        if in.include_sat_param
            param0 = [param0; 1];
            fit_func = @Multimodal_GaussianSat;        
        else
            fit_func = @Multimodal_Gaussian;        
        end
    end
    opts = struct(); 
    opts.MaxIter = 200;  
    try
        if isrow(ycount_bs); ycount_bs = ycount_bs'; end; 
        [param_multimodal_bs ,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(bins_bs,...
                                                ycount_bs,fit_func,param0,opts);
    catch ME
        fprintf('Fitting for ROI %g produced error: %s, skipping\n',i,ME.identifier)
        continue; 
    end
    rsq_adj_all(i) = calcAdjustedRsq(ycount_bs,...
                                    fit_func(param_multimodal_bs,bins_bs),...
                                    param_multimodal_bs);

%     xbin_new = linspace(0,1.5*max(bins_bs),200);   
%     distrib_fit = Multimodal_Gaussian(param_multimodal_bs,xbin_new);
%     pd = fitdist(peaks_roi_bs,'Normal');
%     param_multimodal_bs = [1, pd.mu,pd.sigma];

    params_gaussian_all(i,1:length(param_multimodal_bs)) = param_multimodal_bs;    
    if in.plot_fits
        % Plot
        max_x = max(max(peaks_roi),quantile(peaks_roi_bs,0.98));
        edges = 0:binsize:(max_x+binsize);        
        ax = subplot_tight(Nrows,Ncols,i,[0.06, 0.04]);
%         ax = subplot(Nrows,Ncols,i);
        h = histogram(ax,peaks_roi,edges,'FaceColor',0.6*[1 1 1],'LineStyle','none');
        hold(ax,'on');        
        ycount_data=h.Values;        

        % Find normalization factor
%         bins_limits=h.BinLimits;
%         x_bins = linspace(bins_limits(1),bins_limits(2),length(ycount_data)); % on average in the middle of the bin but not exactly
%         ycount_GP = fit_func(param_multimodal_bs,x_bins);
%         alpha_fit=1:in.alpha_fit_dx:10000;                
%         % Perform numerical fitting - best match for non-zero elements of the real histogram
%         Fit_error=zeros(size(alpha_fit));
%         Idx_non_zero=find(ycount_data>0);
%         % normalize using point with minimum error between fit and bootstrapped data
%         for k=1:length(alpha_fit) 
%             Fit_error(k)=sum((ycount_GP(Idx_non_zero)/alpha_fit(k)-ycount_data(Idx_non_zero)).^2);
%         end
%         [~,index_alpha]=min(Fit_error);
%         norm1=alpha_fit(index_alpha);

        x=0:in.dx:max_x; 
%         x=0:in.dx:0.5; 
        A1i = param_multimodal_bs(1); 
        % [amplitude; mean; st dev]         
        if n_G > 1
            mui = param_multimodal_bs(4); 
            sigmai = param_multimodal_bs(5);
            y0 = fit_func(param_multimodal_bs,x);            
            norm1 = max(y0)/max(ycount_data);
            y0 = y0/norm1; 
        else
            mui = param_multimodal_bs(2); 
            sigmai = param_multimodal_bs(3);  
            % Plot first gaussian
            y0 = SingleGaussian([abs(A1i),abs(mui),sigmai],x);
            norm1 = max(y0)/max(ycount_data);
            y0 = y0/norm1; 
        end               
        plot(ax,x,y0,'k','LineWidth',in.lw);                
        % higher modes
        if in.include_sat_param
            sati = param_multimodal_bs(6);
        else
            sati = 1; 
        end
                
        if n_G >= 2
            % Plot 1st including noise component
            y1 = SingleGaussianNoSquare([abs(A1i),abs(mui),estim_noise^2+sigmai^2],x)/norm1; 
            plot(x,y1,'k--','LineWidth',in.lw/1.5);
            % Plot 2nd
            A2i = param_multimodal_bs(2);
            mui = param_multimodal_bs(4); 
            sigmai = param_multimodal_bs(5);
            y2 = SingleGaussianNoSquare([abs(A2i),abs(mui)+sati*abs(mui),estim_noise^2+sigmai^2],x)/norm1; 
            plot(x,y2,'k--','LineWidth',in.lw/1.5);
        end
        if n_G >= 3
            % Plot 3rd
            A3i = param_multimodal_bs(3);                   
            y3 = SingleGaussianNoSquare([abs(A3i),abs(mui)+sati*abs(mui)+sati^2*abs(mui),...
                                estim_noise^2+sigmai^2],x)/norm1; 
            plot(x,y3,'k--','LineWidth',in.lw/1.5);
        end        
%         max_y = max(ycount_data);
%         xlim(ax,[0 max(max_x,max(x))]);
%         xlim(ax,[0 max_x]);        
%         ylim(ax,[0 max_y]*1.1); 
        title(sprintf('%g: \\mu = %.2f, \\sigma = %.2f, CV = %.1f %%',...
                i,mui,sigmai,100*sigmai/mui),'FontSize',10);
        if i > (Nrows-1)*Ncols
        xlabel(ax,'Amplitude')
        end
        box(ax,'off');
        drawnow; 
    end
end
fprintf('Done\n')
if in.plot_fits
    varargout = {fig};
end
%% Single Gaussian function
    function y = SingleGaussian(params,x) % [amplitude; mean; st dev]
        y=params(1).*exp(-(x-params(2)).^2/(2*params(3)^2));
    end
    function y = SingleGaussianNoSquare(params,x) % [amplitude; mean; st dev]
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
                    adj_factor = 1; 
%                     adj_factor = (A1>=0)*(A2>=0)*(A3>=0)*(A1>A3); % adjustment factor to help fit
            end
%             y = (A1.*exp(-(x - abs(mu)).^2/(2*(estim_noise^2 + sigma.^2)))+...
%                 A2.*exp(-(x - 2*abs(mu)).^2/(2*(estim_noise^2 + sigma.^2)))+...
%                 A3.*exp(-(x - 3*abs(mu)).^2/(2*(estim_noise^2 + sigma.^2))))...
%                 *adj_factor;    
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
%          y = (A1.*exp(-(x - abs(mu)).^2/(2*(estim_noise^2+1*sigma.^2)))+...
%             A2.*exp(-(x - abs(mu) - sat*abs(mu)).^2/(2*(estim_noise^2 + 1*sigma.^2)))+...
%             A3.*exp(-(x - abs(mu) - sat*abs(mu) - sat^2*abs(mu)).^2/(2*(estim_noise^2+1*sigma.^2))))...
%             *adj_factor;  
        y = (abs(A1).*exp(-(x - abs(mu)).^2/(2*(estim_noise^2+1*sigma.^2)))+...
            abs(A2).*exp(-(x - abs(mu) - sat*abs(mu)).^2/(2*(estim_noise^2 + 1*sigma.^2)))+...
            abs(A3).*exp(-(x - abs(mu) - sat*abs(mu) - sat^2*abs(mu)).^2/(2*(estim_noise^2+1*sigma.^2))))...
            *adj_factor;        
    end 
end