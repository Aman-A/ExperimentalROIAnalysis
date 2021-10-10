function output = calcROIfuncs(img,rois,funcs,baseline_wind_inds,...
                               roi_func_mode,varargin)
%CALCROIFUNCS ... 
%  
%   Inputs 
%   ------ 
%   img : Recording object with vals property (M x N x time points stack of
%         images)
%   rois : ROIs object (todo: make generic ROI class)
%           specifies position and size of all ROIs
%   funcs : string or cell array
%           single function (string) or list of functions (cell array) to
%           apply, can be 'mean', 'std', 'deltaF_F0', or 'baseline'
%   bsline_wind : 1 x 2 integer vector or indices
%               Specify frames to take baseline over, either start and end
%               or all frames as a vector
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
in = sl.in.processVarargin(in,varargin); 
if nargin < 4
   baseline_wind_inds = 1:100; 
end
if nargin < 5
   roi_func_mode = 'combine'; % 'combine' or 'separate', specify how to apply function 
end
if ischar(funcs)
    funcs = {funcs};
end
if ~ischar(roi_func_mode) && isvector(roi_func_mode)
    roi_inds = roi_func_mode;
    roi_func_mode = 'combine'; % treat as combine mode below
elseif ischar(roi_func_mode)
    roi_inds = 1:rois.num_rois; % Use all rois for default combine and separate modes
else
    error(['roi_func_mode should be either string (''combine'' or ''separate'')',...
           ' or vector of indices to apply function to']);
end
tic; 
switch roi_func_mode    
    case 'combine'
        output = struct; 
        mask = rois.getMask(img.imsize(1:2),roi_inds); % single mask for all (or subset of) ROIs           
        num_masks = 1;
        for i = 1:length(funcs) % add function output to struct in corresponding field            
            output = apply_func(output,1,funcs{i},img.vals,mask,baseline_wind_inds); 
        end
        print_str = ['Computed funcs: ', strjoin(funcs,', '), ' on ', ...
                      num2str(length(roi_inds)), ' of ',num2str(rois.num_rois),...
                      ' ROIs combined in %.2f sec\n'];                            
    case 'separate' % separate mask for each roi
        output = struct;     
        num_masks = rois.num_rois;
        for j = 1:num_masks
            maskj = rois.getMask(img.imsize(1:2),j);                
            for i = 1:length(funcs)                                   
                output = apply_func(output,j,funcs{i},img.vals,maskj,baseline_wind_inds); 
            end
        end
        print_str = ['Computed funcs: ', strjoin(funcs,', '), ' on ', ...
                      num2str(rois.num_rois), ' ROIs separately in %.2f sec\n']; 
    otherwise 
        error('roi_mode %s does not exist, use ''combine'' or ''separate''\n',roi_func_mode); 
end
output.img_name = img.img_name;
output.rois = rois; 
output.roi_func_mode = roi_func_mode; 
output.roi_inds = roi_inds; 
output.funcs = funcs; 
output.baseline_wind_inds = baseline_wind_inds; 
time_elapsed = toc; 
if in.print_level > 0
    fprintf(print_str,time_elapsed);
end
function output_new = apply_func(output,ind,func,img,mask,bsline_wind)    
    output_new = output; 
    if strcmp(func,'mean') % spatial mean across all rois     
        if ind == 1
            output_new.mean = zeros(size(img,3),num_masks); % initialize
        end
        output_new.mean(:,ind) = squeeze(mean(img.*mask,[1 2],'omitnan'));         
    elseif strcmp(func,'std')% spatial std across all rois        
        if ind == 1
            output_new.std = zeros(size(img,3),num_masks); % initialize
        end
        output_new.std(:,ind) = squeeze(std(img.*mask,0,[1 2],'omitnan')); 
    elseif strcmp(func,'baseline') % Baseline value within ROI pixels across baseline time window
        if ind == 1
            output_new.baseline = nan(size(bsline_wind,1),num_masks); % rows are for each stimulus, columns for rois        
        end
        for k = 1:size(bsline_wind,1)
            output_new.baseline(k,ind) = mean(img(:,:,bsline_wind(k,:) ).*mask,'all','omitnan');        
        end
    elseif strcmp(func,'deltaF_F0') % DeltaF/F0 of ROI pixels (averaged)
        if isfield(output,'mean')
            output_mean = output.mean(:,ind);
        else
            output_mean = squeeze(mean(img.*mask,[1 2],'omitnan'));  
        end
        % use baseline of first stim for global deltaF/F0 peak, check 
        % if value was calculated for this index (ind)
        if isfield(output,'baseline') && ~isnan(output.baseline(1,ind)) 
            baseline = output.baseline(1,ind);
        else
            baseline = mean(img(:,:,bsline_wind(1,:)).*mask,'all','omitnan');    
        end
        if ind == 1
            output_new.deltaF_F0 = zeros(size(img,3),num_masks); % rows are for each stimulus, columns for rois        
        end
        output_new.deltaF_F0(:,ind) = (output_mean - baseline)./baseline;
    end
end
end