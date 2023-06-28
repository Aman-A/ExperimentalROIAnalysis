function widths = getSpikeWidthsAll(traces,exp_settings,frac_amps,varargin)
%GETSPIKEWIDTHSALL Extracts width at multiple fractions of amplitude for set of traces 
%  
%   Inputs 
%   ------ 
%   traces : N x 1 or 1 x N cell array
%            Each element should have a single trace
%   exp_settings : N x 1 object array or single ExperimentSettings object
%   frac_amps : vector
%               Amplitudes at which widths will be computed, should be 
%               between 0 and 1
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.train_spike_width_mode = 1; % 1 - Cho 2020 method for nFWHM, use half 
                               % amp of 1st AP in train for rest of APs in train
in.fwhm_spline_interp = 0; % cubic spline interpolation for FWHM calculation
in = sl.in.processVarargin(in,varargin);
if length(exp_settings) == 1
    exp_settings = repmat(exp_settings,length(traces),1); % convert to object array
else
    if iscell(exp_settings) % cell array of ExperimentSettings objects
        % convert to object array
        exp_settings = [exp_settings{:}];
    end
end
fwhm_spline_interp = in.fwhm_spline_interp; 
train_spike_width_mode = in.train_spike_width_mode; 
num_trains = exp_settings(1).num_trains; % must be same for all
widths = zeros(length(traces),length(frac_amps),num_trains);
for i = 1:length(traces)
    exp_settings(i).convert2Frames(); % convert from time to frames units if necessary    
    baseline_wind = exp_settings(i).baseline_wind;      
    tracei = traces{i}; 
    t = exp_settings(i).getTimeVector(size(tracei,1));          
    if num_trains > 1 % get average FWHM of each spike within train (averaged across multiple trains)
        stim_indices = baseline_wind + 1 + exp_settings(i).stim_vals(1,:)-exp_settings(i).stim_vals(1);        
        for j = 1:length(frac_amps)
            widths(i,j,:) = spikeWidths(t,tracei,stim_indices,frac_amps(j),...
                                train_spike_width_mode,baseline_wind,...
                                'spline_interp',fwhm_spline_interp);
        end
    else % get average FWHM of all spikes averaged together (single train)
        stim_index = baseline_wind + 1;         
        for j = 1:length(frac_amps)
            widths(i,j) = spikeWidth(t,tracei,stim_index,frac_amps(j));
        end        
    end
end