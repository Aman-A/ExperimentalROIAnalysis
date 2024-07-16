classdef EfieldAnalysisClass < ws.UserClass
    % NOTE: Need ExperimentalROIAnalysis to be added to path   
    properties
        Greeting = 'Hello, there!'
        classname_ = 'EfieldAnalysisClass';
        TimeAtStartOfLastRunAsString_ = ''  
          % TimeAtStartOfLastRunAsString_ should only be accessed from 
          % the methods below, but making it protected is a pain.         
         amplifier_gain = 13; % gain on instrumentation amplifier
%          iel_mm = 0.61; % interelectrode length (recording elecrodes) in mm - Pt bipolar 
        iel_mm = 4.3;  % interelectrode length (recording elecrodes) in mm  - Ag probe  
%          iel_mm = 5.1; % interelectrode length (recording elecrodes) in mm - Pt probe    
         isolator_mA_per_V = 10; % mA out per V input for isolator in arbitrary analog isolation mode
         ss_wind_frac = 0.5; % fraction of pulse to start calculation of steady state 
                             % value, e.g. 0.5 is last half of stimulus pulse, 0
                             % is full pulse duration

    end
    
     % Properties that a) You don't want to be persisted in the protocol file,
    % and b) you don't need access to outside the methods.
    properties (Transient=true, Access=protected)
%         run_data = [];  
        ss_Es = []; 
        amps_mA = [];
        regress_Rsq = [];
        regress_p = []; 
        ss_E_slope = []; 
        ss_E_int = [];         
        ta_sweep = []; 
        V_aligned_bs_sweep = []; 
        E_fig_
        % TODO: Use uifigure to make numeric fields to edit IEL, amplitude
        % gain, and stimulus isolator amps/V to set in GUI
%         iel_edit_field_
%         amp_gain_field_
%         isolator_amps_per_V_field_
    end

    methods        
        function self = EfieldAnalysisClass()
            % creates the "user object"
            fprintf('%s  Instantiating an instance of %s.\n', ...
                    self.Greeting,self.classname_);
        end
        
        function wake(self, rootModel)  %#ok<INUSD>
            % creates the "user object"
            fprintf('%s  Waking an instance of %s.\n', ...
                    self.Greeting,self.classname_);
            self.E_fig_ = figure('Units','normalized','Position',[0.1 0.6 0.55 0.3]);
%             self.E_fig_ = uifigure('Units','normalized','Position',[0.1 0.6 0.55 0.3]);
%             setTextFields(self)
            plotE(self,[]); 
        end
        
        function delete(self)
            % Called when there are no more references to the object, just
            % prior to its memory being freed.
            fprintf('%s  An instance of %s is being deleted.\n', ...
                    self.Greeting,self.classname_);
            delete(self.E_fig_);
        end
        
        function setTextFields(self)
            xpos = 1300;
            self.iel_edit_field_ = uieditfield(self.E_fig_,'numeric',...
                                               'Position',[xpos,200,100,22],...
                                               'ValueDisplayFormat','%.2f mm',...
                                               'Limits',[0,20],'LowerLimitInclusive','off',...
                                               'Value',self.iel_mm);
            self.amp_gain_field_ = uieditfield(self.E_fig_,'numeric',...
                                               'Position',[xpos,150,100,22],...
                                               'ValueDisplayFormat','%.1fx',...
                                               'Limits',[1,101],'LowerLimitInclusive','on',...
                                               'Value',self.amplifier_gain);
            self.isolator_amps_per_V_field_ = uieditfield(self.E_fig_,'numeric',...
                                               'Position',[xpos,100,100,22],...
                                               'ValueDisplayFormat','%.2f mm',...
                                               'Limits',[0,20],'LowerLimitInclusive','off',...
                                               'Value',self.isolator_mA_per_V);            
        end
        function willSaveToProtocolFile(self, wsModel)  %#ok<INUSD>
            fprintf('%s  Saving to protocol file in %s.\n', ...
                    self.Greeting,self.classname_);
        end        
        
        % These methods are called in the frontend process
        function startingRun(self, wsModel)  %#ok<INUSD>
            % Called just before each set of sweeps (a.k.a. each
            % "run")
            self.TimeAtStartOfLastRunAsString_ = datestr( clock() ) ;
