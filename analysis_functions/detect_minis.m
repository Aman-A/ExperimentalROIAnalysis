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
% To do: Add width criteria based on upstroke/downstroke of mini (FWHM?)
in.apply_filter = 0;
in.filt_type = 'gauss'; % 'butter' or 'gauss'
in.filt_order = 3; % order of butterworth filter
in.fc = [0.5 30]; % 0.5 to 60 Hz high pass filter cutoff
in.smooth_filt_type = 'med'; %'med' or 'sgolay'
in.smooth_filt_width = 5; % 5 for med or 15 for sgolay
in.plot_figs = 1;
in.plot_filt_output = 1; 
in.deconv = 0; 
in.deconv_tau = 35e-3; % sec (~35 ms is mean decay time constant from my 
                       % evoked GluSnFR3 measurements)
in.refilter_deconv = 1;     
in.num_frames_skip_start_end = 100; % frames to remove from start/end due to filtering artifacts
in.offset_factor = 1.01; 
in.use_asls_baseline = 1; % set to 1 to use asymmetric least squares baseline detection
in.find_pk_frame = 3; % number of frames around original peak to search in unfiltered traces (or 0 to use peak frame from filtered traces)
in = sl.in.processVarargin(in,varargin);
num_rois = size(F,2); 
sampling_rate = settings.sampling_rate;
stim_frames = settings.stim_frame;        
blank_around_stim = settings.blank_around_stim; 
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
    if isempty(stim_frames)
        F_deconv = F_deconv ./max(F_deconv(in.num_frames_skip_start_end:end-in.num_frames_skip_start_end,:),[],1,'omitnan');
    else
        F_deconv = F_deconv./max(F_deconv(stim_frames(1):stim_frames(end),:),[],1,'omitnan'); 
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
        gauss_fit_params = zeros(3,num_rois); % 3 parameters
        for i = 1:num_rois
            gauss_fit_params(:,i) = fitHistSingleGaussian(F_filt(:,i),10); % 10 bins per std    
        end
    else
        F_filt = F_deconv; 
    end   
    sigmas = gauss_fit_params(3,:);  % noise level in deconvolved trace    
    [F_blanked,evoked_peaks,evoked_peaks_filt] = ...
        blankStimAndExtractPeaks(F_filt,F,stim_frames,blank_around_stim);
else
    F_filt = F_filt2; 
    F_deconv = F_filt2;    
    % get sigmas below
    [F_blanked,evoked_peaks,evoked_peaks_filt] = ...
        blankStimAndExtractPeaks(F_filt,F,stim_frames,blank_around_stim);
    sigmas = std(F_blanked,0,1,'omitnan');  % noise level in deconvolved trace (omit evoked responses)
end
if in.plot_filt_output
    ii = settings.roi_with_mini_index; 
%     x_lim = [400 550]; % roi 1
%     x_lim = [50 300]; % roi 3
    x_lim = [490 530]; % roi 4
%     x_lim = [540 740]; % roi 5
    % subplot(4,1,1); plot((F(:,1)-mean(F(:,1))/mean(F(:,1)))); xlim([1000 2000]); title('Raw F'); box off; 
    % subplot(4,1,2); plot(F_filt1(:,1)); xlim([1000 2000]); title(sprintf('%s filter',in.filt_type)); box off; 
    % subplot(4,1,3); plot(F_filt2(:,1)); xlim([1000 2000]); title(sprintf('%s + %s',in.filt_type,in.smooth_filt_type)); box off; 
    % subplot(4,1,4); plot(F_filt(:,1)); xlim([1000 2000]); title(sprintf('Deconv with tau_{d} = %g ms',in.deconv_tau*1e3)); box off; 
    figure('Units','inches','Position',[29 5 14 6.5]); 
    ax = subplot(4,1,1); 
    if isempty(settings.stim_frame)
       plot(F(:,ii)-mean(F(1:10,ii))); 
       title('Mean'); 
    else
        plot((F(:,ii)-mean(F(1:settings.stim_frame(1)-1,ii)))/mean(F(:,ii))); 
        hold on; plot(settings.stim_frame,ax.YLim(2)*0.8,'ro');
        title('deltaF/F'); 
    end      
    xlim(x_lim); 
    box off; 
    subplot(4,1,2); % 1st filter
    plot((F_filt1(:,ii)-mean(F_filt1(:,ii))/mean(F_filt1(:,ii)))); xlim(x_lim);
    title(sprintf('%s filter',in.filt_type)); box off; 
    subplot(4,1,3); % 1st filter + smoothing filter
    plot((F_filt2(:,ii)-mean(F_filt2(:,ii))/mean(F_filt2(:,ii)))); xlim(x_lim);
    title(sprintf('%s + %s',in.filt_type,in.smooth_filt_type)); box off; 
    subplot(4,1,4); % filters + deconv
    if in.refilter_deconv
        plot(F_deconv(:,ii)); hold on; plot(F_blanked(:,ii)); xlim(x_lim);
        plot([0,size(F_filt,1)],settings.threshold*sigmas(ii)*[1 1])
        legend('Deconvolved','Deconvolved + refiltered',...
                'Threshold','Box','off','Location','northeast','Orientation','horizontal')
    else
        plot(F_deconv(:,ii)); xlim(x_lim); hold on;
        plot([0,size(F_filt,1)],settings.threshold*sigmas(ii)*[1 1])
    end    
    title(sprintf('Deconv with tau_{d} = %g ms',in.deconv_tau*1e3)); box off; 
    % subplot(4,1,4); plot((F_filt(:,ii)-mean(F_filt(:,ii))/mean(F_filt(:,ii)))); xlim([1000 2000]); title(sprintf('Deconv with tau_{d} = %g ms',in.deconv_tau*1e3)); box off; 
