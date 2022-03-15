function filt_vals = temporalFiltRecording(vals,filt_order,filt_cutoff,filt_str,sampling_rate)
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