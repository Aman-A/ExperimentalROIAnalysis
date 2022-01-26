function mini_frames = detect_minis(F,settings,method,varargin)
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
in.plot_figs = 1;
in = sl.in.processVarargin(in,varargin);

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
        F_blank = F;
        F_blank((stim_frame-blank_around_stim):(stim_frame+blank_around_stim),:) = nan; % blank out frames around stimulus
        F_std = std(F_blank,0,1,'omitnan'); % std of signal in each ROI
        thresholds = threshold*F_std; 
        num_rois = size(F,2); 
        mini_frames = cell(num_rois,1); 
        mini_traces = cell(1,num_rois); 
        roi_inds = []; % ROI index for each mini
        for i = 1:num_rois
            if any(F_blank(:,i) >= thresholds(i))
                [mini_peak,mini_frames{i}] = findpeaks(F_blank(:,i),...
                                          'MinPeakHeight',thresholds(i),...
                                          'MinPeakWidth',min_mini_width*sampling_rate,...
                                          'MinPeakDistance',2*min_mini_width*sampling_rate); %,...
%                                           'WidthReference','halfheight'); 
                roi_inds = [roi_inds;i*ones(length(mini_frames{i}),1)];
                mini_traces{i} = nan(nframes_back+nframes_forward+1,length(mini_frames{i}));
                for j = 1:length(mini_frames{i})
                    mini_framesij = (mini_frames{i}(j)-nframes_back):(mini_frames{i}(j)+nframes_forward);
                    mini_framesij(mini_framesij<=0) = nan; % exclude frames outside of recording window
                    mini_framesij(mini_framesij>size(F,1)) = nan;
                    include_inds = ~isnan(mini_framesij); % frames to include for this mini
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
if in.plot_figs
   t = 0:(1/sampling_rate):(size(mini_deltaF_F_traces,1)-1)/sampling_rate;
   figure; 
   plot(t*1e3,mini_deltaF_F_traces); 
   xlabel('time (ms)'); ylabel('\Delta F/F_{0}'); 
end
end
