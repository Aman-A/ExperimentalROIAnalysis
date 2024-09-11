function y_filt = dual_exp_filter(tau1,tau2,p,fs,y)
%DUAL_EXP_FILTER sum of two low pass filters
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
% b1 = [0 1/(tau1*fs)];
% a1 = [1 (1/(tau1*fs) - 1)];
% b2 = [0 1/(tau2*fs)];
% a2 = [1 (1/(tau2*fs) - 1)];
b1 = 1/(1+2*tau1*fs).*[1 1];
a1 = [1 (1-2*tau1*fs)/(1+2*tau1*fs)];                
b2 = 1/(1+2*tau2*fs).*[1 1];
a2 = [1 (1-2*tau2*fs)/(1+2*tau2*fs)];     
y_filt1 = filter(b1,a1,y);
y_filt2 = filter(b2,a2,y);
y_filt = y_filt1*p + y_filt2*(1-p); 