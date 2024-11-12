function params = fitHistSingleGaussian(y,num_bins_per_std,param0)
%FITHISTSINGLEGAUSSIAN ... 
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   params : [amplitude, mean, st dev] of Gaussian fit
%   Examples 
%   --------------- 
% Based on method of Mendonca 2022, Quantal_Analysis.m script (lines
% 277-299)
% AUTHOR    : Aman Aberra 
if nargin < 2
    num_bins_per_std = 10; 
end
std_vals = std(y,0,'omitnan');
binsize = std_vals/num_bins_per_std;
nbins = round((max(y,[],'omitnan')-min(y,[],'omitnan'))/binsize); % get number of bins
[ycount1,bins1]=histcounts(y,nbins);  
bins1=[bins1(1) bins1(end)];
xbin=linspace(bins1(1),bins1(2),length(ycount1));

%Fitting histogram data with a single Gaussian function
if nargin < 3
    param0=[max(ycount1);mean(y,'omitnan');std(y,0,'omitnan')]; % initial parameters
end
[params,~,~,~,MSE,ErrorModelInfo] = nlinfit(xbin,ycount1,@Gaussian,param0); % nonlinear least-squares regression
% sigma01=params(3); % noise level in deconvolved trace
end

function y = Gaussian(params,x)
    y=params(1).*exp(-(x-params(2)).^2/(2*params(3).^2));
end