function output = analyzeTraces(traces,exp_settings,varargin)
%ANALYZETRACES Analyze multiple trials of time-series data to extract peak,
%  integral, and decay time constants 
%  If contains multiple stimuli, generates matrix of aligned responses
%  within trial and mean across stimuli

%   Inputs 
%   ------ 
%   traces : N x num_traces array
%            Columns are time series with N time points, e.g., from separate trials/ROIs
%            or stim-aligned responses (see aligned below) with size N_wind x
%            num_traces x num_stim or N_wind x num_stim for single ROI
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
exp_settings.convert2Frames(); % convert from time to frames units if necessary
sampling_rate = exp_settings.sampling_rate; 
stim_frames = exp_settings.stim_vals; 
stim_wind_inds = exp_settings.stim_wind_inds; 
baseline_wind_inds = exp_settings.baseline_wind_inds;
num_stim = length(stim_frames); 
num_traces = size(traces,2); 
output = struct();
%% Analyze traces
if any(strcmp(in.funcs,'peaks'))
    if num_stim > 0
        peaks = zeros(num_stim,num_traces); % [num_stim x num_traces] peak amps 
        peak_times = zeros(num_stim,num_traces); % [num_stim x num_traces] peak times (relative to stimulus)
        pk_inds = zeros(num_stim,num_traces); 
        for i = 1:num_stim
            [peaks(i,:),pk_inds(i,:)] = max(traces(stim_wind_inds(i,:),:),[],1);
            peak_times(i,:) = exp_settings.convert2Time(stim_wind_inds(i,pk_inds(i,:)) - stim_frames(i));
        end
        output.peaks = peaks;
        output.mean_peak = mean(peaks,2:ndim(peaks)); % mean across trials (not stimuli)
        output.std_peak = std(peaks,0,2:ndim(peaks)); 
        output.sem_peak = output.std_peak/sqrt(length(peaks));
    else
        [peaks,pk_inds] = max(traces,[],1);
        peak_times = exp_settings.convert2Time(pk_inds); 
        output.peaks = peaks;
        output.mean_peak = mean(output.peaks,2); 
        output.std_peak = std(output.peaks,0,2:ndims(output.peaks));
        output.sem_peak = output.std_peak/sqrt(numel(output.peaks));
    end
end
if any(strcmp(in.funcs,'peak_times'))
    output.peak_times = peak_times; 
end
if any(strcmp(in.funcs,'poststim_ints'))
    poststim_ints = zeros(num_stim,num_traces); % [num_stim x num_traces] poststim integrals
    for i = 1:num_stim
        poststim_ints(i,:) = (1/sampling_rate)*trapz(traces(stim_wind_inds(i,:),:));
    end
    output.poststim_ints = poststim_ints; 
end
if any(strcmp(in.funcs,'decay_fit'))
    t = exp_settings.getTimeVector(size(traces,1))';    
    s = fitoptions('Method','NonlinearLeastSquares','Lower',[0,0,0,0],...
                   'Upper',[max(traces,[],'all'),1,t(end),t(end)],...
                   'Startpoint',[1,0.8,0.5,0.5]); % [amplitude, tau1 fraction, 
                                                  %  tau1 (sec), tau2
                                                  %  (sec)]
    % F = A*(p * exp(-t/taud1) + (1-p) * exp(-t/taud2)) 
    f = fittype('a*(b*exp(-x/c) + (1-b)*exp(-x/d))',...
                'options',s); 
    % Recover time constants from transient           
    decay_fit = struct();    
    decay_fit.taud1 = zeros(num_stim,num_traces); % sec - fast time constant
    decay_fit.taud2 = zeros(num_stim,num_traces); % sec
    decay_fit.p = zeros(num_stim,num_traces); % proportion of fast timeconstant
    decay_fit.A = zeros(num_stim,num_traces); % amplitude (a.u./%)
    decay_fit.rsquare = zeros(num_stim,num_traces); % amplitude (a.u./%)
    decay_fit.fitobjs = cell(num_stim,num_traces); 
    decay_fit.gofs = cell(num_stim,num_traces); 
    successful_spikes = zeros(num_stim,num_traces);            
    for n = 1:num_stim    
        t_stim = t(stim_wind_inds(n,:));
        traces_stim = traces(stim_wind_inds(n,:),:);       
        for i = 1:num_traces            
            t_fit = t_stim(pk_inds(n,i):end)-t_stim(pk_inds(n,i)); % start at peak (t=0)
                                                               % capture full post-stim window        
            trace_fit = traces_stim(pk_inds(n,i):end,i);
            trace_w_bsline = traces([baseline_wind_inds(n,:),...
                                     stim_wind_inds(n,:)],i); 
            successful_spikes(n,i) = spike_present(trace_w_bsline,...
                                            1:length(baseline_wind_inds(n,:)),...
                                            peaks(n,i),in.spike_thresh);
            include_trial = length(t_fit) > 4 && successful_spikes(n,i); 
            if include_trial
                [fitobj,gof,~] = fit(t_fit,trace_fit,f);
                decay_fit.fitobjs{n,i} = fitobj;
                if gof.rsquare < 0.5
                    fprintf('Warning: R^2 of decay fit = %.3f for stim %g, trace %g\n',gof.rsquare,n,i);
                end
                decay_fit.gofs{n,i} = gof; 
                decay_fit.rsquare(n,i) = gof.rsquare;
                decay_fit.A(n,i) = fitobj.a; 
                if fitobj.c < fitobj.d 
                    decay_fit.taud1(n,i) = fitobj.c; 
                    decay_fit.taud2(n,i) = fitobj.d;
                    decay_fit.p(n,i) = fitobj.b; 
                else
                    decay_fit.taud1(n,i) = fitobj.d; 
                    decay_fit.taud2(n,i) = fitobj.c;
                    decay_fit.p(n,i) = 1 - fitobj.b; 
                end        
            else
                decay_fit.A(n,i) = nan;
                decay_fit.taud1(n,i) = nan;
                decay_fit.taud2(n,i) = nan;
                decay_fit.p(n,i) = nan;
                if ~successful_spikes(n,i)
                    fprintf('No spike for stim %g, trace %g\n',n,i)
                end
            end
        end   
    end
    output.decay_fit = decay_fit;
    output.successful_spikes = successful_spikes;
    output.spike_thresh = in.spike_thresh;  
end
end
function spike = spike_present(trace,baseline_wind_inds,peak,thresh)
    std_baseline = std(trace(baseline_wind_inds));
    if peak > thresh*std_baseline
        spike = true;
    else
        spike  = false;
    end
end
