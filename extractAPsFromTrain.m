function [tAP, mean_APs_all, deltaF_F0_all, peak_frames_all, means, t] = extractAPsFromTrain(means,...                                                                  
                                                                  exp_settings,...
                                                                  varargin)
%EXTRACTAPSFROMTRAIN ... 
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
in.AP_window = 50e-3; % time window (or frames) around AP peak to extract, specify units below
                      % E.g. 50e-3 gives 25 ms before and after peak of
                      % each AP. If single value, is symmetric window
                      % around peak or stim frame (depending on method
                      % specified below). Or, can enter 1x2 vector to
                      % specify asymmetric window, e.g. [4 6]*1e-3 is 4 ms
                      % before and 6 ms after stim/peak time                       
in.AP_window_units = 'sec'; % specify units of AP_window, 'sec' or 'frames'
in.min_interAP_interval = 0.95; % min time between APs defined as 
                                % proportion of inter-stimulus interval 
                                % (for method 2)
in.min_AP_width = 0.3e-3; % min AP width (sec) (for method 2)
in.plot_roi_ind = 1; % specify ROIs to plot in 2nd subplot (averaged waveforms overlaid)
in.font_size = 16; 
in.filt_order = 0; % Order of high-pass filter (acausal), set to 0 to turn off
in.filt_cutoff = 0; % cutoff frequencies of filters [low high] (Hz) Default: [0.5 Hz]
in.remove_initial_timepoints = 0.05; % 0.05 remove this duration from beginning of trace (sec)
in.print_level = 1;
in.method = 1; % 1 - find APs based on stim frames, 2 - find APs based on peaks
in.save_fig = 0;
in.fig_dir = pwd;
in.fig_basename = 'extractAPs';
in.y_lim2 = []; 
in.biphasic_mode = 0;
in.inds1 = 1:2:length(exp_settings.stim_vals);
in.inds2 = 2:2:length(exp_settings.stim_vals);
in = sl.in.processVarargin(in,varargin); 
%% Get frames vector and stimulus vector (frames when stimuli occurred)
exp_settings.convert2Frames(); % make sure units are in frames
stim_frames = exp_settings.stim_vals;
baseline_wind = exp_settings.baseline_wind;
baseline_start_frame = exp_settings.baseline_start_frame;
frames = (1:length(means));
t = (0:(length(means)-1))/exp_settings.sampling_rate;
num_rois = size(means,2);
%% Cut out transients in early frames (generally get sharp transient in voltage recordings)
if in.remove_initial_timepoints > 0    
    if in.print_level > 0
        fprintf('Removing first %g frames (%.1f ms)\n',sum(t <= in.remove_initial_timepoints),...
                                                      in.remove_initial_timepoints*1e3); 
    end    
    means = means(t > in.remove_initial_timepoints,:);
    frames = frames(t > in.remove_initial_timepoints);
    t = t(t > in.remove_initial_timepoints); 
end
%% Apply high pass filter to remove exponential decay from bleaching 
if in.filt_order > 0
    if length(in.filt_cutoff) == 1
        filt_str = 'high';
    else
        filt_str = 'bandpass';
    end
    [b,a] = butter(in.filt_order,in.filt_cutoff/(exp_settings.sampling_rate/2),filt_str);
    means = filtfilt(b,a,means); 
    if in.print_level > 0
        fprintf('Applied %g order butterworth filter with fc = %.2f Hz\n',...
                  in.filt_order,in.filt_cutoff);
    end
end
%% Get size of window around each AP to extract in frames
% Convert AP_window to frames if necessary
if strcmp(in.AP_window_units,'sec') 
    AP_window = ceil(in.AP_window*exp_settings.sampling_rate);
end
% Make sure format is [frames_before frames_after]; 
if length(AP_window) == 1
   AP_window = ceil([AP_window/2 AP_window/2]); % round up if AP_window is odd    
