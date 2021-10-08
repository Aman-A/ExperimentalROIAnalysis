function [tAP, mean_APs_all, deltaF_F0_all, peak_frames_all, means, t] = extractAPsFromTrain(means,...
                                                                  baselines,...
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
                      % each AP
in.AP_window_units = 'sec'; % specify units of AP_window, 'sec' or 'frames'
in.min_interAP_interval = 0.95; % min time between APs defined as proportion of inter-stimulus interval
in.min_AP_width = 0.3e-3; % min AP width (sec)
in.plot_roi_ind = 1; % specify ROIs to plot in 2nd subplot (averaged waveforms overlaid)
in.font_size = 16; 
in.filt_order = 3; % 3 order of high-pass filter, set to 0 to turn off
in.filt_cutoff = 1/2; % 1/3 cutoff frequency of high-pass filter (Hz)
in.remove_initial_timepoints = 0.05; % 0.05 remove this duration from beginning of trace (sec)
in.print_level = 1;
in = sl.in.processVarargin(in,varargin); 
%% Get frames vector and stimulus vector (frames when stimuli occurred)
exp_settings.convert2Frames(); % make sure units are in frames
stim_frames = exp_settings.stim_vals;
frames = (1:length(means));
t = (0:(length(means)-1))/exp_settings.sampling_rate;
%% Cut out transients in early frames (generally get sharp transient in voltage recordings)
if in.remove_initial_timepoints > 0
    means = means(t > in.remove_initial_timepoints,:);
    frames = frames(t > in.remove_initial_timepoints);
    t = t(t > in.remove_initial_timepoints); 
    if in.print_level > 0
        fprintf('Removed first %g frames (%.1f ms)\n',sum(t <= in.remove_initial_timepoints),...
                                                      in.remove_initial_timepoints*1e3); 
    end    
end
%% Apply high pass filter to remove exponential decay from bleaching 
if in.filt_order > 0 && in.filt_cutoff > 0
    [b,a] = butter(in.filt_order,in.filt_cutoff/(exp_settings.sampling_rate/2),'high');
    means = filtfilt(b,a,means); 
    if in.print_level > 0
        fprintf('Applied %g order butterworth filter with fc = %.2f Hz\n',...
                  in.filt_order,in.filt_cutoff);
    end
end
% Get frames and data post first stimulus
frames_post_stim = frames(frames>stim_frames(1)*0.98); % NOTE: 0.98 factor 
                                                       % included due to (temporary) 
                                                       % misalignment of stimulation 
                                                       % with imaging 
means_post_stim = means(frames>stim_frames(1)*0.98,:);
% stim_times = stim_frames/exp_settings.sampling_rate; % WARNING: MAY BE INACCURATE
% stim_times = (stim_delay:(1/stim_freq):t_frames(end));

% Get size of window around each AP to extract in frames
if strcmp(in.AP_window_units,'sec') % convert to frames
    numAPframes = ceil(in.AP_window*exp_settings.sampling_rate);
elseif strcmp(in.AP_window_units,'frames')
    numAPframes = in.AP_window;
end
if mod(numAPframes,2) == 0
   numAPframes = numAPframes + 1;  % make odd
end
ISI = min(diff(stim_frames));
%% Find peaks
num_rois = size(means_post_stim,2);
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
% Grab window around each peak
mean_APs_all = cell(1,num_rois);
deltaF_F0_all = cell(1,num_rois);
for j = 1:num_rois
    AP_framesj = nan(numAPframes,length(peak_frames)); % [num of stim frames x num of APs]
    for i = 1:length(peak_frames)
        stim_framei = find(frames_post_stim == peak_frames(i));
        AP_framesi=(stim_framei-(numAPframes-1)/2):(stim_framei+(numAPframes-1)/2);
        AP_framesi(AP_framesi<0) = nan; % exclude frames before stim
        AP_framesi(AP_framesi>length(means_post_stim)) = nan; % exclude frames after end of recording
        include_inds = ~isnan(AP_framesi) & AP_framesi > 0; % frames to include for this AP
        AP_framesj(include_inds,i) = means_post_stim(AP_framesi(include_inds),j);          
    end
    mean_APs_all{j} = AP_framesj; 
    deltaF_F0_all{j} = (AP_framesj - baselines(:,j)')./baselines(:,j)'; % get DF/F using AP-specific baseline (for jth roi)
end

% AP_winds(:,end) = [];
tAP = 1e3*(1:numAPframes)/exp_settings.sampling_rate; % convert to ms
tAP = tAP - tAP((length(tAP)+1)/2); % center around peak
t = 1e3*(frames - 1)/exp_settings.sampling_rate; 
% Plot
cols = {'k','r'};
light_cols = {0.4*ones(1,3),0.4*[1 0 0]};
figure; 
for i = 1:num_rois
    coli = cols{i}; 
    light_coli = light_cols{i};
    ax1 = subplot(2,1,1);
    plot(ax1,t,means(:,i),'Color',coli); hold on;
    plot(ax1,1e3*peak_frames_all{i}/exp_settings.sampling_rate,peak_vals_all{i},'o','Color',light_coli);
    title(sprintf('Mean F - %g order high pass filter with %.1f Hz cutoff\n',...
                  in.filt_order,in.filt_cutoff)); 
    ylabel(ax1,'Mean F (a.u.)');     
    box(ax1,'off');
    ax1.FontSize = in.font_size;
%     ax1.XLim = [frames(1),frames(end)];
%     xlabel(ax1,'Frames'); 
%     ax1.XLim = [0.9*1e3*stim_frames(1)/exp_settings.sampling_rate t(end)]; 
    ax2 = subplot(2,1,2);
    plot(ax2,tAP,deltaF_F0_all{in.plot_roi_ind},'Color',light_cols{in.plot_roi_ind},'LineWidth',0.5,'Marker','.'); hold on;
    plot(ax2,tAP,mean(deltaF_F0_all{in.plot_roi_ind},2,'omitnan'),cols{in.plot_roi_ind},'LineWidth',2,'Marker','.'); 
    ylabel(ax2,'\DeltaF/F_{0}'); 
    box(ax2,'off');     
    ax2.FontSize = in.font_size;
    ax2.XLim = [tAP(1), tAP(end)]; 
    xlabel(ax2,'Time (ms)'); 
end
plot(ax1,1e3*stim_frames/exp_settings.sampling_rate,ax1.YLim(2)*0.99*ones(1,length(stim_frames)),...
    'r.','MarkerSize',8,'DisplayName','Stim times'); 