function F_deconv = deconvSingleExp(F,sampling_rate,taud)
%DECONVSINGLEEXP ... 
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
td = (0:(1/sampling_rate):(size(F,1)-2)/sampling_rate)';
fu = [0;exp(-td/taud)];  % unitary response: instantaneous rise and 
                         % monoexponential decay
fft_F = fft(F,[],1); % Fourier transform of signal
fft_fu = fft(fu,[],1); % Fourier transform of unitary response
F_deconv = ifft(fft_F./fft_fu)/1; % deconvolve unitary response from signal