end
numAPframes = sum(AP_window) + 1; % include stim/peak frame in count
% Check that baseline window fits in AP window
if baseline_wind > AP_window(1)
   baseline_wind = AP_window(1) - baseline_start_frame - 1; 
end
% Get frames and data post first stimulus, including pre-stimulus frames
% based on AP_window
frames_post_stim = frames(frames>(stim_frames(1)-AP_window(1)));
means_post_stim = means(frames>(stim_frames(1)-AP_window(1)),:);
%% Extract spikes using Method 1: stimulus frames (timing) or Method 2: Peaks
if in.method == 1 % NOTE: Requires precise alignment of stimulus times to image frames
    fprintf('Method %g: Detecting APs using stimulus frames\n',in.method);    
    % Get peaks for plotting, using peak in stim window
    AP_start_frames_all = repmat({stim_frames+1},1,num_rois);    
    peak_frames_all = cell(1,num_rois);    
    peak_vals_all = cell(1,num_rois);
    for i = 1:num_rois
        peak_frames_all{i} = zeros(length(stim_frames),1);
        peak_vals_all{i} = zeros(length(stim_frames),1);
        for j = 1:length(stim_frames)
            post_stim_frame_ij = find(frames_post_stim==AP_start_frames_all{i}(j));
            post_stim_frames_ij = post_stim_frame_ij:(post_stim_frame_ij+AP_window(2));
            post_stim_frames_ij(post_stim_frames_ij>length(means_post_stim)) = []; % remove points past recording
            means_post_stim_frames_ij = means_post_stim(post_stim_frames_ij,i);
            [~,ind_ij] =  max(abs(means_post_stim_frames_ij)); % get pos or neg peak
            peak_vals_all{i}(j) = means_post_stim_frames_ij(ind_ij);
            peak_frames_all{i}(j) = frames_post_stim(post_stim_frames_ij(ind_ij)); 
        end
    end
    alignment_frames = AP_start_frames_all; 
elseif in.method == 2
    % Find peaks
    fprintf('Method %g: Detecting APs by finding peaks\n',in.method);
    ISI = min(diff(stim_frames)); % min inter stimulus interval, use for peak finder    
    peak_vals_all = cell(1,num_rois);
    peak_frames_all = cell(1,num_rois);
    for i = 1:num_rois
        [peak_vals,peak_frames] = findpeaks(means_post_stim(:,i),frames_post_stim,...
                                      'NPeaks',length(stim_frames),...
                                      'MinPeakDistance',in.min_interAP_interval*ISI,...
                                      'MinPeakWidth',in.min_AP_width*exp_settings.sampling_rate);
        peak_vals_all{i} = peak_vals;
        peak_frames_all{i} = peak_frames;
        if in.print_level > 0
            fprintf('ROI %g: %g peaks found for %g stimuli\n',i,length(peak_vals),...
                                                                length(stim_frames)); 
        end
    end                                  
    alignment_frames = peak_frames_all; 
end
tAP = 1e3*(1:numAPframes)/exp_settings.sampling_rate; % convert to ms
tAP = tAP - tAP(AP_window(1)+1); % center around peak or first post-stimulus frame
%% Extract APs
% Grab window around first post-stimulus frame (method 1) or each peak
% (method 2) for averaging
mean_APs_all = cell(1,num_rois);
deltaF_F0_all = cell(1,num_rois);
for j = 1:num_rois
    align_framesj = alignment_frames{j};
    AP_framesj = nan(numAPframes,length(align_framesj)); % [num of stim frames x num of APs]
    for i = 1:length(align_framesj)
        align_framei = find(frames_post_stim == align_framesj(i));
        AP_framesi=(align_framei-AP_window(1)):(align_framei+AP_window(2));
        AP_framesi(AP_framesi<=0) = nan; % exclude frames outside of recording window
        AP_framesi(AP_framesi>length(means_post_stim)) = nan; % exclude frames after end of recording
        include_inds = ~isnan(AP_framesi); % frames to include for this AP
        AP_framesj(include_inds,i) = means_post_stim(AP_framesi(include_inds),j);          
    end
    mean_APs_all{j} = AP_framesj; 
    baselinesj = mean(AP_framesj(AP_window(1)-baseline_start_frame-baseline_wind:AP_window(1)-baseline_start_frame,:),1);
    if in.filt_order > 0 % baseline removed due to high pass filter, just get deltaF
        deltaF_F0_all{j} = (AP_framesj - baselinesj); % get DF/F using AP-specific baseline (for jth roi)
    else
        deltaF_F0_all{j} = (AP_framesj - baselinesj)./baselinesj; % get DF/F using AP-specific baseline (for jth roi)
    end