end
%% Peak detection
switch method
    case 1 % Simple method using threshold based on noise level (std)        
        nframes_back = settings.nframes_back;
        nframes_forward = settings.nframes_forward;         
        thresholds = settings.threshold*sigmas; 
        min_mini_width = settings.min_mini_width;     
                
        % get noise level
%         F_std = std(F_blanked,0,1,'omitnan'); % std of signal in each ROI
%         F_bl_z = (F_blanked - mean(F_blanked,1,'omitnan'))./F_std; % z score of blanked F traces        
%         F_pks = F_bl_z; 
        F_findpks = F_blanked;
        if in.num_frames_skip_start_end > 0
            F_findpks(1:in.num_frames_skip_start_end,:) = nan;
            F_findpks(end-in.num_frames_skip_start_end:end,:) = nan;
        end
        % Exclusion criteria
        % Exclude ROIs with evoked SNR < threshold
        snr_thresh = settings.snr_thresh; 
%         mean_evoked_peaks = mean(evoked_peaks,1);        
%         mean_evoked_peaks_filt = mean(evoked_peaks_filt,1);        
%         mean_evoked_peaks_delFF0 = ...
%             (mean_evoked_peaks - mean(F(1:stim_frames(1)-1,:),1))./mean(F(1:stim_frames(1)-1,:),1);
%         std_Fbsline = std((F(1:stim_frames(1)-1,:) - mean(F(1:stim_frames(1)-1,:),1))./mean(F(1:stim_frames(1)-1,:),1));        
%         snr_rois = mean_evoked_peaks_filt./F_std; 
%         exclude_roi = snr_rois < snr_thresh; 
        exclude_roi = false(num_rois,1);
        % Find ROIs        
        mini_frames = cell(num_rois,1); 
        mini_frames_filt = cell(num_rois,1); % frames based on filtered trace
        mini_traces = cell(1,num_rois); 
        mini_baselines = cell(1,num_rois);
        mini_snr = cell(1,num_rois);
        roi_inds = []; % ROI index for each mini
        for i = 1:num_rois
            if any(F_findpks(:,i) >= thresholds(i)) && ~exclude_roi(i)
                [~,mini_framesi,widthsi] = findpeaks(F_findpks(:,i),...
                                          'MinPeakHeight',thresholds(i),...
                                          'MinPeakDistance',3*min_mini_width*sampling_rate,...
                                           'MinPeakWidth',min_mini_width*sampling_rate,... 
                                          'WidthReference','halfprom',... % halfheight or halfprom
                                          'Annotate','extents');                                                 
                mini_framesi_filt = mini_framesi; 
                mini_tracesi = nan(nframes_back+nframes_forward+1,length(mini_framesi));
                baselinesi = nan(nframes_back+nframes_forward+1,length(mini_framesi));
                peaksi = zeros(1,length(mini_framesi));
                for j = 1:length(mini_framesi) % loop through minis in this ROI
                    mini_frame0ij = mini_framesi(j);
                    if in.find_pk_frame > 0
                        % find actual peak frame using unfiltered trace
                        % within find_pk_frame frames of peak detected in
                        % filtered trace above
                        [peaksi(j),loc] = max(F(mini_frame0ij-in.find_pk_frame:mini_frame0ij+in.find_pk_frame,i));
                        mini_frame0ij = mini_frame0ij + (loc - in.find_pk_frame - 1);
                        mini_framesi(j) = mini_frame0ij; % update to new frame
                    end
                    mini_framesij = (mini_frame0ij-nframes_back):(mini_frame0ij+nframes_forward);
                    mini_framesij(mini_framesij<=0) = nan; % exclude frames outside of recording window
                    mini_framesij(mini_framesij>size(F_findpks,1)) = nan;
                    include_inds = ~isnan(mini_framesij); % frames to include for this mini
                    % Get mini trace from unfiltered recording
                    mini_tracesi(include_inds,j) = F(mini_framesij(include_inds),i);
                    if in.use_asls_baseline
                        baselinesi(include_inds,j) = asLS_baseline(mini_tracesi(include_inds,j),5,0.1);
                    end
                end    
                if in.use_asls_baseline
