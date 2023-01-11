function out = downSampleRecording(recording,down_sample_factor,mode)
%DOWNSAMPLERECORDING Temporally downsample recording by integer factor
%  
%   Inputs 
%   ------ 
%   recording : Recording object or m x n x T image stack
%   down_sample_factor : integer
%                       downsample by summing or averaging every 
%                       down_sample_factor frames 
%   mode : char
%          'sum' or 'mean', determines whether frames are added or
%          averaged
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if nargin < 3
    mode = 'sum'; % 'sum' or 'mean'
end
if ischar(recording)    
    recording = Recording(recording);
    recording.load(); 
    data = recording.vals; 
    out_mode = 1; 
elseif isnumeric(recording)
    data = recording; % input recording as 3D array
    out_mode = 2; 
elseif isa(recording,'Recording')
    if ~recording.loaded
        recording.load();
    end
    data = recording.vals;     
    out_mode = 1; 
end
[m,n,T] = size(data);
% if mod(T,2) ~= 0 % check if odd number of frames
%     data = data(:,:,1:end-1); % remove last odd frame
%     fprintf('Odd number of frames (%g), removed final frame\n',T)
%     T = T - 1;     
% end
down_sample_factor = uint16(down_sample_factor); % convert to integer
fprintf('Downsampling recording by factor of %g\n',down_sample_factor)
rem_frames = mod(T,down_sample_factor);
if  rem_frames ~= 0
    data = data(:,:,1:end-rem_frames);
    fprintf('Number of frames (%g) not divisible by %g, removed %g frames\n',...
        T,down_sample_factor,rem_frames)
    T = T - rem_frames;     
end
switch mode
    case 'sum'
        data2 = squeeze(sum(reshape(data,m,n,[],uint16(T/down_sample_factor)),3));
    case 'mean'
        data2 = squeeze(mean(reshape(data,m,n,[],uint16(T/down_sample_factor)),3));
end
switch out_mode
    case 1 % loaded Recording above
        recording2 = recording.copy(); 
        recording2.imsize = size(data2);   
        recording2.vals = data2; 
        recording2.img_name = sprintf('%s_%gXdownsample',recording.img_name,...
                                     down_sample_factor);
        out = recording2;     
    case 2 
        out = data2; % input recording as 3D array
end

end