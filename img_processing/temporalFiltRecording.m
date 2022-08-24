function filt_recording = temporalFiltRecording(recording,filt_order,filt_cutoff,...
                                            filt_str,sampling_rate)
%TEMPORALFILTRECORDING ... 
%  
%   Inputs 
%   ------ 
%   vals : m x n x k aray - recording image stack
%          m x n pixels x k frames (time points)
%   filt_order : integer
%                order of butterworth filter
%   filt_cutoff : scalar or 1 x 2 vector
%                 filter cutoff in Hz
%   filt_str : string
%              'low', 'high', or 'bandpass' (needs 1 x 2 filt_cutoff
%              vector)
%   sampling_rate : scalar
%                   Recording sampling rate in Hz

%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if ischar(recording)    
    recording = Recording(recording);
    recording.load(); 
    vals = recording.vals; 
    out_mode = 1; 
elseif isnumeric(recording)
    vals = recording; % input recording as 3D array
    out_mode = 2; 
elseif isa(recording,'Recording')
    recording.load();
    vals = recording.vals;     
    out_mode = 1; 
end

[b,a] = butter(filt_order,filt_cutoff/(sampling_rate/2),filt_str);
[nrows,ncols] = size(vals,[1 2]);
filt_vals = zeros(size(vals));
tic
for i = 1:nrows
    for j = 1:ncols
        filt_vals(i,j,:) = filtfilt(b,a,squeeze(vals(i,j,:)));
    end
end
toc

switch out_mode
    case 1 % loaded Recording above
        recording.vals = filt_vals; 
        filt_recording = recording;     
    case 2 
        filt_recording = filt_vals; % input recording as 3D array
end

end