function output = calcROIfuncs(img,rois,funcs,baseline_wind_inds,...
                               roi_func_mode)
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
%   roi_mode : string
%          'combine' or 'separate', specify whether to apply function
%          across pixels of all ROIs, or only within ROI. 'combined' outputs
%          single vector per function, 'separate' outputs array of vectors for each ROI
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   output : struct
%            includes fields for each func input in funcs and img_name
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if nargin < 4
   baseline_wind_inds = 1:100; 
end
if nargin < 5
   roi_func_mode = 'combine'; % 'combine' or 'separate', specify how to apply function 
end
if ischar(funcs)
    funcs = {funcs};
end
switch roi_func_mode    
    case 'combine'
        output = struct; 
        mask = rois.getMask(img.imsize(1:2),1:rois.num_rois); % single mask for all ROIs           
        num_masks = 1;
        for i = 1:length(funcs) % add function output to struct in corresponding field            
            output = apply_func(output,1,funcs{i},img.vals,mask,baseline_wind_inds); 
        end
    case 'separate' % separate mask for each roi
        output = struct;     
        num_masks = rois.num_rois;
        for j = 1:num_masks
            maskj = rois.getMask(img.imsize(1:2),j);                
            for i = 1:length(funcs)                                   
                output = apply_func(output,j,funcs{i},img.vals,maskj,baseline_wind_inds); 
            end
        end
    otherwise 
        error('roi_mode %s does not exist, use ''combine'' or ''separate''\n',roi_func_mode); 
end
output.img_name = img.img_name;
output.rois = rois; 
output.roi_mode = roi_func_mode; 
output.funcs = funcs; 
output.baseline_wind_inds = baseline_wind_inds; 
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
            output_new.baseline = zeros(size(bsline_wind,1),num_masks); % rows are for each stimulus, columns for rois        
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
        if isfield(output,'baseline') % use baseline of first stim for global deltaF/F0 peak
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