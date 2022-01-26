function output = detect_minis(F,settings,method,varargin)
% DETECT_MINIS
% F - matrix
%   mean fluorescence traces in each ROI [num_time_points x num_rois]
% settings - struct
%   structure with algorithm settings
%   for method 1:
%       nframes_back
%       nframes_forward
%       roi_with_mini_index
%       blank_around_stim
in.apply_filter = 0;
in.filt_order = 3; % order of butterworth filter
in.fc = 2/3; % Hz high pass filter cutoff
in.med_filt_width = 5;
in.plot_figs = 1;
in = sl.in.processVarargin(in,varargin);
if in.apply_filter
    % High pass filter to slow fluctuations (x-y drift or photobleaching)
    if in.filt_order > 0
        [b,a] = butter(in.filt_order,in.fc/(settings.sampling_rate/2),'high');    
        F_filt = filtfilt(b,a,F); 
        fprintf('Applied %g order high pass butterworth filter with %g Hz cutoff\n',...
                in.filt_order,in.fc); 
    else
        F_filt = F; % for next filter step
    end
    % median filter to remove high freq noise
    if in.med_filt_width > 0
        F_filt = medfilt1(F_filt,in.med_filt_width);
        fprintf('Applied median filter with width %g\n',in.med_filt_width);
    end
else
    F_filt = F;
    fprintf('Skipped filtering step\n'); 
end
switch method
    case 1 % Simple method using threshold based on noise level (std)
        sampling_rate = settings.sampling_rate;
        nframes_back = settings.nframes_back;
        nframes_forward = settings.nframes_forward; 
        roi_with_mini_index = settings.roi_with_mini_index;
        stim_frame = settings.stim_frame;
        blank_around_stim = settings.blank_around_stim; 
        threshold = settings.threshold; 
        min_mini_width = settings.min_mini_width; 
        % get noise level
        F_blanked = F_filt;
        F_blanked((stim_frame-blank_around_stim):(stim_frame+blank_around_stim),:) = nan; % blank out frames around stimulus
        F_std = std(F_blanked,0,1,'omitnan'); % std of signal in each ROI
        F_bl_z = (F_blanked - mean(F_blanked,1,'omitnan'))./F_std; % z score of blanked F traces        
        num_rois = size(F,2); 
        mini_frames = cell(num_rois,1); 
        mini_traces = cell(1,num_rois); 
        roi_inds = []; % ROI index for each mini
        for i = 1:num_rois
            if any(F_bl_z(:,i) >= threshold)
                [~,mini_framesi] = findpeaks(F_bl_z(:,i),...
                                          'MinPeakHeight',threshold,...
                                          'MinPeakWidth',min_mini_width*sampling_rate,...
                                          'MinPeakDistance',2*min_mini_width*sampling_rate); %,...
%                                           'WidthReference','halfheight'); 
                mini_frames{i} = mini_framesi; 
                roi_inds = [roi_inds;i*ones(length(mini_framesi),1)];
                mini_traces{i} = nan(nframes_back+nframes_forward+1,length(mini_framesi));
                for j = 1:length(mini_framesi) % loop through minis in this ROI
                    mini_framesij = (mini_framesi(j)-nframes_back):(mini_framesi(j)+nframes_forward);
                    mini_framesij(mini_framesij<=0) = nan; % exclude frames outside of recording window
                    mini_framesij(mini_framesij>size(F_bl_z,1)) = nan;
                    include_inds = ~isnan(mini_framesij); % frames to include for this mini
                    % Get mini trace from unfiltered recording
                    mini_traces{i}(include_inds,j) = F(mini_framesij(include_inds),i);
                end        
            else
               mini_frames{i} = [];  
            end
        end
        num_rois_w_mini = sum(~cellfun(@isempty,mini_frames,'UniformOutput',1)); 
        num_minis = sum(cellfun(@length,mini_frames,'UniformOutput',1)); 
        fprintf('Found %g minis from %g ROIs (%g total ROIs)\n',num_minis,...
                num_rois_w_mini,num_rois); 
end
aligned_minis = cell2mat(mini_traces(~cellfun(@isempty,mini_traces)));
mini_frames_lin = cell2mat(mini_frames); % convert to vector
% Convert to deltaF/F0
baselines = mean(aligned_minis(1:nframes_back,:),1);
mini_deltaF_F_traces = (aligned_minis-abs(baselines))./abs(baselines); % subtract/divide each column by corresponding baseline
mini_peaks_deltaF_F = cell(num_rois,1);
for i = 1:num_rois
    mini_peaks_deltaF_F{i} = mini_deltaF_F_traces(nframes_back+1,roi_inds == i);
end
mini_peaks_deltaF_F_lin = mini_deltaF_F_traces(nframes_back+1,:);
output = struct();
output.mini_frames = mini_frames; % num_rois x 1 cell array of mini peak frames in each ROI
output.mini_peaks_deltaF_F = mini_peaks_deltaF_F;% num_rois x 1 cell array of peak deltaF/F values in each ROI
output.mini_frames_lin = mini_frames_lin; % num_minis x 1 vector of all mini_frames
output.mini_roi_inds = roi_inds; % num_minis x 1 vector of ROI index 
                                 % corresponding to minis in mini_frames_lin
output.mini_F_traces = aligned_minis; % num_timepoints x num_minis raw 
                                      % fluorescence values of each mini
                                      % aligned to peak
output.mini_deltaF_F_traces = mini_deltaF_F_traces; % num_timepoints x num_minis
                                                    % deltaF/F traces of
                                                    % each mini aligned to
                                                    % peak
output.mini_peaks_deltaF_F_lin = mini_peaks_deltaF_F_lin; % peak deltaF/F value of 
                                                  % each mini                                                    

if in.plot_figs
   t = 0:(1/sampling_rate):(size(mini_deltaF_F_traces,1)-1)/sampling_rate;
   figure; 
   plot(t*1e3,mini_deltaF_F_traces); 
   xlabel('time (ms)'); ylabel('\Delta F/F_{0}'); 
end
end
