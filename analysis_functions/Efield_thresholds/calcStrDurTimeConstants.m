function [tau,rb,rsq,fits]  = calcStrDurTimeConstants(pws,data,mode,varargin)
%CALCSTRDURTIMECONSTANTS ... 
%  
%   Inputs 
%   ------ 
%   pws : vector of pulse-widths 
%           note: tau will be in same units of input pws
%   data : length(pws) x num_trials array of thresholds
%   mode : integer 
%           mode = 1  - chronaxie (Weiss)
%           mode = 2 - time constant (Lapicque exp func) 
%           mode = 3 - time constant (Lapicque base 2)
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 


in.lower = [0,0]; % [rheobase,time constant]
in.upper = [max(data,[],'all'),max(pws)*5];  
in.startpoint = [1,mean(pws)]; 
in = sl.in.processVarargin(in,varargin);

s = fitoptions('Method','NonlinearLeastSquares','Lower',in.lower,...
        'Upper',in.upper,'Startpoint',in.startpoint); % [uA,ms]
switch mode
    case 1 % chronaxie
        f = fittype('a*(1+b*x^-1)','options',s); % Weiss equation  
    case 2 % time constant, base e
        f = fittype('a./(1-exp(-x/b))','options',s); % Lapicque Equation for str-duration curve
    case 3 % time constant, base 2
        f = fittype('a./(1-2.^(-x/b))','options',s); % Lapicque Equation for str-duration curve
end
N = size(data,2);
if isrow(pws)
    pws = pws';
end
tau = zeros(1,N); % time constant or chronaxie in ms 
rb = zeros(1,N); % rheobase in threshold units 
rsq = zeros(1,N); % R^2 of fit
fits = cell(1,N); 
for i = 1:N
    [fiti,gofi] = fit(pws,data(:,i),f);
    tau(i) = fiti.b; 
    rb(i) = fiti.a;  
    rsq(i) = gofi.rsquare;     
    fits{i} = fiti; 
end
if N == 1
    fits = fits{1}; 
end
end