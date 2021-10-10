classdef ExperimentSettings < handle % Stimulus, recording, and analysis settings for imaging
                  % experiment
    properties
        stim_vals {mustBeNumeric} % vector of stimulus times
        stim_wind {mustBeNumeric} % time window to extract stimulus statistics, e.g. peak,
                                  %  either 1 window or N windows (for N
                                  %  windows after each stimulus)
        baseline_wind {mustBeNumeric} % time window to extract baseline, either
                                      % 1 window or N windows (for N stimuli)
        units char {mustBeTextScalar} % string, units of input stim_vals, 
                                      % stim_wind, and baseline_wind, 
                                      % either 'frames' or 'sec'
        sampling_rate {mustBeNumeric} % sampling rate in frames/sec
        stim_wind_inds = []; % stimulus windows as either single row vector 
                       % (1 stimulus) or N x stim_wind matrix (N stimuli)
        baseline_wind_inds = [];% baseline windows as either single row vector 
                           % (1 stimulus) or N x stim_wind matrix (N stimuli)
        baseline_start_frame = 1; % start baseline from 1 frame before 
                                  % stimulus frames
    end
    methods
        function obj = ExperimentSettings(stim_vals,stim_wind,baseline_wind,units,...
                                sampling_rate,varargin)
            in.print_level = 0;                 
            in = sl.in.processVarargin(in,varargin); 
            if nargin > 0
                obj.stim_vals = stim_vals;
                obj.stim_wind = stim_wind;
                obj.baseline_wind = baseline_wind;
                obj.units = units;
                obj.sampling_rate = sampling_rate;                        
            end            
            convert2Frames(obj,in.print_level);  
            getWindInds(obj);
        end
        function convert2Frames(obj,varargin)
            if length(varargin) == 1
                print_level = varargin{1};
            else
                print_level = 1;
            end
            if strcmp(obj.units,'sec')
                obj.stim_vals = ceil(obj.stim_vals*obj.sampling_rate); % round up to next frame
                obj.stim_wind = ceil(obj.stim_wind*obj.sampling_rate);
                obj.baseline_wind = ceil(obj.baseline_wind*obj.sampling_rate);
                obj.units = 'frames';
                if print_level > 0
                    fprintf('Converted ExperimentSettings to frames\n');
                end
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
                   obj.units = 'sec';                   
                end           
            elseif nargin == 2 % just convert input value/s
                varargout = {frames_val/obj.sampling_rate}; 
            end
        end
        function getWindInds(obj)
            if obj.baseline_wind + obj.baseline_start_frame >= obj.stim_vals(1)
               fprintf(['Warning baseline_wind of %g exceeds pre-stimulus ',...
                       'recording time, setting to max possible %g frames\n'],...
                       obj.baseline_wind,obj.stim_vals(1) - obj.baseline_start_frame); 
               obj.baseline_wind = obj.stim_vals(1) - obj.baseline_start_frame ;                
            end
            % add window indices
            if length(obj.stim_vals) > 1
                obj.stim_wind_inds = zeros(length(obj.stim_vals),obj.stim_wind+1);
                obj.baseline_wind_inds = zeros(length(obj.baseline_wind_inds),obj.baseline_wind+1);
                for i = 1:length(obj.stim_vals)
                    obj.stim_wind_inds(i,:) = (obj.stim_vals(i)+1):(obj.stim_vals(i) + obj.stim_wind + 1);
                    obj.baseline_wind_inds(i,:) = ...
                     (obj.stim_vals(i) - obj.baseline_wind - obj.baseline_start_frame + 1):(obj.stim_vals(i) - obj.baseline_start_frame);
                end
            else
                obj.stim_wind_inds = (obj.stim_vals + 1):(obj.stim_vals + obj.stim_wind + 1);
                obj.baseline_wind_inds = ...
                 (obj.stim_vals - obj.baseline_wind - obj.baseline_start_frame + 1):(obj.stim_vals - obj.baseline_start_frame);
            end
        end
    end
    
end