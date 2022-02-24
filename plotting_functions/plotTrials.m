function trials_data = plotTrials(img_names,exp_settings,roi_set_filename,...
                                  varargin)
%PLOTTRIALS Plot set of trials on same axis  
%   
in = plotTrialSettings; % get defaults from plotTrialSettings
in = sl.in.processVarargin(in,varargin); 
%% Get file names within condition if not input
if isempty(img_names) % assume all .fits files are relevant trial data
    if isempty(in.filedir) % construct default experiment file path to this condition
        filedir = fullfile(in.data_fold,in.exp_date,in.reporter,in.dish,in.condition);            
        img_names = getImagesWithinDir(filedir); 
    else % use input path to find all trials for this condition
        filedir = in.filedir; 
        img_names = getImagesWithinDir(filedir); 
        % append full path
        img_names = fullfile(filedir,img_names); 
    end   
end
if ischar(img_names)
   img_names = {img_names};  
end
num_trials = length(img_names); 
plot_trials = ~strcmp(in.plot_func,'none') && all(in.plot_func~=0) ...
                && ~isempty(in.plot_func); 
if in.overlay_trials && plot_trials
    trace_fig = figure; 
    if strcmp(in.roi_func_mode,'combine')
        trace_axis = gca; 
    elseif strcmp(in.roi_func_mode,'separate') 
        if num_trials > 1
            traces_axes = cell(num_trials,1); 
            for i = 1:num_trials
                traces_axes{i} = subplot(1,num_trials,i);         
            end
        else
            trace_axis = gca;
        end
    end
else
    trace_axis = [];
end
func_outputs = cell(1,num_trials); 
deltaF_F0 = cell(1,num_trials); 
deltaF_F0_aligned = cell(1,num_trials); 
trial_times = NaT(1,num_trials); 
bslines = cell(1,num_trials); 
means = cell(1,num_trials); 
rois_all = cell(1,num_trials); 
% Format roi_set_filename
if iscell(roi_set_filename) && length(roi_set_filename) == 1
    roi_set_filename = roi_set_filename{1};
end
if ischar(roi_set_filename) || ~iscell(roi_set_filename)
    roi_set_filename = repmat({roi_set_filename},1,num_trials);
    % roi_set_filename should be cell array of length num_trials
