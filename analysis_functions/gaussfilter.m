function yout = gaussfilter(yin, sampfreq, cornerfreq)
% YOUT = GAUSSFILTER(YIN, SAMPFREQ, CORNERFREQ)
% returns the Gaussian filtered version of YIN. SAMPFREQ is the sampling frequency
% CORNERFREQ is the corner frequency of the Gaussian
% Hugh Robinson, University of Cambridge
% Example usage: filter a sweep acquired at 20000 Herz at a corner frequency of 1 kHz:
% Modified by Aman Aberra 8/16/22 (allows for application of filter to
% multiple waveforms input as columns of matrix)

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
% yout = yout(nc+1:end-nc,:);  % chop off ends so that same length as yin

% if ~iscolumn(yout)
%     yout=yout';
% end
end