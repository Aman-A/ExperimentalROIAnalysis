classdef ExperimentSettings < handle & matlab.mixin.Copyable % Stimulus, recording, and analysis settings for imaging
                  % experiment
    properties
        stim_vals {mustBeNumeric} % N stimuli x M trains array of stimulus times 
                                  % single train is 1 x N vector, stays in
                                  % same units as input
        stim_wind {mustBeNumeric} % time window to extract post-stimulus statistics, e.g. peak,
                                  %  generates NxM windows
        baseline_wind {mustBeNumeric} % time window to extract baseline, either
                                      % 1 window or N windows (for N stimuli)        
        sampling_rate {mustBeNumeric} % sampling rate in frames/sec
        stim_pulse_dur {mustBeNumeric} % Stimulus pulse duration/s, scalar 
                                       % for uniform duration, or array same
                                       % size as stim_vals with duration of
                                       % each stimulus                                        
        baseline_start_frame = 1; % start baseline from 1 frame before 
                                  % stimulus frames               
    end
    properties (Dependent)
        num_stim  % number of stimuli within train
        num_trains  % number of repeated stimulus trains within stim_vals,
                            % if stim_vals is 1D vector, considered 1 pulse
                            % train
                            % if stim_vals is 2D, each row of stim times is
                            % treated as a separate stim train in subsequent
                            % analysis                                       
    end
    properties (SetAccess = private)
        stim_wind_inds = []; % stimulus windows as either single column vector 
                       % (1 stimulus) or stim_wind x N stimuli x
                       % M trains array
        baseline_wind_inds = []; % baseline windows as either single column vector 
                           % (1 stimulus) or stim_wind x N stimuli x M
                           % trains array    
%         initial_units; % units of stim_vals when object was instantiated
        units  % string, current units of stim_wind, and baseline_wind, 
               % either 'frames' or 'sec'  
    end
    methods
        function obj = ExperimentSettings(stim_vals,stim_wind,baseline_wind,units,...
                                sampling_rate,varargin)
%             in.print_level = 0;        
              in.stim_pulse_dur = [];
              in = sl.in.processVarargin(in,varargin); 
            if nargin > 0
%                 obj.initial_units = units; 
                assert(any(strcmp(units,{'sec','frames'})),'ExperimentSettings units must be ''sec'' or ''frames''')
                obj.units = units;
                obj.sampling_rate = sampling_rate;                                
                obj.stim_wind = stim_wind;
                obj.baseline_wind = baseline_wind;                                                        
                obj.stim_pulse_dur = in.stim_pulse_dur; 
                obj.stim_vals = stim_vals; % set other properties first so get method can update stim_wind_inds/baseline_inds
                obj.convert2Frames()
            end                    
        end
        function varargout = convert2Frames(obj,varargin)     
            % Convert properties or input vector of time points to frame
            % numbers
            if nargin == 1
                if strcmp(obj.units,'sec')
                    obj.stim_vals = round(obj.stim_vals*obj.sampling_rate); % round to nearest frame
                    obj.stim_wind = round(obj.stim_wind*obj.sampling_rate);
                    obj.baseline_wind = round(obj.baseline_wind*obj.sampling_rate);
                    if ~isempty(obj.stim_pulse_dur)
                        obj.stim_pulse_dur = max(round(obj.stim_pulse_dur*obj.sampling_rate),1); % if <1 frame, set to 1
                    end
                    obj.units = 'frames';                    
                end            
            else
                varargout = {ceil(varargin{1}*obj.sampling_rate)};
            end
        end
        function varargout = convert2Time(obj,frames_val)
            % Converts contents of object to time units (sec) or converts 
            % given vector of frames to times if input as second argument
            if nargin == 1 % convert properties of object
                if strcmp(obj.units,'frames')
                   obj.stim_vals = obj.stim_vals/obj.sampling_rate; 
                   obj.stim_wind = obj.stim_wind/obj.sampling_rate; 
                   obj.baseline_wind = obj.baseline_wind/obj.sampling_rate;                
                   obj.stim_pulse_dur = obj.stim_pulse_dur/obj.sampling_rate; 
                   obj.units = 'sec';                   
                end           
            elseif nargin == 2 % just convert input value/s
                varargout = {frames_val/obj.sampling_rate}; 
            end
        end             
        function num_trains = get.num_trains(obj)
           num_trains = size(obj.stim_vals,1);                 
        end
        function num_stim = get.num_stim(obj)
           num_stim = size(obj.stim_vals,2); 
        end       
        function stim_wind_inds = get.stim_wind_inds(obj)
            [stim_wind_inds,~] = obj.getWindInds();
        end
        function baseline_wind_inds = get.baseline_wind_inds(obj)
            [~,baseline_wind_inds] = obj.getWindInds();
        end
        function t = getTimeVector(obj,num_frames)            
            x = (0:num_frames-1)';
            t = convert2Time(obj,x);            
%             if length(obj.stim_vals) == 1
%                 if strcmp(obj.units,'frames')
%                     stim_time = convert2Time(obj,obj.stim_vals);
%                 else
%                     stim_time = obj.stim_vals;  
%                 end
%                 t = t - stim_time;
%             end
        end
    end
    methods (Access = private)
        function [stim_wind_inds,baseline_wind_inds] = getWindInds(obj)
            obj.convert2Frames()
            % add window indices
            if isempty(obj.stim_vals) % no stim, use initial frames as
                % default baseline otherwise,
                % calculate on per event basis
                % externally
                stim_wind_inds = []; 
                baseline_wind_inds = (1:obj.baseline_wind)';
            else
                if obj.baseline_wind + obj.baseline_start_frame > obj.stim_vals(1)
                    fprintf(['Warning baseline_wind of %g exceeds pre-stimulus ',...
                        'recording time, setting to max possible %g frames\n'],...
                        obj.baseline_wind,obj.stim_vals(1) - obj.baseline_start_frame);
                    obj.baseline_wind = obj.stim_vals(1) - obj.baseline_start_frame ;
                end
                if numel(obj.stim_vals) > 1
                    stim_wind_inds = zeros(obj.stim_wind,obj.num_stim,... % [stim_wind x num_stim x num_trains]
                                              obj.num_trains);  
                    baseline_wind_inds = zeros(obj.baseline_wind,...
                                              obj.num_stim,obj.num_trains);
                    for i = 1:obj.num_trains
                        for j = 1:obj.num_stim
                            stim_wind_inds(:,j,i) = ...
                                (obj.stim_vals(i,j)+1):(obj.stim_vals(i,j) + obj.stim_wind);
                            baseline_wind_inds(:,j,i) = ...
                                (obj.stim_vals(i,j) - obj.baseline_wind - obj.baseline_start_frame + 1):(obj.stim_vals(i,j) - obj.baseline_start_frame);
                        end
                    end
                else
                    stim_wind_inds = ...
                        ((obj.stim_vals + 1):(obj.stim_vals + obj.stim_wind + 1))';
                    baseline_wind_inds = ...
                        ((obj.stim_vals - obj.baseline_wind - obj.baseline_start_frame + 1):(obj.stim_vals - obj.baseline_start_frame))';
                end
            end
        end
    end
    
end