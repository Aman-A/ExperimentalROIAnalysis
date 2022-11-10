function output = calcROIfuncs(recording,rois,funcs,exp_settings,...
                               roi_func_mode,varargin)
%CALCROIFUNCS Calculate functions within ROIs of image stack 
%  
%   Inputs 
%   ------ 
%   recording : Recording object 
%               has 'vals' property with image stack 
%               (M x N x time points stack of images)
%   rois : ROIs object (todo: make generic ROI class)
%           specifies position and size of all ROIs
%   funcs : string or cell array
%           single function (string) or list of functions (cell array) to
%           apply, can be 'mean', 'std', 'deltaF_F0', or 'baseline'
%   exp_settings : ExperimentSettings object
%   uses fields: 
%       bsline_wind : 1 x 2 integer vector or indices
%                   Specify frames to take baseline over, either start and end
%                   or all frames as a vector
%       stim_vals : 1 x num_stim vector of stim times or frames
%   roi_func_mode : string or vector of integers
%                   'combine' or 'separate', specify whether to apply 
%                   function across pixels of all ROIs, or only within ROI. 
%                   'combine' outputs single vector per function, 
%                   'separate' outputs array of vectors for each ROI. 
%                   Or if input is vector, treats as 'combine' mode but
%                   across ROI indices specified in vector, e.g. [1:5]
%   Optional Inputs 
%   --------------- 
%   print_level : integer
%                 Set to 0 to suppress print statements, 1 to turn on
%   Outputs 
%   ------- 
%   output : struct
%            includes fields with data output for each function (func) in 
%            funcs and the img_name, roi_func_mode, and roi_inds
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.print_level = 1;
in.rem_pbleach = 0;
in.rem_pbleach_method = 1; % 1 - Cohen method, smooths based on min value every interp_interval
in.align_use_train_baseline = 1; % if num_trains > 1, in addition to 
                                 % aligning traces to trains, calcROIfuncs 
                                 % also aligns to individual stimuli. 
                                 % Set to 1 to generate deltaF_F0 with 
                                 % baseline of first stim in train, 0 to 
                                 % use baseline before individual stim
                                 % responses                                 
in = sl.in.processVarargin(in,varargin); 
if nargin < 4
   exp_settings = ExperimentSettings([],[],20,'frames',100); 
end
if nargin < 5
   roi_func_mode = 'combine'; % 'combine' or 'separate', specify how to apply function 
end
if ischar(funcs)
    funcs = {funcs};
end
% Sort funcs to ensure mean computed first, allows computing baseline
% from mean traces
if any(strcmp(funcs,'mean')) && any(strcmp(funcs,'baseline'))
   inds = 1:length(funcs);
   inds1 = [find(strcmp(funcs,'mean')),find(strcmp(funcs,'baseline'))];   
   funcs = [funcs(inds1),funcs(setdiff(inds,inds1))];
end
% Get roi_func_mode
if ~ischar(roi_func_mode) && isvector(roi_func_mode)
    roi_inds = roi_func_mode;
    roi_func_mode = 'combine'; % treat as combine mode below
elseif ischar(roi_func_mode)
    roi_inds = 1:rois.num_rois; % Use all rois for default combine and separate modes
else
    error(['roi_func_mode should be either string (''combine'' or ''separate'')',...
           ' or vector of indices to apply function to']);
end
% Get stim and baseline settings
baseline_wind_inds = exp_settings.baseline_wind_inds; 
exp_settings.convert2Frames(); 
stim_frames = exp_settings.stim_vals; % stimulus frames 
stim_wind = exp_settings.stim_wind; % post-stim window in frames
if recording.loaded == 0; recording.load(); end
% Truncate stim_frames based on length of recording
remove_stim_inds = stim_frames + stim_wind > size(recording.vals,3);
if any(remove_stim_inds)
   stim_frames(remove_stim_inds) = []; 
   baseline_wind_inds(:,remove_stim_inds) = []; 
   fprintf('Warning: %g stim frames excluded due to stim_wind exceeding recording length (calcROIfuncs)\n',...
           sum(remove_stim_inds));  