%             fprintf('%s  About to start a run.  Current time: %s\n', ...
%                     self.Greeting,self.TimeAtStartOfLastRunAsString_);
%             self.run_data = zeros(wsModel.ExpectedSweepScanCount,wsModel.NSweepsPerRun);
            self.ss_Es = [];
            self.amps_mA = [];            
            self.ss_E_slope = []; 
            self.ss_E_int = []; 
            self.regress_Rsq = [];
            self.regress_p = []; 
        end
        
        function completingRun(self, wsModel)  %#ok<INUSD>
            % Called just after each set of sweeps (a.k.a. each
            % "run")
%             fprintf('%s  Completed a run.  Time at start of run: %s\n', ...
%                     self.Greeting,self.TimeAtStartOfLastRunAsString_);
            
%             if length(unique(self.amps_mA)) > 2
%                 regressEs(self,wsModel)                 
%             end
        end
        
        function stoppingRun(self, wsModel)  %#ok<INUSD>
            % Called if a sweep is manually stopped
            if length(unique(self.amps_mA)) > 2
                regressEs(self,wsModel);
                plotE(self,wsModel)
            end
%             fprintf('%s  User stopped a run.  Time at start of run: %s\n', ...
%                     self.Greeting,self.TimeAtStartOfLastRunAsString_);
        end            

        function abortingRun(self, wsModel)  %#ok<INUSD>
            % Called if a run goes wrong, after the call to
            % abortingSweep()
%             fprintf('%s  Oh noes!  A run aborted.  Time at start of run: %s\n', ...
%                     self.Greeting,self.TimeAtStartOfLastRunAsString_);
        end
        
        function startingSweep(self, wsModel)  %#ok<INUSD>
            % Called just before each sweep
%             fprintf('%s  About to start a sweep.  Time at start of run: %s\n', ...
%                     self.Greeting,self.TimeAtStartOfLastRunAsString_);
        end
        
        function completingSweep(self, wsModel)  %#ok<INUSD>
            % Called after each sweep completes
%             fprintf('%s  Completed a sweep.  Time at start of run: %s\n', ...
%                     self.Greeting,self.TimeAtStartOfLastRunAsString_);
            sweep_data = wsModel.getAIDataFromCache(); 
            [ss_E,amp_mA,ta,V_aligned_bs] = self.calcEsweep(wsModel,sweep_data);
%             self.run_data(:,wsModel.NSweepsCompletedInThisRun) = sweep_data;   
            self.ss_Es = [self.ss_Es;ss_E];
            self.amps_mA = [self.amps_mA;amp_mA];
            self.ta_sweep = ta; 
            self.V_aligned_bs_sweep = V_aligned_bs;             
            % Update E plot
%             if wsModel.NSweepsPerRun == inf
            if length(unique(self.amps_mA)) > 2
                regressEs(self,wsModel); % update regression values
            end
            plotE(self,wsModel); 
        end
        
        function stoppingSweep(self, wsModel)  %#ok<INUSD>
            % Called if a sweep goes wrong
            fprintf('%s  User stopped a sweep.  Time at start of run: %s\n', ...
                    self.Greeting,self.TimeAtStartOfLastRunAsString_);
        end        
        
        function abortingSweep(self, wsModel)  %#ok<INUSD>
            % Called if a sweep goes wrong
            fprintf('%s  Oh noes!  A sweep aborted.  Time at start of run: %s\n', ...
                    self.Greeting,self.TimeAtStartOfLastRunAsString_);
        end        
        
        function [ss_E,amp_mA,ta,V_aligned_bs] = calcEsweep(self, wsModel,V0) 
            tic
            V = V0/self.amplifier_gain; % actual voltage            
            sweep_ind = wsModel.NSweepsCompletedInThisRun; 
%             stim_ind = wsModel.indexOfStimulusLibraryClassSelection('ws.Stimulus');   
            stim_inds = wsModel.stimulusLibrarySelectedOutputableProperty('IndexOfEachStimulusInLibrary'); 
            chan_ind = strcmp(wsModel.stimulusLibrarySelectedOutputableProperty('ChannelName'),'AO0');
            stim_ind = stim_inds{chan_ind};
