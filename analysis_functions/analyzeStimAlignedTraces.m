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
%           Standard dimensions:
%           m - num_rois
%           n - num_stimuli
%           k - num_trials
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
in.funcs = {'peaks','peak_times','poststim_ints','decay_fit','fwhm','mean_fwhm'};
in.decay_fit_order = 1;
in.spike_thresh = 3; % peak must be over 3x std of baseline to be considered spike
in.spike_window = 0.1; % sec - peak must be within this time of stim to be considered spike
in.train_peak_baseline_mode = 1; % for num_trains > 1:
                                  % 1 - use same baseline for full train
                                  % 2 - get individual baseline for each
                                  % stim (assume deltaF_F0_aligned2 input)
in.train_spike_width_mode = 1; % 1 - Cho 2020 method for nFWHM, use half 
                               % amp of 1st AP in train for rest of APs in train
in.frac_amp = 0.5; 
in.fwhm_spline_interp = 0; % cubic spline interpolation for FWHM calculation
in.save_analysis = 1;
in.save_dir = './'; % default save in current directory
in.save_filename = sprintf('analysis_trials_dims_%g_%g_%g_%g.mat',size(traces,[1,2,3,4]));
in.load = 1; 
in = sl.in.processVarargin(in,varargin);
exp_settings.convert2Frames(); % convert from time to frames units if necessary
sampling_rate = exp_settings.sampling_rate; 
baseline_wind = exp_settings.baseline_wind;
stim_frame = baseline_wind + 1; 
stim_wind = exp_settings.stim_wind;
spike_window = exp_settings.convert2Frames(in.spike_window);
if spike_window > stim_wind
   spike_window = stim_wind; 
end
trace_dims = size(traces,1:5);
num_stim = exp_settings.num_stim; % num stim within train
num_trains = exp_settings.num_trains;
if num_trains > 1 
    % make sure spike window is shorter than interspike interval within train
    min_isi = min(diff(exp_settings.stim_vals(1,:)));
    if spike_window > min_isi
        spike_window = min_isi; 
    end
end
analysis_file = fullfile(in.save_dir,in.save_filename);
if in.load
    % check if exists    
    if exist(analysis_file,'file')
        output = load(analysis_file);
        fprintf('Loaded analysis data from %s\n',analysis_file);
        return;     
    else
        fprintf('No analysis file to load, running analysis...\n')
    end
end
fwhm_spline_interp = in.fwhm_spline_interp; % avoid broadcasting below
output = struct();
if isempty(in.funcs); return; end
%% Analyze traces
% Calculate post-stimulus peaks
if any(strcmp(in.funcs,'peaks'))
    % get peaks within spike_window 
    if num_trains > 1 && in.train_peak_baseline_mode == 1       
        % [num_rois x num_trains x num_stim x num_trials]
        peaks = zeros([trace_dims(2),num_trains,num_stim,trace_dims(4)]);
        pk_inds = zeros([trace_dims(2),num_trains,num_stim,trace_dims(4)]);
        isi_stims = diff(exp_settings.stim_vals(1,:)); % assume identical ISIs between trains
        for i = 1:num_stim
            if i > 1
%                 stim_framei = stim_frame + cumsum(diff(exp_settings.stim_vals(1,1:i)))*(i-1);                                
                stim_framei = stim_frame + sum(isi_stims(1:(i-1))); % handle non-uniform ISI 
                                                                    % by summing stim intervals 
                                                                    % up to this stim to get frame within train                                                                    
            else
                stim_framei = stim_frame; 
            end
            [peaks(:,:,i,:),pk_inds(:,:,i,:)] =  max(traces((stim_framei+1):(stim_framei+spike_window),:,:,:),[],1);   
            pk_inds(:,:,i,:) = pk_inds(:,:,i,:) + stim_framei;  % reference to full time vector 
        end
        peaks = squeeze(peaks); 
        pk_inds = squeeze(pk_inds);
        peak_times = exp_settings.convert2Time(pk_inds-stim_frame); % referenced to first stim in train
        
    else
        [peaks,pk_inds] = max(traces((stim_frame+1):(stim_frame+spike_window),:,:,:,:),[],1);    
        pk_inds = pk_inds + stim_frame; % reference to full time vector
        peaks = squeeze(peaks);
        pk_inds = squeeze(pk_inds);
        peak_times = exp_settings.convert2Time(pk_inds-stim_frame);
    end    
    output.peaks = peaks;
    % average all peaks
    output.mean_peak = mean(peaks,'all'); 
    output.std_peak = std(peaks,0,'all'); 
    % standard error treating last dimension as n
    output.sem_peak = output.std_peak/sqrt(numel(peaks)); 