end
% Compute functions in ROIs
tic; 
switch roi_func_mode    
    case 'combine'
        output = struct; 
        mask = rois.getMask(recording.imsize(1:2),roi_inds); % single mask for all (or subset of) ROIs           
        num_masks = 1;
        for i = 1:length(funcs) % add function output to struct in corresponding field            
            output = apply_func(output,1,funcs{i},recording.vals,mask,baseline_wind_inds); 
        end
        print_str = ['Computed funcs: ', strjoin(funcs,', '), ' on ', ...
                      num2str(length(roi_inds)), ' of ',num2str(rois.num_rois),...
                      ' ROIs combined in %.2f sec\n'];                            
    case 'separate' % separate mask for each roi
        output = struct;     
        num_masks = rois.num_rois; 
        for j = 1:num_masks
            maskj = rois.getMask(recording.imsize(1:2),j);                
            for i = 1:length(funcs)                                   
                output = apply_func(output,j,funcs{i},recording.vals,maskj,...
                                    baseline_wind_inds); 
            end            
        end
        print_str = ['Computed funcs: ', strjoin(funcs,', '), ' on ', ...
                      num2str(rois.num_rois), ' ROIs separately in %.2f sec\n']; 
    otherwise 
        error('roi_mode %s does not exist, use ''combine'' or ''separate''\n',roi_func_mode); 
end
time_elapsed = toc; 
if in.print_level > 0
    fprintf(print_str,time_elapsed);
end
%% Apply photobleaching correction
if in.rem_pbleach
    assert(any(strcmp(funcs,'mean')),'Need to compute mean for photobleach correction')    
    if isempty(stim_frames)
        max_stim_interval = round(size(output.mean,1)/10);
    elseif length(stim_frames) == 1
        max_stim_interval = stim_frames(1); 
    else
        max_stim_interval = max(diff(stim_frames(:)));
    end
    if in.rem_pbleach_method == 1 % method from Adam Cohen rem_pbleach code
        interp_interval = min(round(max_stim_interval*1.2),size(output.mean,1));
    elseif in.rem_pbleach_method == 2
%         interp_interval = min(round(max_stim_interval*1.2),50e-3*exp_settings.sampling_rate); % 100 frames for 2kHz (50 ms)
        interp_interval = 3; % matches Gonzalez Sabater 2021
    end
    [mean_pb,pbleach] = removePhotoBleach(output.mean,... % also removes initial transient
                                         'method',in.rem_pbleach_method,...
                                         'interp_interval',interp_interval,...
                                         'skip_initial_frames',3);    
    output.mean_raw = output.mean; 
    output.mean = mean_pb; % replace mean with photobleach corrected values
    output.pbleach = pbleach; 
    % Recompute and replace deltaF_F0 and deltaF with photobleach corrected values,
    % retain raw values with <func>_raw fields in output
    baseline_new = mean(output.mean(baseline_wind_inds(:,1,1),:),1,'omitnan');    
    if any(strcmp(funcs,'deltaF_F0'))
        output.deltaF_F0_raw = output.deltaF_F0;         
        output.deltaF_F0 = (output.mean - baseline_new)./baseline_new; 
    end
    if any(strcmp(funcs,'deltaF'))
        output.deltaF_raw = output.deltaF; 
        output.deltaF = (output.mean-baseline_new); 
    end
    if in.print_level > 0
        fprintf('Applied photobleach correction with method %g and interp_interval %g\n',...
                in.rem_pbleach_method,interp_interval);
    end
end
%% Generate stim-aligned traces using means
if any(strcmp(funcs,'mean'))
    baseline_wind = exp_settings.baseline_wind;
    align_output = calcStimAlignedResponses(output.mean,stim_frames,...
                                            baseline_wind,stim_wind,...
                                            'use_train_baseline',...
                                            in.align_use_train_baseline);
    output.mean_aligned = align_output.mean_aligned;
    output.deltaF_F0_aligned = align_output.deltaF_F0_aligned; 
    ta = exp_settings.getTimeVector(size(align_output.deltaF_F0_aligned,1));
    output.ta = ta - ta(exp_settings.baseline_wind + 1); % set t = 0 to first stim frame 
    print_str = 'Generated stimulus aligned means and deltaF/F0 traces\n';
    if isfield(align_output,'deltaF_F0_aligned2') % for num_trains > 1, 
        output.mean_aligned2 = align_output.mean_aligned2;
        output.deltaF_F0_aligned2 = align_output.deltaF_F0_aligned2; 
        ta2 = exp_settings.getTimeVector(size(align_output.deltaF_F0_aligned2,1));
        output.ta2 = ta2 - ta2(exp_settings.baseline_wind + 1); % set t = 0 to first stim frame 
        print_str = [print_str,...
                    sprintf(' Also aligned to individual spikes in train, use_train_baseline = %g\n',...
                    in.align_use_train_baseline)];        
    end
    if in.print_level > 0        
        fprintf(print_str)
    end
