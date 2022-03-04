function mean_diff = meanDiffImage(vals,stim_frames,baseline_wind,stim_wind)
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
img_size = size(vals,[1 2]);
mean_diff = zeros(img_size);
num_stim = length(stim_frames);
for i = 1:num_stim
    peaki = max(vals(:,:,stim_frames(i):(stim_frames(i)+stim_wind)),[],3); % max at each pixel
    bslinei = mean(vals(:,:,(stim_frames(i)-baseline_wind):(stim_frames(i)-1)),3); % mean at each pixel
    mean_diff = mean_diff + peaki - bslinei;
%     mean_diff = mean_diff + (peaki - bslinei)./bslinei;
end
mean_diff = mean_diff/num_stim; % average
end