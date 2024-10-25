function rise_fit = fitExpRise(t,Y,rise_fit_order,varargin)
%FITEXPDECAY Fit traces to monoexponential or biexponential rise
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
in.max_taur = 1; % sec
in.min_taur = 0; % sec
in.align_traces = 1; 
in.print_level = 1; 
in.include_offset = 0; 
in.fit_mode = 1; % 1 - use Nonlinearleast squares with fit function
                 % 2 - use nonlinear regression with fitnlm function
in = sl.in.processVarargin(in,varargin);
if isrow(Y)
    Y = Y';
end
if isrow(t)
    t = t';
end
Ntraces = size(Y,2);
taur1 = zeros(1,Ntraces); % sec - fast time constant
taur2 = zeros(1,Ntraces); % sec
p = zeros(1,Ntraces); % proportion of fast timeconstant
A = zeros(1,Ntraces); % amplitude (a.u./%)
rsquare = zeros(1,Ntraces); % amplitude (a.u./%)
fitobjs = cell(1,Ntraces);
gofs = cell(1,Ntraces);
t_fits = cell(1,Ntraces);
for i = 1:Ntraces    
    if in.align_traces        
        [min_y,ind1] = min(Y(:,i));
        [peak_y,~] = max(Y(:,i));        
        y_fit = Y(ind1:end,i) - min_y; % start at 0
        t_fit = t(ind1:end); 
        t_fit = t_fit - t_fit(1); % start at t = 0
    else       
        t_fit = t; 
        y_fit = Y(:,i);
        peak_y = max(y_fit(t_fit>0)); % peaks after t = 0 sec
    end
    t_fits{i} = t_fit; 
    if rise_fit_order == 1 % monoexponential rise
        % y = A*exp(-t/taud1)        
        fit_eqn = 'a*(1 - exp(-x/b))';
        fit_fcn = @(a,x) a(1)*(1 - exp(-x*a(2)));
        upper_bounds = [1.1*peak_y,in.max_taur]; % replace first element in loop
        lower_bounds = [min(y_fit),in.min_taur];
        if in.fit_mode == 1
            start_points = [0.8*peak_y,0.1*in.max_taur];
        else
            start_points = [0.8*peak_y,1/(0.1*in.max_taur)];
        end
        print_str = 'Fitting rise to monoexponential function\n';
    elseif rise_fit_order == 2 % biexponential rise
        % y = A*(p * exp(-t/taud1) + (1-p) * exp(-t/taud2))
        fit_eqn = 'a*(1 - b*exp(-x/c) + (1-b)*exp(-x/d))';
        fit_fcn = @(a,x) a(1)*(1 - a(2)*exp(-x*a(3)) + (1-a(2))*exp(-x*a(4)));
        upper_bounds = [1.1*peak_y,1,in.max_taur,in.max_taur];
        lower_bounds = [min(y_fit),0,in.min_taur,in.min_taur];
        if in.fit_mode == 1
            start_points = [0.8*peak_y,0.8,0.1*in.max_taur,0.1*in.max_taur];
        else
            start_points = [0.8*peak_y,0.8,1/(0.1*in.max_taur),1/(0.1*in.max_taur)];
        end
        print_str = 'Fitting rise to biexponential function\n';
    else
        error('%g rise_fit_order not implemented',rise_fit_order);
    end
    if in.include_offset 
        fit_eqn = [fit_eqn, ' + e'];
        upper_bounds = [upper_bounds,peak_y];
        lower_bounds = [lower_bounds,min(y_fit)];
        start_points = [start_points,0];
    end
    if in.print_level > 1
        fprintf(print_str);
    end
    if in.fit_mode == 1
        s = fitoptions('Method','NonlinearLeastSquares',...
                'Lower',lower_bounds,...
                'Upper',upper_bounds,...
                'Startpoint',start_points);
        f = fittype(fit_eqn,'options',s);
        [fitobj,gof,~] = fit(t_fit,y_fit,f);    
        fitobjs{i} = fitobj;
        if gof.rsquare < 0.5
            if in.print_level > 0
                fprintf('Warning: R^2 of rise fit = %.3f for trace %g\n',...
                    gof.rsquare,i);
            end
        end
        gofs{i} = gof;
        rsquare(i) = gof.rsquare;
        A(i) = fitobj.a;
        if rise_fit_order == 1
            taur1(i) = fitobj.b;
        elseif rise_fit_order == 2
            if fitobj.c < fitobj.d
                taur1(i) = fitobj.c;
                taur2(i) = fitobj.d;
                p(i) = fitobj.b;
            else
                taur1(i) = fitobj.d;
                taur2(i) = fitobj.c;
                p(i) = 1 - fitobj.b;
            end
        end
    elseif in.fit_mode == 2
        mdl = fitnlm(t_fit,y_fit,fit_fcn,start_points);
        A(i) = mdl.Coefficients.Estimate(1); % parameter estimates
        if rise_fit_order == 1
            taur1(i) = 1/mdl.Coefficients.Estimate(2);
        elseif rise_fit_order == 2
            if 1/mdl.Coefficients.Estimate(3) < 1/mdl.Coefficients.Estimate(4)
                taur1(i) = 1/mdl.Coefficients.Estimate(3);
                taur2(i) = 1/mdl.Coefficients.Estimate(4);
                p(i) = mdl.Coefficients.Estimate(2);
            else
                taur1(i) = 1/mdl.Coefficients.Estimate(4);
                taur2(i) = 1/mdl.Coefficients.Estimate(3);
                p(i) = 1 - mdl.Coefficients.Estimate(2);
            end
        end
        gofs{i} = [];
        rsquare(i) = mdl.Rsquared.Adjusted;
        fitobjs{i} = mdl; 
    end
end
rise_fit = struct();    
rise_fit.A = A;
rise_fit.taur1 = taur1;
if rise_fit_order == 2
    rise_fit.taur2 = taur2;
    rise_fit.p = p;
end
rise_fit.rsquare = rsquare;
rise_fit.fitobjs = fitobjs;
rise_fit.gofs = gofs;
rise_fit.t_fits = t_fits; 