%             stim_ind =
%             wsModel.selectedStimulusLibraryItemIndexWithinClass(); % bug
%             -> can give selected stim in GUI, not stim used in sweep
            stim_type = wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'TypeString');
            % Common properties
            del = str2double(wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'Delay'));
            amp = eval(sprintf('arrayfun(@(i) %s,%g)',wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'Amplitude'),sweep_ind));
            amp_mA = amp*self.isolator_mA_per_V; % stimululs amp in mA
            end_time = wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'EndTime');
            if strcmp(stim_type,'SquarePulse')
                pulse_dur = str2double(wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'Duration'));
                stim_vals = del; 
                exp_settings = ExperimentSettings(stim_vals,min(end_time,pulse_dur*2),min(del,pulse_dur/2),'sec',wsModel.AcquisitionSampleRate,...
                                               'stim_pulse_dur',pulse_dur);
            elseif strcmp(stim_type,'SquarePulseTrain')
                pulse_dur = str2double(wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'PulseDuration'));
                dur = str2double(wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'Duration'));
                freq = 1/str2double(wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'Period'));
                stim_vals = defineStimTrain(del,freq,dur);
                exp_settings = ExperimentSettings(stim_vals,min(end_time,pulse_dur*2),min(del,pulse_dur/2),'sec',wsModel.AcquisitionSampleRate,...
                                               'stim_pulse_dur',pulse_dur);
            elseif strcmp(stim_type,'Sine')
                dur = str2double(wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'Duration'));
                freq = str2double(wsModel.stimulusLibraryItemProperty('ws.Stimulus', stim_ind, 'Frequency'));
                period = 1/freq; 
                stim_vals = del;
                exp_settings = ExperimentSettings(stim_vals,dur,min(del,period/2),'sec',wsModel.AcquisitionSampleRate,...
                                               'stim_pulse_dur',period);
            end                                                        
            exp_settings.convert2Frames(); 
            align_out = calcStimAlignedResponses(V,exp_settings.stim_vals,...
                                exp_settings.baseline_wind,exp_settings.stim_wind);
            V_aligned = align_out.mean_aligned;
            bslines = align_out.baselines; 
%             bslines = mean(V_aligned(1:exp_settings.baseline_wind,:,:),1,'omitnan');
            V_aligned_bs = squeeze(V_aligned - bslines); % baseline subtracted voltage traces  
            ta = (0:(1/wsModel.AcquisitionSampleRate):((size(V_aligned,1)-1)/wsModel.AcquisitionSampleRate))';
            ta = ta-ta(exp_settings.baseline_wind+1);            
            if strcmp(stim_type,'Sine')
                % time synchronized average (Signal Processing Toolbox)
                meanV = tsa(V_aligned_bs(exp_settings.baseline_wind+1:end),...
                            exp_settings.sampling_rate,0:period:(dur-period));
                V_aligned_bs = meanV; % for plotting output
                ta = (0:1/(exp_settings.sampling_rate):(period-1/exp_settings.sampling_rate))';
                ss_V = (max(meanV) - min(meanV))/2; % mean V amplitude
                ss_E = ss_V/(self.iel_mm*1e-3); % V/m E amplitude
            else    
                meanV = mean(V_aligned_bs,2,'omitnan');
