function mean_mov = meanMovie(vals,stim_frames,baseline_wind,stim_wind)
%MEANDIFFIMAGE Make movie averaging around every stimulus in recording
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
Nframes = baseline_wind + stim_wind + 1; 
mov_size = [size(vals,[1 2]),Nframes];
mean_mov = zeros(mov_size);
remove_stim_inds = stim_frames + stim_wind > size(vals,3);
if any(remove_stim_inds)
   fprintf('Warning: %g stim frames excluded due to stim_wind exceeding recording length (meanDiffImage)\n',...
           sum(remove_stim_inds));  
   stim_frames(remove_stim_inds) = []; % remove stimuli at frames where window 
                                       % goes beyond 
end
num_trains = size(stim_frames,1);
num_stim = size(stim_frames,2);
for i = 1:num_trains
    for j = 1:num_stim
        mean_mov = mean_mov + vals(:,:,(stim_frames(i,j)-baseline_wind):(stim_frames(i,j)+stim_wind));
    end
end
mean_mov = mean_mov/numel(stim_frames);
end