function exp_settings = WaveSurferStim2ExpSettings(ws_stim_or_file,im_sampling_rate,...
                                                   stim_wind,baseline_wind,varargin)
% WAVESURFERSTIM2EXPSETTINGS
% Use wavesurfer stimulus structure from saved experiment data to generate
% ExperimentSettings object for imaging trial, including stimulus
% amplitudes
% exp_settings = WaveSurferStim2ExpSettings(ws_stim_or_file,im_sampling_rate,...
%                                         stim_wind,baseline_wind,varargin)
%  Inputs 
%  ------ 
%  Optional Inputs 
%  --------------- 
%  Outputs 
%  ------- 
%  Examples 
%  ---------------
in.units = 'sec'; % units for stim_wind and baseline_wind
in.E_per_mA = []; % set based on measured E-field scaling
in = sl.in.processVarargin(in,varargin);

if ischar(ws_stim_or_file) % input file path
    stim = getWaveSurferStimStruct(ws_stim_or_file);
else % input struct directly
    stim = ws_stim_or_file;
end

switch stim.TypeString
    case 'SquarePulseLadder'
        del = str2double(stim.Delay); 
    amp1 = str2double(stim.FirstPulseAmplitude);
    amp_step = str2double(stim.AmplitudeChangePerPulse);
    num_stim = str2double(stim.PulseCount); 
    amps = amp1:amp_step:(amp1+amp_step*(num_stim-1));
    stim_pulse_dur = str2double(stim.PulseDuration);
    freq = 1/str2double(stim.DelayBetweenPulses); % Hz
    dur = num_stim/freq; 
    stim_vals = defineStimTrain(del,freq,dur);     
    exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                      in.units,im_sampling_rate,...
                                      'stim_pulse_dur',stim_pulse_dur,...
                                      'stim_amps',amps,'E_per_mA',in.E_per_mA); % automatically converts to frames
    case 'SquarePulse'
        % Not implemented yet
end