%                 pfit = polyfit(ta(1:exp_settings.baseline_wind)',meanV(1:exp_settings.baseline_wind),1);
%                 meanV = meanV - polyval(pfit,ta); % detrend
                ss_wind = (exp_settings.baseline_wind + round(exp_settings.stim_pulse_dur*self.ss_wind_frac) + 1):...
                    (exp_settings.baseline_wind + exp_settings.stim_pulse_dur + 1);
                ss_V = mean(meanV(ss_wind,:),1)';
                ss_E = ss_V/(self.iel_mm*1e-3); % V/m steady state E-field
            end                        
            time_elapsed = toc;
            fprintf('Sweep %g: |E| = %.3f V/m, %.3f V/m per mA (time elapsed = %.3f sec)\n',...
                sweep_ind,ss_E,ss_E/amp_mA,time_elapsed);
        end

        function regressEs(self,wsModel)
            [b,~,~,~,stats] = regress(self.ss_Es,[ones(size(self.amps_mA)) self.amps_mA]); % center x at 0
             self.ss_E_slope = b(2);
             self.ss_E_int = b(1);
             self.regress_Rsq = stats(1); 
             self.regress_p = stats(3); 
             fprintf('%g sweeps: %.3f V/m per mA (R^2 = %.3f, p = %.3f)\n',...
                 wsModel.NSweepsCompletedInThisRun,self.ss_E_slope,...
                 self.regress_Rsq,self.regress_p);
        end
        function plotE(self,wsModel)               
            if ~isvalid(self.E_fig_)
                self.E_fig_ = figure('Units','normalized','Position',[0.1 0.6 0.55 0.3]);
            end
            % Overlay stim averaged pulses for each sweep
            ax = subplot(1,2,1,'Parent',self.E_fig_);
%             ax = axes('Parent',self.E_fig_,'Position',[0.13 0.1511 0.3347 0.752]); 
            if ~isempty(wsModel)
                if wsModel.NSweepsCompletedInThisRun == 1
                    cla(ax);
                end
                plot(ax,self.ta_sweep,mean(self.V_aligned_bs_sweep,2,'omitnan')/(self.iel_mm*1e-3));                
            end
            xlabel(ax,'time (sec)'); 
            ylabel(ax,'|E| (V/m)');
            title(ax,sprintf('|E|: IEL = %g mm, gain = %gx, %g mA/V',...
                            self.iel_mm,self.amplifier_gain,self.isolator_mA_per_V))
            if ~isempty(self.ta_sweep)
                ax.XLim = [self.ta_sweep(1),self.ta_sweep(end)];
            end
            hold(ax,'on');
            % Plot |E| steady state value vs. sweep/amplitude (if varying
            % amplitude)
            ax2 = subplot(1,2,2,'Parent',self.E_fig_);
%             ax2 = axes('Parent',self.E_fig_,'Position',[0.5703 0.1511 0.3347 0.752]);
            cla(ax2);            
            if ~isempty(wsModel)
                if length(unique(self.amps_mA)) > 1 
                    plot(ax2,self.amps_mA,self.ss_Es,'-ko');                    
                    xlabel(ax2,'Current (mA)');
                    ylabel(ax2,'|E| (V/m)')
%                     if wsModel.NSweepsCompletedInThisRun == wsModel.NSweepsPerRun || ...
%                            (wsModel.NSweepsPerRun == inf && wsModel.NSweepsCompletedInThisRun > 2)
                    if ~isempty(self.ss_E_slope)
                        title(sprintf('%.2f V/m per mA. R^{2} = %.3f (p = %.3f)',...
                              self.ss_E_slope,self.regress_Rsq,self.regress_p));
                    end
                else
                    plot(ax2,1:wsModel.NSweepsCompletedInThisRun,self.ss_Es,'-ko');
                    ax2.XLim = [0.5 wsModel.NSweepsCompletedInThisRun+1];
                    xlabel(ax2,'Sweep number');
                    ylabel(ax2,'|E| (V/m)')
                end
            end
            box([ax,ax2],'off');    
            grid([ax,ax2],'on');
        end

        function dataAvailable(self, wsModel)
            % Called each time a "chunk" of data (typically 100 ms worth) 
            % has been accumulated from the looper.
%             analogData = wsModel.getLatestAIData() ;
%             digitalData = wsModel.getLatestDIData() ; 
%             nAIScans = size(analogData,1) ;
%             nDIScans = size(digitalData,1) ;            
%             fprintf('%s  Just read %d scans of analog data and %d scans of digital data.\n', self.Greeting, nAIScans, nDIScans) ;
        end
        
        function startingEpisode(self, refiller)  %#ok<INUSD>
            % Called just before each episode
%             fprintf('%s  About to start an episode.\n',self.Greeting);
        end
        
        function completingEpisode(self, refiller)  %#ok<INUSD>
            % Called after each episode completes
%             fprintf('%s  Completed an episode.\n',self.Greeting);
        end
        
        function stoppingEpisode(self, refiller)  %#ok<INUSD>
            % Called if a episode goes wrong
%             fprintf('%s  User stopped an episode.\n',self.Greeting);
        end        
        
        function abortingEpisode(self, refiller)  %#ok<INUSD>
            % Called if a episode goes wrong
%             fprintf('%s  Oh noes!  An episode aborted.\n',self.Greeting);
        end
    end  % methods
    
    methods 
        % Allows access to private and protected variables for encoding.
        function out = getPropertyValue_(self, name)
            out = self.(name);
        end
        
        % Allows access to protected and protected variables for encoding.
        function setPropertyValue_(self, name, value)
            self.(name) = value;
        end        
    end  % protected methods block
    
    methods
        function mimic(self, other)
            ws.mimicBang(self, other) ;
        end
    end    
    
    methods
        % These are intended for getting/setting *public* properties.
        % I.e. they are for general use, not restricted to special cases like
        % encoding or ugly hacks.
        function result = get(self, propertyName) 
            result = self.(propertyName) ;
        end
        
        function set(self, propertyName, newValue)
            self.(propertyName) = newValue ;
        end           
    end  % public methods block            
    
end  % classdef

