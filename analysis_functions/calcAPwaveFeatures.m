function APwave_feats = calcAPwaveFeatures(tAP,APwave,stim_index0,varargin)
% NOTE: tAP should be in seconds
in.spline_interp = 1;
in.spline_sampling_factor = 5;
in.frac_amps = 0.1:0.1:0.9;
in.AHP_mode = 1; % 0 - find AHP trough in each trace
                 % 1 - use AHP time point found in first trial for all                 
in.AHP_ind = []; % time point to use for AHP_mode = 1
in.AHP_max_wind = 0.03; % sec (30 ms)
in = sl.in.processVarargin(in,varargin);

if in.spline_interp
    [t,y] = splineInterp(tAP,APwave,in.spline_sampling_factor);
    stim_index = stim_index0*in.spline_sampling_factor - in.spline_sampling_factor;

else
    t = tAP;
    y = APwave;
    stim_index = stim_index0;
end
%% Widths at different fractions of amplitude
mean_widths = zeros(1,length(in.frac_amps)); % width in ms
for k = 1:length(in.frac_amps) % frac amp
    %             mean_widths(i,j,k) = 1e3*spikeWidth(tAP*1e-3,meanAPs{j}(:,i),stim_index,in.frac_amps(k),1);
    mean_widths(k) = 1e3*spikeWidth(t,y,stim_index,in.frac_amps(k),0); % convert to ms
end
%% Peak
AP_peak = 100*max(APwave(stim_index0:end)); % percent deltaF/F
%% AHP
sampling_rate = 1/mode(diff(tAP));
if in.AHP_mode == 0 || (in.AHP_mode == 1 && isempty(in.AHP_ind))
    [AHP_amp_val,AHP_ind] = AHP_amp(t,y,stim_index,0,[],'smooth_trace',1,...
                                'smooth_span',20*in.spline_sampling_factor,...
                                'max_ahp_wind',in.spline_sampling_factor*in.AHP_max_wind*sampling_rate); % 30 ms
elseif in.AHP_mode == 1
    [AHP_amp_val,~] = AHP_amp(t,y,stim_index,0,[],'smooth_trace',1,...
                        'smooth_span',20*in.spline_sampling_factor,...
                        'max_ahp_wind',in.spline_sampling_factor*in.AHP_max_wind*sampling_rate,...
                        'ahp_ind',in.AHP_ind); % 30 ms
    AHP_ind = in.AHP_ind;
end
AHP_amp_val = AHP_amp_val*100; % percent deltaF/F below baseline
if in.spline_interp
    AHP_ind0 = round((AHP_ind + in.spline_sampling_factor)/in.spline_sampling_factor);
end

APwave_feats = struct(); 
APwave_feats.mean_widths = mean_widths;
APwave_feats.AP_peak = AP_peak; 
APwave_feats.AHP_amp_val = AHP_amp_val; 
APwave_feats.AHP_ind0 = AHP_ind0;  % AHP_index in original recording
APwave_feats.AHP_ind = AHP_ind;  % AHP_index in spline interpolated recording