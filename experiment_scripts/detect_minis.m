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
in.filt_type = 'gauss'; % 'butter' or 'gauss'
in.filt_order = 3; % order of butterworth filter
in.fc = [0.5 30]; % 0.5 to 60 Hz high pass filter cutoff
in.smooth_filt_type = 'med'; %'med' or 'sgolay'
in.smooth_filt_width = 5; % 5 for med or 15 for sgolay
in.plot_figs = 1;
in.deconv = 0; 
in.deconv_tau = 35e-3; % sec (~35 ms is mean decay time constant from my 
                       % evoked GluSnFR3 measurements)
in = sl.in.processVarargin(in,varargin);
sampling_rate = settings.sampling_rate;
if in.apply_filter
    % High pass filter to slow fluctuations (x-y drift or photobleaching)
    if in.filt_order > 0
        if strcmp(in.filt_type,'butter')
            if length(in.fc) == 1
                [b,a] = butter(in.filt_order,in.fc/(sampling_rate/2),'high');    
                fprintf('Applied %g order high pass butterworth filter with %g Hz cutoff\n',...
                        in.filt_order,in.fc);
            elseif length(in.fc) == 2 % bandpass
                [b,a] = butter(in.filt_order,in.fc/(sampling_rate/2),'bandpass');    
                fprintf('Applied %g order band pass butterworth filter with %g to %g Hz cutoffs\n',...
                            in.filt_order,in.fc(1),in.fc(2));
            end
            F_filt1 = filtfilt(b,a,F);             
        elseif strcmp(in.filt_type,'gauss')
            if length(in.fc) == 1 % low pass
                F_filt1 = gaussfilter(F,sampling_rate,in.fc);
                fprintf('Applied low pass gaussian filter with %g Hz cutoffs\n',...
                            in.fc);
            elseif length(in.fc) == 2 % bandpass
                F_filt1 = gaussfilter(F,sampling_rate,in.fc(2)); % low pass 
                F_filt1 = F_filt1 - gaussfilter(F_filt1,sampling_rate,in.fc(1)); % hi pass
                fprintf('Applied band pass gaussian filter with %g to %g Hz cutoffs\n',...
                            in.fc(1),in.fc(2));
            end                
        else
            error('%s filter type not implemented',in.filt_type);
        end        
    else
        F_filt1 = F; % for next filter step
    end
    % median filter to remove high freq noise
    if in.smooth_filt_width > 0
        if strcmp(in.smooth_filt_type,'med')
            F_filt = medfilt1(F_filt1,in.smooth_filt_width );
            fprintf('Applied median filter with width %g\n',in.smooth_filt_width );
        elseif strcmp(in.smooth_filt_type,'sgolay')
            sgolay_order = 3; 
            F_filt = sgolayfilt(F_filt1,sgolay_order,in.smooth_filt_width);
            fprintf('Applied %g order Savinsky Golay filter with width %g\n',...
                    sgolay_order, in.smooth_filt_width );
        end
    else
        F_filt = F_filt1; 
        fprintf('Skipping smoothing filter\n')
    end
else
    F_filt = F;
    fprintf('Skipped filtering step\n'); 
end
% figure('Units','inches','Position',[29 5 14 6.5]); 
% subplot(3,1,1); plot(F(:,1)); xlim([1000 2000]); title('Raw F'); box off; 
% subplot(3,1,2); plot(F_filt1(:,1)); xlim([1000 2000]); title(sprintf('%s filter',in.filt_type)); box off; 
% subplot(3,1,3); plot(F_filt(:,1)); xlim([1000 2000]); title(sprintf('%s + %s',in.filt_type,in.smooth_filt_type)); box off; 
%% Deconvolution
if in.deconv
    taud = in.deconv_tau; % 35 ms, mean decay time constant from glusnfr3 measurements
    td = (0:(1/sampling_rate):(size(F,1)-2)/sampling_rate)';
    fu = [0;exp(-td/taud)];
    fft_F = fft(F_filt); fft_fu = fft(fu);
    F_deconv = ifft(fft_F./fft_fu)/1; 
    F_deconv = F_deconv./max(F_deconv,[],1);
    % Filter deconvolved trace again
    F_deconv = filtfilt(b,a,F_deconv);    
    F_filt = F_deconv; 
