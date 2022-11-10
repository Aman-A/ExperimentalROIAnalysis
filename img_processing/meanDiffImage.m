function mean_diff = meanDiffImage(vals,stim_frames,baseline_wind,stim_wind,...
                                   peak_mode)
%MEANDIFFIMAGE Averages deltaF image from all stimuli in recording
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
if nargin < 5
    peak_mode = 'max';
end
img_size = size(vals,[1 2]);
mean_diff = zeros(img_size);
remove_stim_inds = stim_frames + stim_wind > size(vals,3);
if any(remove_stim_inds)
   fprintf('Warning: %g stim frames excluded due to stim_wind exceeding recording length (meanDiffImage)\n',...
           sum(remove_stim_inds));  
   stim_frames(remove_stim_inds) = []; % remove stimuli at frames where window 
                                       % goes beyond 
end
num_trains = size(stim_frames,1);
num_stim = size(stim_frames,2);
if ischar(peak_mode)    
    if strcmp(peak_mode,'max')
        for i = 1:num_trains
            mean_diffi = zeros(img_size); % mean image of ith pulse train
            for j = 1:num_stim
                peakj = max(vals(:,:,stim_frames(i,j):(stim_frames(i,j)+stim_wind)),[],3); % max at each pixel for stim j within train
                bslinej = mean(vals(:,:,(stim_frames(i,j)-baseline_wind):(stim_frames(i,j)-1)),3); % mean at each pixel
                mean_diffi = mean_diffi + peakj - bslinej;
            %     mean_diff = mean_diff + (peaki - bslinei)./bslinei;
            end
            mean_diffi = mean_diffi/num_stim; % average across stimuli within train
            mean_diff = mean_diff + mean_diffi;
        end
        mean_diff = mean_diff/num_trains; % average across trains
    elseif strcmp(peak_mode,'mean')
        for i = 1:num_trains
            mean_diffi = zeros(img_size); % mean image of ith pulse train
            for j = 1:num_stim
                peakj = mean(vals(:,:,stim_frames(i,j):(stim_frames(i,j)+stim_wind)),3); % max at each pixel for stim j within train
                bslinej = mean(vals(:,:,(stim_frames(i,j)-baseline_wind):(stim_frames(i,j)-1)),3); % mean at each pixel
                mean_diffi = mean_diffi + peakj - bslinej;
                %     mean_diff = mean_diff + (peaki - bslinei)./bslinei;
            end
            mean_diffi = mean_diffi/num_stim; % average across stimuli within train
            mean_diff = mean_diff + mean_diffi;
        end
        mean_diff = mean_diff/num_trains; % average across trains    
    end
elseif isvector(peak_mode)
    % peak_mode is 1 x 2 vector of start and end post-stim frames to average
    if peak_mode(2) > stim_wind
        peak_mode(2) = stim_wind; 
        fprintf('WARNING: Entered window for averaging in meandiffImage > stim_wind, set to stim_wind\n')
    end
    for i = 1:num_trains
        mean_diffi = zeros(img_size); % mean image of ith pulse train
        for j = 1:num_stim
            peakj = mean(vals(:,:,(stim_frames(i,j)+peak_mode(1)):(stim_frames(i,j)+peak_mode(2))),3); % max at each pixel for stim j within train
            bslinej = mean(vals(:,:,(stim_frames(i,j)-baseline_wind):(stim_frames(i,j)-1)),3); % mean at each pixel
            mean_diffi = mean_diffi + peakj - bslinej;
            %     mean_diff = mean_diff + (peaki - bslinei)./bslinei;
        end
        mean_diffi = mean_diffi/num_stim; % average across stimuli within train
        mean_diff = mean_diff + mean_diffi;
    end
    mean_diff = mean_diff/num_trains; % average across trains
end
end