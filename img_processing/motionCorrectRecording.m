function out = motionCorrectRecording(recording,ref_frames)
%MOTIONCORRECTRECORDING ... 
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
% Adapted from spikePursuit by Kaspar Podgorski
%
% AUTHOR    : Aman Aberra 

if ischar(recording)    
    recording = Recording(recording);
    recording.load(); 
    data = recording.vals; 
    out_mode = 1; 
elseif isnumeric(recording)
    data = recording; % input recording as 3D array
    out_mode = 2; 
elseif isa(recording,'Recording')
    recording.load();
    data = recording.vals;     
    out_mode = 1; 
end

if nargin < 2
%     N = size(data,3);
%     ref_frames = 1:ceil(N/10); % take first 5% of recording
    ref_frames = 1; % take first frame
end
ref = mean(data(:,:,ref_frames),3); 
refFFT = fft2(ref);
drawnow;
data2 = data; 
% pobj = parpool;
parfor f = 1:size(data,3)
    if ~mod(f,400)
        disp(['registering frame: ' int2str(f)])
    end
    %align data
    [~, G] = dftregistration(refFFT,fft2(data(:,:,f)),4);
    data2(:,:,f) = real(ifft2(G));
end
% delete(pobj);
disp('Done alignment')

switch out_mode
    case 1 % loaded Recording above
        recording.vals = data2; 
        out = recording;     
    case 2 
        out = data2; % input recording as 3D array
end
end