end
%% Calculate post-stim peak times
if any(strcmp(in.funcs,'peak_times'))
    if ~any(strcmp(in.funcs,'peaks'))
        [peaks,pk_inds] = max(traces((stim_frame+1):(stim_frame+spike_window),:,:,:,:),[],1);    
        pk_inds = pk_inds + stim_frame; % reference to full time vector    
        pk_inds = squeeze(pk_inds);    
        peak_times = exp_settings.convert2Time(pk_inds-stim_frame);
    end
    output.peak_times = peak_times; 
end
%% Calculate post-stim integral
if any(strcmp(in.funcs,'poststim_ints'))
    % integrate in time, allow up to 4D traces
    poststim_ints = (1/sampling_rate)*trapz(traces(stim_frame:end,:,:,:,:),1);    
    output.poststim_ints = squeeze(poststim_ints); 
end
%% Fit post-stim decay to mono or bi-exponential function
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
    decay_fit_order = in.decay_fit_order;
    if length(exp_settings.stim_vals) > 1
        ISI = exp_settings.convert2Time(max(diff(exp_settings.stim_vals(:)))); % max inter-spike interval in sec
    else
        ISI = (t(end) - t(baseline_wind+1))*2; % recording time post stim
    end
    if decay_fit_order == 1 % monoexponential decay
        % F = A*exp(-t/taud1)
        fit_eqn = 'a*exp(-x/b)';
        upper_bounds = [nan,ISI]; % replace first element in loop
        lower_bounds = [0,0];
        start_points = [1,0.5];
        fprintf('Fitting decay to monoexponential function\n')
    elseif decay_fit_order == 2 % biexponential decay
        % F = A*(p * exp(-t/taud1) + (1-p) * exp(-t/taud2)) 
        fit_eqn = 'a*(b*exp(-x/c) + (1-b)*exp(-x/d))';
        upper_bounds = [nan,1,ISI,ISI];
        lower_bounds = [0,0,0,0];
        start_points = [1,0.8,0.5,0.5];
        fprintf('Fitting decay to biexponential function\n')
    else
        error('%g decay_fit_order not implemented',decay_fit_order);
    end
    parfor n = 1:n_traces        
%         i = i_vec(n); j = j_vec(n); k = k_vec(n);        
        t_fit = t(pk_inds(n):end) - t(pk_inds(n)); % start at peak (t=0)
        trace_w_bsline = traces(:,n); % include bsline for spike detection
        trace_fit = trace_w_bsline(pk_inds(n):end);        
%         successful_spike = spikePresent(trace_w_bsline,baseline_wind,...
%                                          spike_thresh,peaks(n)); 
        successful_spike = spikePresentInWindow(trace_w_bsline,baseline_wind,...
                                         spike_thresh,spike_window,peaks(n)); % uses peaks computed within spike_window
        successful_spikes(n) = successful_spike;
        % only include trial if more than 4 frames and includes spike
        include_trial = length(t_fit) > 4 && successful_spike; 
        if include_trial
            upper_boundsn = upper_bounds;
            upper_boundsn(1) = abs(max(trace_fit));
            s = fitoptions('Method','NonlinearLeastSquares',...
                           'Lower',lower_bounds,...
                           'Upper',upper_boundsn,...
                           'Startpoint',start_points); % [amplitude, tau1 fraction, 
                                                          %  tau1 (sec), tau2
                                                          %  (sec)]
            
            f = fittype(fit_eqn,'options',s); 
            [fitobj,gof,~] = fit(t_fit,trace_fit,f);
            fitobjs{n} = fitobj;
            if gof.rsquare < 0.5
%                 fprintf('Warning: R^2 of decay fit = %.3f for trace (%g, %g, %g)\n',...
%                         gof.rsquare,i_vec(n),j_vec(n),k_vec(n));
            end
            gofs{n} = gof;
            rsquare(n) = gof.rsquare;
            A(n) = fitobj.a;
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
        else
            A(n) = nan;
            taud1(n) = nan;
            taud2(n) = nan;
            p(n) = nan;
            if ~successful_spikes(n)