%                     std_baselinesi = std(mini_tracesi(1:nframes_back,:),0,1,'omitnan'); 
                    std_baselinesi = std(baselinesi(1:nframes_back,:),0,1,'omitnan');  % use smoothed baseline trace
                    mean_baselinesi = mean(baselinesi,1,'omitnan');                    
                else
                    std_baselinesi = std(mini_tracesi(1:nframes_back,:),0,1,'omitnan'); 
                    mean_baselinesi = mean(mini_tracesi(1:nframes_back,:),1,'omitnan');
                end                                                 
                if in.find_pk_frame == 0
                    [peaksi] = max(mini_tracesi(nframes_back-3:nframes_back+3,:),[],1,'omitnan');  % check a few frames before after expected peak (differs from filtered trace)
                end
                snri = (peaksi-mean_baselinesi)./std_baselinesi;
                if snr_thresh > 0
                    keep_minis = snri > snr_thresh; 
                    fprintf('Excluded %g minis in ROI %g with SNR < %.1f\n',...
                            sum(~keep_minis),i,snr_thresh)
                else
                    keep_minis = true(1,length(mini_framesi));
                end
                mini_framesi_filt = mini_framesi_filt(keep_minis);
                mini_framesi = mini_framesi(keep_minis);
                mini_traces{i} = mini_tracesi(:,keep_minis);
                mini_frames{i} = mini_framesi; 
                mini_frames_filt{i} = mini_framesi_filt; 
                mini_baselines{i} = mean_baselinesi(keep_minis); 
                mini_snr{i} = snri(keep_minis);
                roi_inds = [roi_inds;i*ones(length(mini_framesi),1)];
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
mini_baselines_lin = cell2mat(mini_baselines);
% baselines = mean(aligned_minis(1:nframes_back,:),1);
mini_deltaF_F_traces = (aligned_minis-abs(mini_baselines_lin))./abs(mini_baselines_lin); % subtract/divide each column by corresponding baseline
mini_peaks_deltaF_F = cell(num_rois,1);
mini_F_traces_roi = cell(num_rois,1);
mini_deltaF_F_traces_roi = cell(num_rois,1);
for i = 1:num_rois
%     mini_peaks_deltaF_F{i} = mini_deltaF_F_traces(nframes_back+1,roi_inds == i);
    mini_peaks_deltaF_F{i} = max(mini_deltaF_F_traces(nframes_back-1:end,roi_inds == i),[],1);
    mini_F_traces_roi{i} = aligned_minis(:,roi_inds == i);
    mini_deltaF_F_traces_roi{i} = mini_deltaF_F_traces(:,roi_inds == i);
end
mini_peaks_deltaF_F_lin = mini_deltaF_F_traces(nframes_back+1,:);
output = struct();
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
output.mini_snr_lin = cell2mat(mini_snr); 
if in.plot_figs
   rois_w_minis = ~cellfun(@isempty ,mini_frames_filt,'UniformOutput',1);
   rois_w_minis_inds = find(rois_w_minis);