end

%% Peak detection
num_rois = size(F,2); 
switch method
    case 1 % Simple method using threshold based on noise level (std)        
        nframes_back = settings.nframes_back;
        nframes_forward = settings.nframes_forward; 
%         roi_with_mini_index = settings.roi_with_mini_index;
        stim_frames = settings.stim_frame;
        blank_around_stim = settings.blank_around_stim; 
        if length(blank_around_stim) == 1
            blank_around_stim = [blank_around_stim,blank_around_stim]; 
        end
        threshold = settings.threshold; 
        min_mini_width = settings.min_mini_width;         
        F_blanked = F_filt;
        % Blank out frames after stimulus
        evoked_peaks = zeros(length(stim_frames),num_rois);
        evoked_peaks_filt = zeros(length(stim_frames),num_rois);
        for i = 1:length(stim_frames)
            stim_framei = stim_frames(i); 
            stim_inds = (stim_framei-blank_around_stim(1)):(stim_framei+blank_around_stim(2));
            F_blanked(stim_inds,:) = nan; % blank out frames around stimulus
            evoked_peaks(i,:) = max(F(stim_inds,:),[],1);
            evoked_peaks_filt(i,:) = max(F_filt(stim_inds,:),[],1);
        end
        % get noise level
        F_std = std(F_blanked,0,1,'omitnan'); % std of signal in each ROI
        F_bl_z = (F_blanked - mean(F_blanked,1,'omitnan'))./F_std; % z score of blanked F traces        
        % Exclusion criteria
        % Exclude ROIs with evoked SNR < threshold
        snr_thresh = settings.snr_thresh; 
%         mean_evoked_peaks = mean(evoked_peaks,1);        
        mean_evoked_peaks_filt = mean(evoked_peaks_filt,1);        
%         mean_evoked_peaks_delFF0 = ...
%             (mean_evoked_peaks - mean(F(1:stim_frames(1)-1,:),1))./mean(F(1:stim_frames(1)-1,:),1);
%         std_Fbsline = std((F(1:stim_frames(1)-1,:) - mean(F(1:stim_frames(1)-1,:),1))./mean(F(1:stim_frames(1)-1,:),1));        
        snr_rois = mean_evoked_peaks_filt./F_std; 
%         exclude_roi = snr_rois < snr_thresh; 
        exclude_roi = false(num_rois,1);
        % Find ROIs        
        mini_frames = cell(num_rois,1); 
        mini_traces = cell(1,num_rois); 
        roi_inds = []; % ROI index for each mini
        for i = 1:num_rois
            if any(F_bl_z(:,i) >= threshold) && ~exclude_roi(i)
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
output.F_filt = F_filt; 
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
   rois_w_minis = ~cellfun(@isempty ,mini_frames,'UniformOutput',1);
%    F_rois_w_minis = (F_blanked - mean(F_blanked,1,'omitnan'))./mean(F_blanked,1,'omitnan'); 
    F_rois_w_minis = F_blanked;
%    F_rois_w_minis = F_bl_z(:,rois_w_minis);
   offset = linspace(100*num_rois_w_mini*1.01,...
                                    0,size(F_rois_w_minis,2)); 
   t1 = 0:(1/sampling_rate):(size(F_rois_w_minis,1)/sampling_rate - (1/sampling_rate));
   fig1 = figure; 
   plot(t1,F_rois_w_minis + offset);
   hold on;
   doffset = (offset(1)-offset(2)); 
   rois_w_minis_inds = find(rois_w_minis);
   for i = 1:num_rois_w_mini
       ii = rois_w_minis_inds(i);         
       plot(t1(repmat(mini_frames{ii}',2,1)),...
           [offset(i);offset(i)+doffset],'r-','LineWidth',2)        
   end
   t = 0:(1/sampling_rate):(size(mini_deltaF_F_traces,1)-1)/sampling_rate;
   fig2 = figure; 
   plot(t*1e3,mini_deltaF_F_traces); 
   xlabel('time (ms)'); ylabel('\Delta F/F_{0}'); 
end
end
