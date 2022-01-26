function output = analyzeTraces(traces,settings,varargin)
%ANALYZETRACES Analyze multiple trials of time-series data to extract peak,
%  integral, and decay time constants 
%  Note: Only analyzes response to first stimulus if more than one in each
%  trace

%   Inputs 
%   ------ 
%   traces : N x num_trials array
%            Columns are time series from separate trials/ROIs
%   settings: ExperimentSettings object

%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   output : struct
%           fields contain computed metrics on input traces
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.funcs = {'peaks','peak_times','poststim_ints','decay_fit'};
in.spike_thresh = 3; % peak must be over 3x std of baseline to be considered spike
in = sl.in.processVarargin(in,varargin);
settings.convert2Frames(); % convert from time to frames units if necessary
sampling_rate = settings.sampling_rate; 
stim_frames = settings.stim_vals; 
stim_wind_inds = settings.stim_wind_inds; 
output = struct();
if any(strcmp(in.funcs,'peaks'))
    [peaks,pk_inds] = max(traces(stim_wind_inds,:),[],1);
    peak_times = settings.convert2Time(stim_wind_inds(pk_inds) - stim_frames(1));
    output.peaks = peaks;
    output.mean_peak = mean(peaks);
    output.std_peak = std(peaks); 
    output.sem_peak = output.std_peak/sqrt(length(peaks));
end
if any(strcmp(in.funcs,'peak_times'))
    output.peak_times = peak_times; 
end
if any(strcmp(in.funcs,'poststim_ints'))
    poststim_ints = (1/sampling_rate)*trapz(traces(stim_wind_inds,:));
    output.poststim_ints = poststim_ints; 
end
if any(strcmp(in.funcs,'decay_fit'))
    t = settings.getTimeVector(size(traces,1))';     
    t_stim = t(stim_wind_inds);
    traces_stim = traces(stim_wind_inds,:);
    num_traces = size(traces,2);
    % Recover time constants from transient
    s = fitoptions('Method','NonlinearLeastSquares','Lower',[0,0,0,0],...
                   'Upper',[max(traces,[],'all'),1,t(end),t(end)],'Startpoint',[1,0.8,0.5,0.5]); 
    % F = A*(p * exp(-t/taud1) + (1-p) * exp(-t/taud2)) 
    f = fittype('a*(b*exp(-x/c) + (1-b)*exp(-x/d))',...
                'options',s);    
    decay_fit = struct();    
    decay_fit.taud1 = zeros(1,num_traces); % sec - fast time constant
    decay_fit.taud2 = zeros(1,num_traces); % sec
    decay_fit.p = zeros(1,num_traces); % proportion of fast timeconstant
    decay_fit.A = zeros(1,num_traces); % amplitude (a.u./%)
    decay_fit.rsquare = zeros(1,num_traces); % amplitude (a.u./%)
    decay_fit.fitobjs = cell(1,num_traces); 
    decay_fit.gofs = cell(1,num_traces); 
    successful_spikes = zeros(1,num_traces);
    for i = 1:num_traces
        t_fit = t_stim(pk_inds(i):end)-t_stim(pk_inds(i)); % start at peak (t=0)
                                                           % capture full post-stim window        
        tracei_fit = traces_stim(pk_inds(i):end,i);
        successful_spikes(i) = spike_present(traces(:,i),settings,peaks(i),in.spike_thresh);
        include_trial = length(t_fit) > 4 && successful_spikes(i); 
        if include_trial
            [fitobj,gof,~] = fit(t_fit,tracei_fit,f);
            decay_fit.fitobjs{i} = fitobj;
            if gof.rsquare < 0.5
                fprintf('Warning: R^2 of decay fit = %.3f, trial %g\n',gof.rsquare,i);
            end
            decay_fit.gofs{i} = gof; 
            decay_fit.rsquare(i) = gof.rsquare;
            decay_fit.A(i) = fitobj.a; 
            if fitobj.c < fitobj.d 
                decay_fit.taud1(i) = fitobj.c; 
                decay_fit.taud2(i) = fitobj.d;
                decay_fit.p(i) = fitobj.b; 
            else
                decay_fit.taud1(i) = fitobj.d; 
                decay_fit.taud2(i) = fitobj.c;
                decay_fit.p(i) = 1 - fitobj.b; 
            end        
        else
            decay_fit.A(i) = nan;
            decay_fit.taud1(i) = nan;
            decay_fit.taud2(i) = nan;
            decay_fit.p(i) = nan;
            if ~successful_spikes(i)
                fprintf('No spike in trace %g\n',i)
            end
        end
    end   
    output.decay_fit = decay_fit;
    output.successful_spikes = successful_spikes;
    output.spike_thresh = in.spike_thresh;  
end
end
function spike = spike_present(trace,settings,peak,thresh)
    std_baseline = std(trace(settings.baseline_wind_inds));
    if peak > thresh*std_baseline
        spike = true;
    else
        spike  = false;
    end
end