end
%% Add relevant information to output struct
output.img_name = recording.img_name;
% output.rois = rois; 
output.roi_func_mode = roi_func_mode; 
output.roi_inds = roi_inds; 
output.funcs = funcs; 
trec = exp_settings.getTimeVector(recording.imsize(3)); % time vector for full recording
if length(exp_settings.stim_vals) > 1
    output.trec = trec - trec(exp_settings.stim_vals(1)); % set t = 0 to first stim
else
    output.trec = trec; 
end
output.baseline_wind_inds = baseline_wind_inds; 
output.stim_frames = stim_frames; 
%% Function for applying function to image data within ROI masks
function output_new = apply_func(output,ind,func,img,mask,baseline_wind_inds)    
    output_new = output; 
    if strcmp(func,'mean') % spatial mean across all ROI pixels for each frame   
        if ind == 1
            output_new.mean = zeros(size(img,3),num_masks); % initialize
        end                
        output_new.mean(:,ind) = squeeze(sum(img.*mask,[1 2],'omitnan'))/sum(mask,'all','omitnan');                
    elseif strcmp(func,'median') % spatial median across all ROI pixels for each frame
        if ind == 1
            output_new.median = zeros(size(img,3),num_masks); % initialize
        end
        output_new.median(:,ind) = squeeze(median(img.*mask,[1 2],'omitnan'));        
    elseif strcmp(func,'std')% spatial std across all rois within each frame       
        if ind == 1
            output_new.std = zeros(size(img,3),num_masks); % initialize
        end
        output_new.std(:,ind) = squeeze(std(img.*mask,0,[1 2],'omitnan')); 
    elseif strcmp(func,'baseline') % Baseline value within ROI pixels across baseline time window
        if ind == 1
            % rows are rois, columns for for each stimulus
            output_new.baseline = nan([num_masks,size(baseline_wind_inds,2:3)]); % [num_masks x num_stim x num_trains]
        end        
        if isfield(output,'mean') % compute from mean traces
            output_mean = output.mean(:,ind);
            for l = 1:size(baseline_wind_inds,3) % loop over stim trains
                for k = 1:size(baseline_wind_inds,2) % loop over stimuli
                    output_new.baseline(ind,k,l) = mean(output_mean(baseline_wind_inds(:,k,l)),...
                                                                'omitnan');        
                end
            end
        else
            for l = 1:size(baseline_wind_inds,3) % loop over stim trains
                for k = 1:size(baseline_wind_inds,2) % loop over stimuli
                    output_new.baseline(ind,k,l) = mean(img(:,:,baseline_wind_inds(:,k,l)).*mask,...
                                                      'all','omitnan');        
                end
            end
        end        
    elseif strcmp(func,'deltaF') % DeltaF of ROI pixels (averaged)
        if isfield(output,'mean')
            output_mean = output.mean(:,ind);
        else
            output_mean = squeeze(mean(img.*mask,[1 2],'omitnan'));  
        end
        % use baseline of first stim for global deltaF/F0 peak, check 
        % if value was calculated for this index (ind)
        if isfield(output,'baseline') && ~isnan(output.baseline(ind,1)) 
            baseline = output.baseline(ind,1);
        else            
            baseline = mean(img(:,:,baseline_wind_inds(:,1)).*mask,'all','omitnan');                            
        end
        if ind == 1
            output_new.deltaF = zeros(size(img,3),num_masks); % rows are for each stimulus, columns for rois        
        end
        output_new.deltaF(:,ind) = (output_mean - baseline);    
    elseif strcmp(func,'deltaF_F0') % DeltaF/F0 of ROI pixels (averaged)
        if isfield(output,'mean')
            output_mean = output.mean(:,ind);
        else
            output_mean = squeeze(sum(img.*mask,[1 2],'omitnan'))/sum(mask,'all','omitnan');  
        end
        % use baseline of first stim for global deltaF/F0 peak, check 
        % if value was calculated for this index (ind)
        if isfield(output,'baseline') && ~isnan(output.baseline(ind,1)) 
            baseline = output.baseline(ind,1,1);
        else
            baseline = mean(output_mean(baseline_wind_inds(:,1,1)),'omitnan');    
        end
        if ind == 1
            output_new.deltaF_F0 = zeros(size(img,3),num_masks); % rows are for each stimulus, columns for rois        
        end
        output_new.deltaF_F0(:,ind) = (output_mean - baseline)./baseline;
    end
end
end