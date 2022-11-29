function decay_fit = fitExpDecay(t,Y,decay_fit_order,varargin)
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
t_fits = cell(1,Ntraces);
for i = 1:Ntraces
    [peak_y,ind] = max(Y(:,i));
    y_fit = Y(ind:end,i);
    t_fit = t(ind:end); t_fit = t_fit - t_fit(1); 
    t_fits{i} = t_fit; 
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
    [fitobj,gof,~] = fit(t_fit,y_fit,f);
    fitobjs{i} = fitobj;
    if gof.rsquare < 0.5
        fprintf('Warning: R^2 of decay fit = %.3f for trace %g\n',...
            gof.rsquare,i);
    end
    gofs{i} = gof;
    rsquare(i) = gof.rsquare;
    A(i) = fitobj.a;
    if decay_fit_order == 1
        taud1(i) = fitobj.b;
    elseif decay_fit_order == 2
        if fitobj.c < fitobj.d
            taud1(i) = fitobj.c;
            taud2(i) = fitobj.d;
            p(i) = fitobj.b;
        else
            taud1(i) = fitobj.d;
            taud2(i) = fitobj.c;
            p(i) = 1 - fitobj.b;
        end
    end
end
decay_fit = struct();    
decay_fit.A = A;
decay_fit.taud1 = taud1;
if decay_fit_order == 2
    decay_fit.taud2 = taud2;
    decay_fit.p = p;
end
decay_fit.rsquare = rsquare;
decay_fit.fitobjs = fitobjs;
decay_fit.gofs = gofs;
decay_fit.t_fits = t_fits; 