%                 fprintf('No spike for trace (%g, %g, %g)\n',i_vec(n),j_vec(n),k_vec(n))
            end
        end             
    end        
    % compile into struct
    decay_fit = struct();    
    decay_fit.A = A;
    decay_fit.taud1 = taud1;         
    if in.decay_fit_order == 2
        decay_fit.taud2 = taud2;
        decay_fit.p = p; 
    end
    decay_fit.rsquare = rsquare;
    decay_fit.fitobjs = fitobjs;
    decay_fit.gofs = gofs;
    % add to output
    output.decay_fit = decay_fit;
    output.successful_spikes = successful_spikes;
    output.spike_thresh = in.spike_thresh;  
    output.spike_window = spike_window;
    Pr = sum(successful_spikes,2)./size(successful_spikes,2);    
    fprintf('Mean Pr = %.3f +/- %.3f (WARNING: may be inaccurate)\n',mean(Pr,[1 3]),std(Pr,0,[1 3]));
end
%% FWHM of individual responses
if any(strcmp(in.funcs,'fwhm')) % full width half max of all traces   
    n_traces = prod(trace_dims(2:end));    
    t = exp_settings.getTimeVector(size(traces,1));          
    frac_amp = in.frac_amp;
    tic
    if num_trains > 1
        % first frame after each stim within train
        stim_indices = baseline_wind + 1 + exp_settings.stim_vals(1,:)-exp_settings.stim_vals(1);
        fwhm = zeros([trace_dims(2),num_trains,num_stim]); % [num_rois x num_trains x num_stim]
        for n = 1:n_traces
            try
                [i,j] = ind2sub(trace_dims(2:end),n);
                fwhm(i,j,:) = spikeWidths(t,traces(:,n),stim_indices,frac_amp,...
                                        in.train_spike_width_mode,baseline_wind,...
                                        'spline_interp',fwhm_spline_interp);                              
            catch
                fwhm(n) = nan;
            end
        end  
        fwhm = squeeze(fwhm);
    else
        stim_index = baseline_wind + 1;     
        fwhm = zeros(trace_dims(2:end));    
        parfor n = 1:n_traces
            try
                fwhm(n) = spikeWidth(t,traces(:,n),stim_index,frac_amp);
            catch
                fwhm(n) = nan;
            end
        end       
    end    
    elapsed_time = toc;
    fprintf('Computed FWHM of %g traces in %.4f sec\n',n_traces,elapsed_time)
    if any(isnan(fwhm))
        fprintf('%g of %g errors\n',sum(isnan(fwhm),'all'),numel(fwhm));
    end
    output.fwhm = fwhm; 
end
%% FWHM of averaged responses
if any(strcmp(in.funcs,'mean_fwhm')) % Mean FWHM of stim and trial-averaged APs
    % Stim and trial averaged traces
    mean_traces = mean(traces,[3 4]); % Average across stim within trial and across trials/trains    
%     if trace_dims(3) == 1 % single ROI
%         mean_traces = squeeze(mean(traces,2)); 
%     else % multiple ROIs
%         mean_traces = squeeze(mean(traces,3)); 
%     end
    mean_trace_dims = size(mean_traces,1:2);
    t = exp_settings.getTimeVector(size(traces,1));          
    frac_amp = in.frac_amp;
    n_traces = prod(mean_trace_dims(2:end));
    tic
    if num_trains > 1 % get average FWHM of each spike within train (averaged across multiple trains)
        stim_indices = baseline_wind + 1 + exp_settings.stim_vals(1,:)-exp_settings.stim_vals(1);
        mean_fwhm = zeros([mean_trace_dims(2:end),num_stim]); % [num_rois x num_stim] average across trains/trials
        for n = 1:n_traces
            mean_fwhm(n,:) = spikeWidths(t,mean_traces(:,n),stim_indices,frac_amp,...
                                        in.train_spike_width_mode,baseline_wind,...
                                        'spline_interp',fwhm_spline_interp);
        end        
    else % get average FWHM of all spikes averaged together (single train)
        stim_index = exp_settings.baseline_wind + 1; 
        mean_fwhm = zeros(mean_trace_dims(2),1);
        for n = 1:n_traces
            mean_fwhm(n) = spikeWidth(t,mean_traces(:,n),stim_index,frac_amp);
        end
    end
    elapsed_time = toc;
    fprintf('Computed FWHM of %g stim-averaged traces in %.4f sec\n',...
            n_traces,elapsed_time)
    if any(isnan(mean_fwhm))
        fprintf('%g of %g errors\n',sum(isnan(mean_fwhm),'all'),numel(mean_fwhm));
    end
    output.mean_fwhm = mean_fwhm; 
    output.train_spike_width_mode = in.train_spike_width_mode;
    output.fwhm_spline_interp = in.fwhm_spline_interp; 
end
if in.save_analysis
    save(analysis_file,'-STRUCT','output')
    fprintf('Saved analysis data to %s\n',analysis_file);
end
end