end
% AP_winds(:,end) = [];

t = 1e3*(frames - 1)/exp_settings.sampling_rate; 
% Plot
cols = {'k','r'};
light_cols = {0.4*ones(1,3),0.4*[1 0 0]};
for i = 1:num_rois
    fig = figure; 
    ax1 = subplot(2,1,1);
    plot(ax1,t,means(:,i),'Color',cols{1}); hold on;
    plot(ax1,1e3*(peak_frames_all{i}-1)/exp_settings.sampling_rate,...
        peak_vals_all{i},'o','Color',light_cols{1});
    if in.filt_order > 0
        title(sprintf('Mean F - %g order high pass filter with %.1f Hz cutoff\n',...
                  in.filt_order,in.filt_cutoff)); 
    else
        title(sprintf('ROI %g: Mean F',i));  
    end
    ylabel(ax1,'Mean F (a.u.)');     
    box(ax1,'off');
    ax1.FontSize = in.font_size;
%     ax1.XLim = [frames(1),frames(end)];
%     xlabel(ax1,'Frames'); 
%     ax1.XLim = [0.9*1e3*stim_frames(1)/exp_settings.sampling_rate t(end)]; 
    ax2 = subplot(2,1,2);
    
    if in.biphasic_mode
        plot(ax2,tAP,deltaF_F0_all{i}(:,in.inds1),'Color',light_cols{1},'LineWidth',0.5,'Marker','.'); hold on;
        plot(ax2,tAP,mean(deltaF_F0_all{i}(:,in.inds1),2,'omitnan'),cols{1},'LineWidth',2); 
        plot(ax2,tAP,deltaF_F0_all{i}(:,in.inds2),'Color',light_cols{2},'LineWidth',0.5,'Marker','.'); 
        plot(ax2,tAP,mean(deltaF_F0_all{i}(:,in.inds2),2,'omitnan'),cols{2},'LineWidth',2); 
    else
        plot(ax2,tAP,deltaF_F0_all{i},'Color',light_cols{1},'LineWidth',0.5,'Marker','.'); hold on;
        plot(ax2,tAP,mean(deltaF_F0_all{i},2,'omitnan'),cols{1},'LineWidth',2); 
    end
    if in.filt_order > 0
        ylabel(ax2,'\DeltaF');
    else
        ylabel(ax2,'\DeltaF/F_{0}'); 
    end
    box(ax2,'off');     
    ax2.FontSize = in.font_size;
    ax2.XLim = [tAP(1), tAP(end)]; 
    xlabel(ax2,'Time (ms)'); 
    plot(ax1,1e3*stim_frames/exp_settings.sampling_rate,ax1.YLim(2)*0.99*ones(1,length(stim_frames)),...
    'r.','MarkerSize',8,'DisplayName','Stim times');
    if ~isempty(in.y_lim2)
       ax2.YLim = in.y_lim2;  
    end
    if in.save_fig
        fig_name = sprintf('%s_roi%g',in.fig_basename,i);
        printFig(fig,in.fig_dir,fig_name,...
            'formats',{'fig','png'},'resolutions',{'','-r300'})
    end    
end 