function [F_filt,F_filt1] = filterTracesForEventDetection(F,fs,fc,filt_order,...
                                                        filt_type,smooth_filt_width,...
                                                        smooth_filt_type)
%FILTERTRACESFOREVENTDETECTION ... 
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
% High pass filter to slow fluctuations (x-y drift or photobleaching)
if filt_order > 0
    if strcmp(filt_type,'butter')
        if length(fc) == 1
            [b,a] = butter(filt_order,fc/(fs/2),'high');
            fprintf('Applied %g order high pass butterworth filter with %g Hz cutoff\n',...
                filt_order,fc);
        elseif length(fc) == 2 % bandpass
            [b,a] = butter(filt_order,fc/(fs/2),'bandpass');
            fprintf('Applied %g order band pass butterworth filter with %g to %g Hz cutoffs\n',...
                filt_order,fc(1),fc(2));
        end
        F_filt1 = filtfilt(b,a,F);
    elseif strcmp(filt_type,'gauss')
        if length(fc) == 1 % low pass
            F_filt1 = gaussfilter(F,fs,fc);
            fprintf('Applied low pass gaussian filter with %g Hz cutoffs\n',...
                fc);
        elseif length(fc) == 2 % bandpass
            F_filt1 = gaussfilter(F,fs,fc(2)); % low pass
            F_filt1 = F_filt1 - gaussfilter(F_filt1,fs,fc(1)); % hi pass
            fprintf('Applied band pass gaussian filter with %g to %g Hz cutoffs\n',...
                fc(1),fc(2));
        end
    else
        error('%s filter type not implemented',filt_type);
    end
else
    F_filt1 = F; % for next filter step
end
% median filter to remove high freq noise
if smooth_filt_width > 0
    if strcmp(smooth_filt_type,'med')
        F_filt = medfilt1(F_filt1,smooth_filt_width );
        fprintf('Applied median filter with width %g\n',smooth_filt_width );
    elseif strcmp(smooth_filt_type,'sgolay')
        sgolay_order = 3;
        F_filt = sgolayfilt(F_filt1,sgolay_order,smooth_filt_width);
        fprintf('Applied %g order Savinsky Golay filter with width %g\n',...
            sgolay_order, smooth_filt_width );
    end
else
    F_filt = F_filt1;
    fprintf('Skipping smoothing filter\n')
end