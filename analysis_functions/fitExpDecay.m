function fitExpDecay(t,Y,decay_fit_order,varargin)
%FITEXPDECAY Fit traces to monoexponential decay
%  Assumes single response in traces (columns of array)
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.max_taud = 1; % sec
in = sl.in.processVarargin(in,varargin);
Ntraces = size(Y,2);
taud1 = zeros(1,Ntraces); % sec - fast time constant
taud2 = zeros(1,Ntraces); % sec
p = zeros(1,Ntraces); % proportion of fast timeconstant
A = zeros(1,Ntraces); % amplitude (a.u./%)
rsquare = zeros(1,Ntraces); % amplitude (a.u./%)
fitobjs = cell(1,Ntraces);
gofs = cell(1,Ntraces);
for i = 1:Ntraces
    [peak_y,ind] = max(Y(:,i));
    y_fit = Y(ind:end,i);
    t_fit = t(ind:end); t_fit = t_fit - t_fit(1); 
    if decay_fit_order == 1 % monoexponential decay
        % y = A*exp(-t/taud1)
        fit_eqn = 'a*exp(-x/b)';
        upper_bounds = [peak_y,in.max_taud]; % replace first element in loop
        lower_bounds = [0,0];
        start_points = [peak_y*0.8,0.5];
        fprintf('Fitting decay to monoexponential function\n')
    elseif decay_fit_order == 2 % biexponential decay
        % y = A*(p * exp(-t/taud1) + (1-p) * exp(-t/taud2))
        fit_eqn = 'a*(b*exp(-x/c) + (1-b)*exp(-x/d))';
        upper_bounds = [peak_y,1,in.max_taud,in.max_taud];
        lower_bounds = [0,0,0,0];
        start_points = [peak_y*0.8,0.8,0.5,0.5];
        fprintf('Fitting decay to biexponential function\n')
    else
        error('%g decay_fit_order not implemented',decay_fit_order);
    end
    s = fitoptions('Method','NonlinearLeastSquares',...
            'Lower',lower_bounds,...
            'Upper',upper_bounds,...
            'Startpoint',start_points);
    f = fittype(fit_eqn,'options',s);
    [fitobj,gof,~] = fit(t_fit,F_fit,f);
    if decay_fit_order == 1
        taud1(n) = fitobj.b;
    elseif decay_fit_order == 2
        if fitobj.c < fitobj.d
            taud1(n) = fitobj.c;
            taud2(n) = fitobj.d;
            p(n) = fitobj.b;
        else
            taud1(n) = fitobj.d;
            taud2(n) = fitobj.c;
            p(n) = 1 - fitobj.b;
        end
    end
end

% plot(t_fit,F_fit,'r');
% fit