%    F_rois_w_minis = (F_filt2 - mean(F_filt2,1,'omitnan'))./mean(F_filt2,1,'omitnan'); 
%       offset = linspace(100*num_rois_w_mini*1.01,...
%                                     0,size(num_rois_w_mini,2)); 
%    F_rois_w_minis = F_bl_z(:,rois_w_minis);
    if in.deconv
        F_rois_w_minis = F_blanked(:,rois_w_minis);
        offset = linspace(num_rois_w_mini*in.offset_factor,...
                            0,num_rois_w_mini);
    else
       F_rois_w_minis = F_blanked(:,rois_w_minis);
       offset = linspace(100*num_rois_w_mini*in.offset_factor,...
                                        0,num_rois_w_mini); 
    end
   t1 = 0:(1/sampling_rate):(size(F_rois_w_minis,1)/sampling_rate - (1/sampling_rate));
   fig1 = figure; 
%    plot(t1,F_rois_w_minis + offset);
   plot(1:length(t1),F_rois_w_minis + offset);
   hold on; box off; axis tight; 
   if num_rois_w_mini > 1
       doffset = (offset(1)-offset(2));
   else
       doffset = 0;
   end
   rois_w_minis_inds = find(rois_w_minis);
   for i = 1:num_rois_w_mini
       ii = rois_w_minis_inds(i);         
%        plot(t1(repmat(mini_frames{ii}',2,1)),...
%            [offset(i);offset(i)+doffset],'r-','LineWidth',2)        
%         plot(t1(mini_frames{ii}),offset(i)+doffset*0.5,'r*','MarkerSize',12)
        plot(mini_frames_filt{ii},offset(i)+doffset*0.5,'r*','MarkerSize',12)
   end
   if in.num_frames_skip_start_end > 0
%        xlim([t1(in.num_frames_skip_start_end),t1(end-in.num_frames_skip_start_end)]);
        xlim([in.num_frames_skip_start_end,length(t1)-in.num_frames_skip_start_end]);
   else
%        xlim([t1(1),t1(end)]);
        xlim([1,length(t1)]);
   end
   ax = gca;
   ax.YTick = fliplr(offset);  
   ax.YTickLabel = flipud(rois_w_minis_inds);
   % minis overlaid
   t = 0:(1/sampling_rate):(size(mini_deltaF_F_traces,1)-1)/sampling_rate;
   fig2 = figure('Units','inches','Position',[4.9 4.2 18.7 8.9]); 
   [Nrows,Ncols] = getSubplotDimensions(num_rois_w_mini);
%    ls = plot(t*1e3,mini_deltaF_F_traces); 
   roi_cols = jet(num_rois_w_mini);
   for i = 1:num_rois_w_mini
       ax = subplot(Nrows,Ncols,i);
       ii = rois_w_minis_inds(i);  
       plot(t*1e3,mini_deltaF_F_traces(:,roi_inds==ii)); hold on;
       plot(t*1e3,mean(mini_deltaF_F_traces(:,roi_inds==ii),2),'k','LineWidth',2); 
       title(sprintf('%g: Peak %.2f +/- %.2f (n = %g)',ii,...
                    mean(output.mini_peaks_deltaF_F{ii}),...
                    std(output.mini_peaks_deltaF_F{ii},0),...
                    length(output.mini_frames{ii})));
%        plot(t*1e3,mini_deltaF_F_traces(:,roi_inds==ii),'Color',roi_cols(i,:)); hold on;
%        [ls(roi_inds==ii).Color] = deal(roi_cols(ii,:)); 
        if i >= ((Nrows-1)*Ncols)
            xlabel(ax,'time (ms)');
        end
        if (mod(i,Ncols) == 1 || num_rois_w_mini == 1) 
            ylabel('\Delta F/F_{0}');    
        end
        box(ax,'off');
        ylim([-0.2 0.4])
   end   
%    xlabel('time (ms)');
%    ylabel('\Delta F/F_{0}');    
end
end

function [F_blanked,evoked_peaks,evoked_peaks_filt] = ...
            blankStimAndExtractPeaks(F_filt,F,stim_frames,blank_around_stim)
% Blank out frames after stimulus
num_rois = size(F,2);
evoked_peaks = zeros(length(stim_frames),num_rois);
evoked_peaks_filt = zeros(length(stim_frames),num_rois);
F_blanked = F_filt; % start with filtered traces
for i = 1:length(stim_frames)
    stim_framei = stim_frames(i);
    stim_inds = (stim_framei-blank_around_stim(1)):(stim_framei+blank_around_stim(2));
    F_blanked(stim_inds,:) = nan; % blank out frames around stimulus
    evoked_peaks(i,:) = max(F(stim_inds,:),[],1);
    evoked_peaks_filt(i,:) = max(F_filt(stim_inds,:),[],1);
end
end