end
if ~strcmp(in.transform_type,'none') && ~isempty(in.registration_rec)
    if ischar(in.registration_rec)    
        in.registration_rec = Recording(in.registration_rec);  % pre-load once
        if ~exist(in.registration_rec.filepath,'file')                   
            error('''%s'' input for registration_rec does not exist',in.registration_rec);  
        end
    end
end
for i = 1:num_trials
    if strcmp(in.roi_func_mode,'separate') && num_trials > 1 && ...
            ~strcmp(in.plot_func,'none') && all(in.plot_func~=0) && in.overlay_trials
        trace_axis = traces_axes{i};         
    end
    img_namei = img_names{i}; 
    datai = plotTrial(img_namei,exp_settings,roi_set_filename{i},...
                       trace_axis,in);
    func_outputs{i} = datai.func_output; 
    deltaF_F0{i} = datai.func_output.deltaF_F0;
    if isfield(datai.func_output,'deltaF_F0_aligned')
        deltaF_F0_aligned{i} = datai.func_output.deltaF_F0_aligned; 
    end
    trial_times(i) = datai.recording.time_start; 
    bslines{i} = datai.func_output.baseline;    
    rois_all{i} = datai.rois;
    if any(strcmp('mean',in.funcs))
       means{i} = datai.func_output.mean; 
    end
end
if strcmp(in.reporter,'GluSnFR3')
    analysis_funcs = {'peaks','peak_times','poststim_ints','decay_fit'};
else
    analysis_funcs = {'peaks','peak_times'};
end
if ~exist('filedir','var')
    filedir = datai.recording.filedir;
end
if strcmp(in.roi_func_mode,'combine')
    deltaF_F0 = cell2mat(deltaF_F0); 
    bslines = squeeze(cell2mat(bslines')'); % num_stim x num_trials 
    mean_deltaF_F0 = mean(deltaF_F0,2); % average across trials
    if any(strcmp('mean',in.funcs))
        means = cell2mat(means); 
    end
    if isfield(datai.func_output,'deltaF_F0_aligned')        
        deltaF_F0_aligned = cell2mat(reshape(deltaF_F0_aligned,1,1,num_trials)); % [num_frames x num_stim x num_trials]
        analysis = analyzeStimAlignedTraces(deltaF_F0_aligned,exp_settings,...
                                            'funcs',analysis_funcs,...
                                            'load',in.load_processed_data,...
                                            'save_dir',filedir);  
        mean_deltaF_F0_aligned = mean(deltaF_F0_aligned,[2 3]); % average across stimuli and trials
        mean_peak_deltaF_F0 = analysis.mean_peak;
        std_peak_deltaF_F0 = analysis.std_peak; 
    else
        analysis = analyzeTraces(deltaF_F0,exp_settings,'funcs',analysis_funcs);    
        mean_peak_deltaF_F0 = mean(analysis.mean_peak); 
        std_peak_deltaF_F0 = std(analysis.peaks,0);
    end
    fprintf('%s: Peak deltaF_F0 across stimuli and trials (mean +/- std) = %.3f +/- %.3f\n',...
             in.condition, mean_peak_deltaF_F0,std_peak_deltaF_F0); 
    fprintf('  Mean baseline (%g frames, 1st stim) across trials = %.3f +/- %.3f\n',...
            exp_settings.baseline_wind,mean(bslines(1,:)),std(bslines(1,:),0));
elseif strcmp(in.roi_func_mode,'separate') 
    % [num_frames x num_rois x num_stim x num_trials]    
    if isfield(datai.func_output,'deltaF_F0_aligned')
        deltaF_F0_aligned = squeeze(cell2mat(reshape(deltaF_F0_aligned,1,1,1,num_trials)));
        analysis = analyzeStimAlignedTraces(deltaF_F0_aligned,exp_settings,...
                                            'funcs',analysis_funcs,...
                                            'load',in.load_processed_data,...
                                            'save_dir',filedir);                                   
        mean_deltaF_F0_aligned = mean(deltaF_F0_aligned,[3 4]); % average across stimuli and trials
        mean_peak_deltaF_F0 = analysis.mean_peak;
        std_peak_deltaF_F0 = analysis.std_peak; 
    else
        analysis = cellfun(@(x) analyzeTraces(x,exp_settings,'funcs',analysis_funcs),...
                            deltaF_F0,'UniformOutput',0);        
        analysis = [analysis{:}]; % convert to struct array    
        mean_peak_deltaF_F0 = mean(concatFieldInStructArray(analysis,'peaks'),3); % mean across trials, within roi
        std_peak_deltaF_F0 = concatFieldInStructArray(analysis,'std_peak'); % std across trials, within roi    
    end
    
    bslines = squeeze(cell2mat(reshape(bslines,1,1,num_trials))); % [num_rois x num_stim x num_trials]     
    deltaF_F0 = cell2mat(reshape(deltaF_F0,1,1,num_trials)); % [num_frames x num_rois x num_trials]
    mean_deltaF_F0 = mean(deltaF_F0,3); % average traces across trials    
    fprintf('%s: Peak deltaF_F0 across trials and ROIs (mean +/- std) = %.3f +/- %.3f\n',...
             in.condition, mean(mean_peak_deltaF_F0(1,:,:),[2,3]),...
             mean(std_peak_deltaF_F0(1,:,:),[2,3])); 
    fprintf('  Mean baseline (%g frames) across trials and ROIs = %.3f +/- %.3f\n',...
            exp_settings.baseline_wind,mean(bslines,'all'),std(bslines,0,'all'));
end
trials_data = struct(); 
trials_data.deltaF_F0 = deltaF_F0;
trials_data.mean_deltaF_F0 = mean_deltaF_F0;
if isfield(datai.func_output,'deltaF_F0_aligned')
    trials_data.deltaF_F0_aligned = deltaF_F0_aligned;
    trials_data.mean_deltaF_F0_aligned = mean_deltaF_F0_aligned;
end
if any(strcmp('mean',in.funcs))
    trials_data.means = means; 
end
trials_data.analysis = analysis;
trials_data.trial_times = trial_times; 
trials_data.bslines = bslines;
trials_data.rois_all = rois_all; 
trials_data.img_names = img_names; 
if in.save_fig && in.overlay_trials && plot_trials
    if isfield(datai,'fig_dir') && isempty(in.data_fold)
        fig_dir = datai.fig_dir;
    else
        roiset_filename_no_ext = getROIset_name(roi_set_filename{1},...
                                            in.transform_type,...
                                            in.registration_rec);  
        fig_dir = fullfile(in.data_fold,in.exp_date,in.reporter,in.dish,...
                            in.condition,['figs_',roiset_filename_no_ext]);
    end
    fig_name = sprintf('%s_%s_%s_%gtrials',in.condition,in.plot_func,in.roi_func_mode(1:3),num_trials);
    printFig(trace_fig,fig_dir,fig_name);
end
end