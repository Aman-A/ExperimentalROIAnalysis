function output = analyzeStimAlignedTraces(traces,exp_settings,varargin)
%ANALYZESTIMALIGNEDTRACES Analyze multiple trials of time-series data to extract peak,
%  integral, and decay time constants 
%  If contains multiple stimuli, generates matrix of aligned responses
%  within trial and mean across stimuli

%   Inputs 
%   ------ 
%   traces : N x m x n x k array
%            Columns are time series with N time points, and m, n, and k are
%            additional trials/ROIs/stimuli aligned to single stim per
%            column (max allowable dimensions is 4 currently)
%   settings: ExperimentSettings object

%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   output : struct
%           fields contain computed metrics on input traces
%   Examples 
%   --------------- 
% TODO:
% Make decay fit compatible with ndimensional traces array where first column is
% always time. Could use recursive loop like matlab answer here: 
% https://stackoverflow.com/questions/14040260/how-to-iterate-over-n-dimensions
% AUTHOR    : Aman Aberra 
in.funcs = {'peaks','peak_times','poststim_ints','decay_fit'};
in.spike_thresh = 3; % peak must be over 3x std of baseline to be considered spike
in = sl.in.processVarargin(in,varargin);
exp_settings.convert2Frames(); % convert from time to frames units if necessary
sampling_rate = exp_settings.sampling_rate; 
baseline_wind = exp_settings.baseline_wind;
stim_frame = baseline_wind + 1; 
trace_dims = size(traces,1:4);
num_dims = ndims(traces);
output = struct();
%% Analyze traces
if any(strcmp(in.funcs,'peaks'))
    [peaks,pk_inds] = max(traces,[],1);    
    peaks = squeeze(peaks);
    pk_inds = squeeze(pk_inds);
    peak_times = exp_settings.convert2Time(pk_inds-stim_frame);
    output.peaks = peaks;
    % average all peaks
    output.mean_peak = mean(peaks,'all'); 
    output.std_peak = std(peaks,0,'all'); 
    % standard error treating last dimension as n
    output.sem_peak = output.std_peak/sqrt(numel(peaks)); 
end
if any(strcmp(in.funcs,'peak_times'))
    output.peak_times = peak_times; 
end
if any(strcmp(in.funcs,'poststim_ints'))
    % integrate in time, allow up to 4D traces
    poststim_ints = (1/sampling_rate)*trapz(traces(stim_frame:end,:,:,:),1);    
    output.poststim_ints = squeeze(poststim_ints); 
end
if any(strcmp(in.funcs,'decay_fit'))
    t = exp_settings.getTimeVector(size(traces,1));           
    % Recover time constants from transient                  
    taud1 = zeros(trace_dims(2:end)); % sec - fast time constant
    taud2 = zeros(trace_dims(2:end)); % sec
    p = zeros(trace_dims(2:end)); % proportion of fast timeconstant
    A = zeros(trace_dims(2:end)); % amplitude (a.u./%)
    rsquare = zeros(trace_dims(2:end)); % amplitude (a.u./%)
    fitobjs = cell(trace_dims(2:end)); 
    gofs = cell(trace_dims(2:end)); 
    successful_spikes = zeros(trace_dims(2:end));      
    n_traces = prod(trace_dims(2:end));    
    [i_vec,j_vec,k_vec] = ind2sub(trace_dims(2:end),1:n_traces);  
    spike_thresh = in.spike_thresh;         
    for n = 1:n_traces        
%         i = i_vec(n); j = j_vec(n); k = k_vec(n);        
        t_fit = t(pk_inds(n):end) - t(pk_inds(n)); % start at peak (t=0)
        trace_n = traces(:,n);
        trace_fit = trace_n(pk_inds(n):end);
        trace_w_bsline = traces(:,n); % include bsline for spike detection
        successful_spike = spike_present(trace_w_bsline,...
                                                baseline_wind,...
                                                peaks(n),spike_thresh);
        successful_spikes(n) = successful_spike;
        % only include trial if more than 4 frames and includes spike
        include_trial = length(t_fit) > 4 && successful_spike; 
        if include_trial
            s = fitoptions('Method','NonlinearLeastSquares',...
                           'Lower',[0,0,0,0],...
                           'Upper',[abs(max(trace_fit)),1,t(end),t(end)],...
                           'Startpoint',[1,0.8,0.5,0.5]); % [amplitude, tau1 fraction, 
                                                          %  tau1 (sec), tau2
                                                          %  (sec)]
            % F = A*(p * exp(-t/taud1) + (1-p) * exp(-t/taud2)) 
            f = fittype('a*(b*exp(-x/c) + (1-b)*exp(-x/d))',...
                        'options',s); 
            [fitobj,gof,~] = fit(t_fit,trace_fit,f);
            fitobjs{n} = fitobj;
            if gof.rsquare < 0.5
                fprintf('Warning: R^2 of decay fit = %.3f for trace (%g, %g, %g)\n',...
                        gof.rsquare,i_vec(n),j_vec(n),k_vec(n));
            end
            gofs{n} = gof;
            rsquare(n) = gof.rsquare;
            A(n) = fitobj.a;
            if fitobj.c < fitobj.d
                taud1(n) = fitobj.c;
                taud2(n) = fitobj.d;
                p(n) = fitobj.b;
            else
                taud1(n) = fitobj.d;
                taud2(n) = fitobj.c;
                p(n) = 1 - fitobj.b;
            end
        else
            A(n) = nan;
            taud1(n) = nan;
            taud2(n) = nan;
            p(n) = nan;
            if ~successful_spikes(n)
                fprintf('No spike for trace (%g, %g, %g)\n',i_vec(n),j_vec(n),k_vec(n))
            end
        end             
    end        
    % compile into struct
    decay_fit = struct();    
    decay_fit.taud1 = taud1; 
    decay_fit.taud2 = taud2;
    decay_fit.p = p; 
    decay_fit.A = A;
    decay_fit.rsquare = rsquare;
    decay_fit.fitobjs = fitobjs;
    decay_fit.gofs = gofs;
    % add to output
    output.decay_fit = decay_fit;
    output.successful_spikes = successful_spikes;
    output.spike_thresh = in.spike_thresh;  
end
end
function spike = spike_present(trace,baseline_wind,peak,thresh)
    std_baseline = std(trace(1:baseline_wind));
    if peak > thresh*std_baseline
        spike = true;
    else
        spike  = false;
    end
end
