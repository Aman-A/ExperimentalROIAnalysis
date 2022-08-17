function yout = gaussfilter(yin, sampfreq, cornerfreq,mode)
% YOUT = GAUSSFILTER(YIN, SAMPFREQ, CORNERFREQ)
% returns the Gaussian filtered version of YIN. SAMPFREQ is the sampling frequency
% CORNERFREQ is the corner frequency of the Gaussian
% Hugh Robinson, University of Cambridge
% Example usage: filter a sweep acquired at 20000 Herz at a corner frequency of 1 kHz:
% Modified by Aman Aberra 8/16/22:
% Allow for application of filter to multiple waveforms input as columns of matrix
% Add mode argument for either causal filter (1) or zero-phase filter (2)
if nargin < 4
    mode = 1; % 1 - causal, forward filter, 2 - acausal, zero-phase filter
end
fc = cornerfreq/sampfreq;  
sigma = 0.132505/fc;
nc = round(4*sigma); 
coeffs = -nc:nc;
coeffs = exp((-coeffs.^2)/(2*sigma^2))/(sqrt(2*pi)*sigma);
% yout = zeros(size(yin) + [nc*2 0]);
yout = zeros(size(yin));
for i = 1:size(yin,2)
    yout(:,i) = conv(yin(:,i),coeffs,'same');
end
if mode == 2
    for i = 1:size(yin,2)
        yi = conv(flipud(yout(:,i)),coeffs,'same');
        yout(:,i) = flipud(yi);
%         yi = conv(flipud(yout(:,i)),coeffs,'same');
%         yout(:,i) = flipud(yi);
    end
end
% yout = yout(nc+1:end-nc,:);  % chop off ends so that same length as yin

% if ~iscolumn(yout)
%     yout=yout';
% end
end