function output = detectMinis(F,sampling_rate,varargin)
% DETECTMINIS(F,sampling_rate,varargin)
%  
%   Inputs 
%   ------ 
%    F - num_timepoints x num_rois matrix
%        Mean fluorescence trace within rois at each frame of recording
%        Each column corresponds to individual ROI
%    sampling_rate - scalar
%                    Sampling rate in Hz of signal
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
%
% To do: Add width criteria based on upstroke/downstroke of mini (FWHM?)
% AUTHOR    : Aman Aberra 
% F - matrix
if nargin < 2
    sampling_rate = 25; 
end
in.threshold = 4; % threshold for peak detection on filtered trace. 
                  % Defined as multiple above noise level (std of
                  % baseline fluctations)
in.snr_thresh = []; % throw out minis with mini SNR (peak/std(baseline)) < this number (based on raw F trace)
                    % skips this step if left empty
in.min_mini_width = 0; % sec - minimum peak full width at half max, 
in.min_peak_distance = 3*in.min_mini_width;
in.width_ref = 'halfheight'; % width reference for findpeaks, eithe 'halfprom' or 'halfheight'
in.nframes_back = round(0.4*sampling_rate); % number of frames before each mini peak to extract (default 0.4 sec)
in.nframes_forward = round(0.4*sampling_rate); % number of frames after each mini peak to extract
in.stim_frames = []; % frames at which stimuli were applied (if applicable)
in.blank_around_stim = [round(0.2*sampling_rate),round(0.2*sampling_rate)];  % blank around each stim (default 0.2 sec)
in.apply_filter = 1;
in.filt_type = 'gauss'; % filter type, 'gauss' for gaussian or 'butter' for butterworth
in.filt_order = 3; % order of butterworth filter
in.fc = [0.5 30]; % 0.5 to 30 Hz high pass filter cutoff
in.smooth_filt_type = 'med'; %'med' or 'sgolay'
in.smooth_filt_width = 5; % 5 for med or 15 for sgolay
in.plot_figs = 1; % 1 to plot mini detection figures, 0 to skip
in.save_figs = 0; % 1 to save figures, 0 to skip
in.save_figs_dir = ''; % save figures to this directory (saves to current directory if empty
in.trial_name = ''; % for file saving
in.plot_x_time = 0; % 1 to use time on x-axis, 0 to use frames
in.plot_filt_output_roi_index = 4; % index of ROI to plot filter output of, leave as 0 to skip
in.deconv = 0; 
in.deconv_tau = 35e-3; % sec (~35 ms is mean decay time constant from my 
                       % evoked GluSnFR3 measurements)
in.refilter_deconv = 1;     
in.num_frames_skip_start_end = round(0.1*sampling_rate); % frames to remove from start/end due to filtering artifacts
% in.offset_factor = 1.01; % how much to offset traces in plot
in.offset_factor = []; 
in.use_asls_baseline = 1; % set to 1 to use asymmetric least squares baseline detection
in.asls_smoothness = 5; % smoothness param for asymmetric least squares (see asLS_baseline.m for description)
in.asls_asym = 0.1;  % asymmetry parameter for asymmetric least squares
in.find_pk_frame = 5; % number of frames around original peak to search in unfiltered traces (or 0 to use peak frame from filtered traces)
in.est_rise_time_frames = ceil(20e-3*sampling_rate); % take baseline 20 ms before peak (typical rise time of GluSnFR3 signal)
in.print_level = 0; % print level
in = sl.in.processVarargin(in,varargin);
%% Output default settings struct if called with no inputs
if nargin == 0
    output = in; 
    return; 
end
%% Filter traces
num_rois = size(F,2); 
blank_around_stim = in.blank_around_stim; 
if length(blank_around_stim) == 1
    blank_around_stim = [blank_around_stim,blank_around_stim];
end
if in.apply_filter
    [F_filt2,F_filt1] = filterTracesForEventDetection(F,sampling_rate,in.fc,...
                                                    in.filt_order,in.filt_type,...
                                                    in.smooth_filt_width,...
                                                    in.smooth_filt_type);
else
    F_filt1 = F;
    F_filt2 = F;
    fprintf('Skipped filtering step\n'); 
end
%% Deconvolution
if in.deconv    
    F_deconv = deconvSingleExp(F_filt2,sampling_rate,in.deconv_tau); 
    % normalize to max
    if isempty(in.stim_frames)
        F_deconv = F_deconv ./max(F_deconv(in.num_frames_skip_start_end:end-in.num_frames_skip_start_end,:),[],1,'omitnan');
    else
        F_deconv = F_deconv./max(F_deconv(in.stim_frames(1):in.stim_frames(end),:),[],1,'omitnan'); 
    end
    gauss_fit_params = zeros(3,num_rois); % 3 parameters
    for i = 1:num_rois
        gauss_fit_params(:,i) = fitHistSingleGaussian(F_deconv(:,i),10); % 10 bins per std    
    end
    F_deconv = F_deconv - gauss_fit_params(2,:); % adjusted deconvolved traces (on the value of the peak of gauss)
    % Filter deconvolved trace again
    if in.refilter_deconv
        fprintf('Refiltering deconvolved trace...\n')
        [F_filt,~] = filterTracesForEventDetection(F_deconv,sampling_rate,in.fc,...
                                                    in.filt_order,in.filt_type,...
                                                    0,...
                                                    'none');
        % refit histogram to gaussian
        gauss_fit_params = zeros(3,num_rois); % 3 parameters - amplitude A, mean /mu, std /sigma
        for i = 1:num_rois
            gauss_fit_params(:,i) = fitHistSingleGaussian(F_filt(:,i),10); % 10 bins per std    
        end
    else
        F_filt = F_deconv; 
    end   
    sigmas = gauss_fit_params(3,:);  % noise level in deconvolved trace    
    [F_blanked,F_blanked_filt,evoked_peaks,evoked_peaks_filt] = ...
        blankStimAndExtractPeaks(F,F_filt,in.stim_frames,blank_around_stim);
else
    F_filt = F_filt2; 
    F_deconv = F_filt2;   
    gauss_fit_params = []; 
    % get sigmas below
    [F_blanked,F_blanked_filt,evoked_peaks,evoked_peaks_filt] = ...
        blankStimAndExtractPeaks(F,F_filt,in.stim_frames,blank_around_stim);
    sigmas = std(F_blanked_filt,0,1,'omitnan');  % noise level in deconvolved trace (omit evoked responses)
end
%% Plot output of filtering and deconvolution
if in.plot_x_time % x axis is time (sec)
    x_full = (0:(size(F,1)-1))/sampling_rate; % time in sec
    x_mini = 1e3*(0:(in.nframes_back + in.nframes_forward))/sampling_rate; % time in ms
    x_mini = x_mini - x_mini(in.nframes_back + 1);
    stim_frames_plot = x_frames/sampling_rate;
    xaxis_label = 'time (ms)';
else % x axis is frame
    x_full = 1:size(F,1);
    x_mini = 1:(in.nframes_back + in.nframes_forward + 1);
    x_mini = x_mini - x_mini(in.nframes_back + 1);
    stim_frames_plot = in.stim_frames; 
    xaxis_label = 'frame';
end
% get file names for saving
if in.save_figs
    save_figs = 1;
    if isempty(in.save_figs_dir)
        fig_dir = './mini_analysis';
    else
        fig_dir = in.save_figs_dir;
    end
    if isempty(in.trial_name)
        fig_basename = 'trial';
    else
        fig_basename = in.trial_name;
    end
else
    save_figs = 0;
end
% set figure size
fig_units = 'inches';
fig_pos = [4.8 4.2 18.5 9];
if in.plot_filt_output_roi_index > 0 && in.plot_figs
    ii = in.plot_filt_output_roi_index; 
%     x_lim = [490 530]; % roi 4
    x_lim = [1 x_full(end)];
    fig = figure('Units',fig_units,'Position',fig_pos); 
    ax = subplot(4,1,1); 
    if isempty(in.stim_frames)
       plot(x_full,F(:,ii)-mean(F(1:10,ii))); 
       title('Mean'); 
    else
        plot(x_full,(F(:,ii)-mean(F(1:in.stim_frames(1)-1,ii)))/mean(F(:,ii))); 
        hold on; plot(stim_frames_plot,ax.YLim(2)*0.8,'ro');
        title('deltaF/F'); 
    end      
    xlim(x_lim); 
    box off; 
    subplot(4,1,2); % 1st filter
    plot(x_full,(F_filt1(:,ii)-mean(F_filt1(:,ii))/mean(F_filt1(:,ii)))); xlim(x_lim);
    title(sprintf('%s filter',in.filt_type)); box off; 
    subplot(4,1,3); % 1st filter + smoothing filter
    plot(x_full,(F_filt2(:,ii)-mean(F_filt2(:,ii))/mean(F_filt2(:,ii)))); xlim(x_lim);
    title(sprintf('%s + %s',in.filt_type,in.smooth_filt_type)); box off; 
    subplot(4,1,4); % filters + deconv
    if in.refilter_deconv
        plot(x_full,F_deconv(:,ii)); hold on; plot(F_blanked_filt(:,ii)); xlim(x_lim);
        plot([x_full(1) x_full(end)],sigmas(ii)*[1 1])
        plot([x_full(1) x_full(end)],in.threshold*sigmas(ii)*[1 1],'--')
        legend('Deconvolved','Deconvolved + refiltered',...
                'STD',sprintf('Threshold (%.1f x STD)',in.threshold),...
                'Box','off','Location','northeast','Orientation','horizontal')
    else
        plot(x_full,F_deconv(:,ii)); xlim(x_lim); hold on;
        plot([x_full(1) x_full(end)],in.threshold*sigmas(ii)*[1 1])
    end    
    title(sprintf('Deconv with tau_{d} = %g ms',in.deconv_tau*1e3)); box off;     
    sgtitle(sprintf('%s: ROI %g',in.trial_name,ii),'Interpreter','none');
    if save_figs
        printFig(fig,fig_dir,[fig_basename '_filt_output_roi' num2str(ii)],...
            'formats','png','resolutions','-r300');        
    end
end
%% Peak detection

nframes_back = in.nframes_back;
nframes_forward = in.nframes_forward;         
thresholds = in.threshold*sigmas; 
min_mini_width = in.min_mini_width;     
min_peak_distance = in.min_peak_distance;
width_ref = in.width_ref;
est_rise_time_frames = in.est_rise_time_frames;
F_findpks = F_blanked_filt;
if in.num_frames_skip_start_end > 0
    F_findpks(1:in.num_frames_skip_start_end,:) = nan;
    F_findpks(end-in.num_frames_skip_start_end:end,:) = nan;
end
t_mini = (0:(nframes_back+nframes_forward))'/sampling_rate;
t_mini = t_mini - t_mini(nframes_back+1);
% Exclusion criteria
% Exclude ROIs with evoked SNR < threshold
snr_thresh = in.snr_thresh; 

% Find ROIs        
mini_frames = cell(1,num_rois); 
mini_frames_filt = cell(1,num_rois); % frames based on filtered trace
mini_traces = cell(1,num_rois); 
mini_baselines = cell(1,num_rois);
mini_snr = cell(1,num_rois);
mini_widths = cell(1,num_rois);
roi_inds = []; % ROI index for each mini
for i = 1:num_rois
    if any(F_findpks(:,i) >= thresholds(i))
        [~,mini_framesi,peak_widthsi] = findpeaks(F_findpks(:,i),...
                                  'MinPeakHeight',thresholds(i),...
                                  'MinPeakDistance',min_peak_distance*sampling_rate,... %'MinPeakWidth',1,... % 1 frame 'MinPeakWidth',min_mini_width*sampling_rate,                                  
                                  'WidthReference',width_ref,... % halfheight or halfprom
                                  'Annotate','extents');                                                 
        mini_framesi_filt = mini_framesi; 
        mini_tracesi = nan(nframes_back+nframes_forward+1,length(mini_framesi));
        baselinesi = nan(nframes_back+nframes_forward+1,length(mini_framesi));
        peaksi = zeros(1,length(mini_framesi));
        widthsi = zeros(1,length(mini_framesi));        
        for j = 1:length(mini_framesi) % loop through minis in this ROI
            mini_frame0ij = mini_framesi(j);
            if in.find_pk_frame > 0
                % find actual peak frame using unfiltered trace
                % within find_pk_frame frames of peak detected in
                % filtered trace above
                % start at find_pk_frame before or beginning of recording if precedes start               
                start_wind = max([1,mini_frame0ij-in.find_pk_frame]);
                % end at find_pk_frame after or next peak/end of recording
                % if occurs earlier
                end_wind = min([size(F_blanked,1),mini_frame0ij+in.find_pk_frame]); 
                if j < length(mini_framesi)
                    end_wind = min(end_wind,mini_framesi(j+1)-1);
                end
                [peaksi(j),loc] = max(F_blanked(start_wind:end_wind,i),[],'omitnan');
                mini_frame0ij = start_wind + loc - 1; 
                % check if new frame is too close to other minis (most
                % common if local maximum during long decay is above
                % threshold)                
                mini_framesi(j) = mini_frame0ij; % update to new frame           
            end
            mini_framesij = (mini_frame0ij-nframes_back):(mini_frame0ij+nframes_forward);
            mini_framesij(mini_framesij<=0) = nan; % exclude frames outside of recording window
            mini_framesij(mini_framesij>size(F_findpks,1)) = nan;
            include_inds = ~isnan(mini_framesij); % frames to include for this mini
            % Get mini trace from unfiltered recording
            mini_tracesi(include_inds,j) = F(mini_framesij(include_inds),i);            
            if in.use_asls_baseline
                baselinesi(include_inds,j) = asLS_baseline(mini_tracesi(include_inds,j),...
                            in.asls_smoothness,in.asls_asym);
            end            
        end 
        keep_minis = true(1,length(mini_framesi));
        % Remove events too close to eachother after adjusting to peak in
        % raw trace 
        for j = 1:length(mini_framesi)-1            
            if (mini_framesi(j+1) - mini_framesi(j) < min_peak_distance*sampling_rate)
                keep_minis(j+1) = false;
                if in.print_level > 0
                    fprintf('ROI %g: mini at %g and %g too close, removing 2nd\n',...
                        i,mini_framesi(j),mini_framesi(j+1))
                end
            end            
        end
        % Filter out spurious events by SNR
        if in.use_asls_baseline
            std_baselinesi = std(mini_tracesi(1:nframes_back-est_rise_time_frames,:),0,1,'omitnan'); % use raw trace to determine baseline variability 
%             std_baselinesi = std(baselinesi(1:nframes_back,:),0,1,'omitnan');  % use smoothed baseline trace
            mean_baselinesi = mean(baselinesi(1:nframes_back-est_rise_time_frames,:),1,'omitnan');                    
        else
            std_baselinesi = std(mini_tracesi(1:nframes_back-est_rise_time_frames,:),0,1,'omitnan'); 
            mean_baselinesi = mean(mini_tracesi(1:nframes_back-est_rise_time_frames,:),1,'omitnan');
        end                                                 
        if in.find_pk_frame == 0
            [peaksi] = max(mini_tracesi(nframes_back-3:nframes_back+3,:),[],1,'omitnan');  % check a few frames before after expected peak (differs from filtered trace)
        end
        snri = (peaksi-mean_baselinesi)./std_baselinesi;
        if snr_thresh > 0
            keep_minis1 = snri > snr_thresh; 
            if in.print_level > 0 && any(~keep_minis1)
                fprintf('Excluded %g minis in ROI %g with SNR < %.1f\n',...
                        sum(~keep_minis1),i,snr_thresh)
            end
            keep_minis = keep_minis & keep_minis1; 
        end
        % Filter out spurious events by width
        for j = find(keep_minis) % only check minis that pass SNR criterion
            widthsi(j) = spikeWidth(t_mini,mini_tracesi(:,j),... % set stim_index to peak frame - in.find_pk_frame
                        nframes_back+1 - in.find_pk_frame,0.5,0,...
                        nframes_back+1);%  Get FWHM
        end
        if min_mini_width > 0                  
            keep_minis2 = widthsi > min_mini_width; 
            if in.print_level > 0 && any(~keep_minis2(keep_minis))
                % Print number of minis excluded due to FWHM criteria that
                % passed SNR criterion and total excluded
                fprintf('Excluded %g minis in ROI %g with FWHM < %.1f ms (%g total)\n',...
                        sum(~keep_minis2(keep_minis)),i,min_mini_width*1e3,...
                        sum(~keep_minis2 | ~keep_minis))
            end
            keep_minis = keep_minis & keep_minis2; % undefined width (nan) will also fail to pass
        end

        mini_framesi_filt = mini_framesi_filt(keep_minis);
        mini_framesi = mini_framesi(keep_minis);
        mini_traces{i} = mini_tracesi(:,keep_minis);
        mini_frames{i} = mini_framesi; % column vector
        mini_frames_filt{i} = mini_framesi_filt; 
        mini_baselines{i} = mean_baselinesi(keep_minis)'; % column vector 
        mini_snr{i} = snri(keep_minis);
        mini_widths{i} = widthsi(keep_minis); 
        roi_inds = [roi_inds;i*ones(length(mini_framesi),1)];
    else
       mini_frames{i} = [];  
    end
end
num_rois_w_mini = sum(~cellfun(@isempty,mini_frames,'UniformOutput',1)); 
num_minis = sum(cellfun(@length,mini_frames,'UniformOutput',1)); 
fprintf('Found %g minis from %g ROIs (%g total ROIs)\n',num_minis,...
        num_rois_w_mini,num_rois); 
%%
aligned_minis = cell2mat(mini_traces(~cellfun(@isempty,mini_traces)));
mini_frames_lin = cell2mat(mini_frames'); % convert to column vector
% Convert to deltaF/F0
mini_baselines_lin = cell2mat(mini_baselines')'; % convert to row vector 
% baselines = mean(aligned_minis(1:nframes_back,:),1);
mini_deltaF_F_traces = (aligned_minis-abs(mini_baselines_lin))./abs(mini_baselines_lin); % subtract/divide each column by corresponding baseline
mini_peaks_deltaF_F = cell(1,num_rois);
mini_F_traces_roi = cell(1,num_rois);
mini_deltaF_F_traces_roi = cell(1,num_rois);
for i = 1:num_rois
    if ~isempty(mini_frames{i})
        mini_peaks_deltaF_F{i} = mini_deltaF_F_traces(nframes_back+1,roi_inds == i)';
        mini_F_traces_roi{i} = aligned_minis(:,roi_inds == i);
        mini_deltaF_F_traces_roi{i} = mini_deltaF_F_traces(:,roi_inds == i);
    end
end
mini_peaks_deltaF_F_lin = cell2mat(mini_peaks_deltaF_F'); % col vector
output = struct();
output.F = F; % Original raw traces
output.F_filt = F_filt; % Output of all filters (bandpass + smoothing + deconv)
output.F_filt1 = F_filt1; % Output of 1st filter (bandpass)
output.F_deconv = F_deconv; % Output of deconvolution (before refiltering)
output.mini_frames = mini_frames; % num_rois x 1 cell array of mini peak frames in each ROI - based on raw trace (if in.find_pk_frame > 1)
output.mini_frames_filt = mini_frames_filt; % num_rois x 1 cell array of mini peak frames in each ROI - based on filtered trace
output.mini_baselines = mini_baselines; % 1 x num_rois cell array of mini baselines in each ROI
output.mini_baselines_lin = mini_baselines_lin; % 1 x num_minis vector of baselines of ech mini
output.mini_frames_lin = mini_frames_lin; % num_minis x 1 vector of all mini_frames
output.mini_roi_inds = roi_inds; % num_minis x 1 vector of ROI index 
                                 % corresponding to minis in mini_frames_lin
output.mini_F_traces = aligned_minis; % num_timepoints x num_minis raw 
                                      % fluorescence values of each mini
                                      % aligned to peak
output.mini_F_traces_roi = mini_F_traces_roi; % mini_F_traces organized by roi in cell aray                                      
output.mini_deltaF_F_traces = mini_deltaF_F_traces; % num_timepoints x num_minis
                                                    % deltaF/F traces of
                                                    % each mini aligned to
                                                    % peak
output.mini_deltaF_F_traces_roi = mini_deltaF_F_traces_roi; % deltaF/F traces aligned to peak organized by roi in cell array
output.mini_peaks_deltaF_F = mini_peaks_deltaF_F;% num_rois x 1 cell array of peak deltaF/F values in each ROI
output.mini_peaks_deltaF_F_lin = mini_peaks_deltaF_F_lin; % peak deltaF/F value of 
                                                  % each mini       
output.mini_snr = mini_snr;
output.mini_widths = mini_widths;
output.mini_snr_lin = cell2mat(mini_snr);
output.mini_widths_lin = cell2mat(mini_widths); 
output.evoked_peaks = evoked_peaks; % save evoked stim peaks (empty if no stim)
output.evoked_peaks_filt = evoked_peaks_filt; % save evoked stim peaks from filtered trace (empty if no stim)
output.gauss_fit_params = gauss_fit_params; 
output.settings = in; 
%% Plot results
if in.plot_figs
    % Plot only in ROIs with minis, or if no minis, plot all ROIs
    if num_rois_w_mini > 0
        rois_plot = ~cellfun(@isempty ,mini_frames_filt,'UniformOutput',1);        
        num_rois_plot = num_rois_w_mini;
    else
        rois_plot = true(1,num_rois);
        num_rois_plot = num_rois;
    end
    rois_plot_inds = find(rois_plot);
    F_rois_plot = F_blanked_filt(:,rois_plot); % switch to F_blanked to plot unfiltered trace
    F_rois_plot = F_rois_plot - mean(F_rois_plot,1,'omitnan');
%     F_rois_plot = F_rois_plot - F_rois_plot(non_nan_frames(1),:);
    mini_frames_plot = mini_frames_filt; % switch to mini_frames if plotting unfiltered trace
    non_nan_frames = find(~isnan(F_rois_plot(:,1)));
    if isempty(in.offset_factor)
        in.offset_factor = quantile(max(F_rois_plot,[],1,'omitnan')-mean(F_rois_plot,1,'omitnan'),0.9)*1.1;
    end
    offset = linspace(num_rois_plot*in.offset_factor,...
                    0,num_rois_plot);
    % Plot full time course with minis marked
    fig1 = figure('Units',fig_units,'Position',fig_pos);
    plot(x_full,F_rois_plot  + offset);
    hold on; box off; axis tight;
    if num_rois_plot > 1
        doffset = (offset(1)-offset(2));
    else
        doffset = 0;
    end
    for i = 1:num_rois_plot
        ii = rois_plot_inds(i);
        if ~isempty(mini_frames_plot{ii})
            plot(x_full(mini_frames_plot{ii}),offset(i)+doffset*0.5,'r*','MarkerSize',12)
        end
    end
    if in.num_frames_skip_start_end > 0
        xlim([x_full(in.num_frames_skip_start_end),x_full(end-in.num_frames_skip_start_end)]);
    else
        xlim([x_full(1),x_full(end)]);
    end
    ax = gca;
    ax.YTick = fliplr(offset);
    ax.YTickLabel = fliplr(rois_plot_inds);
    xlabel(ax,xaxis_label);
    title(in.trial_name,'Interpreter','none')
    if save_figs
        printFig(fig1,fig_dir,[fig_basename '_filtF_w_minis'],...
            'formats','png','resolutions','-r300');        
    end
    % Plot minis within each ROI overlaid
    if num_rois_w_mini > 0
%         y_lim = [-max(mini_peaks_deltaF_F_lin)*0.5 1.05*max(mini_peaks_deltaF_F_lin)];
        y_lim = []; 
        fig2 = figure('Units',fig_units,'Position',fig_pos);
        plotTracesOverlaidGrid_ROIs(x_mini,mini_deltaF_F_traces,roi_inds,...
                                    'peaks',mini_peaks_deltaF_F,...
                                    'xaxis_label',xaxis_label,...
                                    'y_lim',y_lim,...
                                    'title',in.trial_name);        
        if save_figs
            printFig(fig2,fig_dir,[fig_basename '_minis_overlaid'],...
                'formats','png','resolutions','-r300');
        end
    end
end
end

function [F_blanked,F_blanked_filt,evoked_peaks,evoked_peaks_filt] = ...
            blankStimAndExtractPeaks(F,F_filt,stim_frames,blank_around_stim)
% Blank out frames after stimulus
num_rois = size(F,2);
evoked_peaks = zeros(length(stim_frames),num_rois);
evoked_peaks_filt = zeros(length(stim_frames),num_rois);
F_blanked = F; % raw traces
F_blanked_filt = F_filt; % filtered traces
for i = 1:length(stim_frames)
    stim_framei = stim_frames(i);
    stim_inds = (stim_framei-blank_around_stim(1)):(stim_framei+blank_around_stim(2));
    F_blanked(stim_inds,:) = nan; % blank out frames around stimulus
    F_blanked_filt(stim_inds,:) = nan; % blank out frames around stimulus
    evoked_peaks(i,:) = max(F(stim_inds,:),[],1);
    evoked_peaks_filt(i,:) = max(F_filt(stim_inds,:),[],1);
end
end