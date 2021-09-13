function output = calcROIfuncs(img,rois,funcs,baseline_wind_inds,...
                               roi_func_mode)
%CALCROIFUNCS ... 
%  
%   Inputs 
%   ------ 
%   img : Recording object with vals property (M x N x time points stack of
%         images)
%   rois : circROIs object (todo: make generic ROI class)
%           specifies position and size of all ROIs
%   funcs : string or cell array
%           single function (string) or list of functions (cell array) to
%           apply, can be 'mean', 'std', 'deltaF_F0', or 'baseline'
%   bsline_wind : 1 x 2 integer vector or indices
%               Specify frames to take baseline over, either start and end
%               or all frames as a vector
%   roi_mode : string
%          'combined' or 'separate', specify whether to apply function
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
        mask = rois.getMask(1:rois.num_rois,img.imsize(1:2)); % single mask for all ROIs        
        mask_inds = find(mask);
        [mask_rows,mask_cols] = ind2sub(size(mask),mask_inds);        
        for i = 1:length(funcs) % add function output to struct in corresponding field
            output = apply_func(output,1,funcs{i},img.vals,mask_rows,mask_cols,baseline_wind_inds); 
        end
    case 'separate' % separate mask for each roi
        output = struct;                         
        for j = 1:rois.num_rois
            for i = 1:length(funcs)      
                maskj = rois.getMask(j,img.imsize(1:2));
                mask_indsj = find(maskj);
                [mask_rowsj,mask_colsj] = ind2sub(size(maskj),mask_indsj);
                output = apply_func(output,j,funcs{i},img.vals,mask_rowsj,mask_colsj,baseline_wind_inds); 
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
function output_new = apply_func(output,ind,func,img,mask_rows,mask_cols,bsline_wind)    
    output_new = output; 
    if strcmp(func,'mean') % spatial mean across all rois
        output_new.mean(:,ind) = squeeze(mean(img(mask_rows,mask_cols,:),[1 2]));
    elseif strcmp(func,'std')% spatial std across all rois
        output_new.std(:,ind) = squeeze(std(img(mask_rows,mask_cols,:),0,[1 2]));
    elseif strcmp(func,'baseline')
        output_new.baseline(:,ind) = squeeze(mean(img(mask_rows,mask_cols,bsline_wind(1):bsline_wind(end)),'all'));
    elseif strcmp(func,'deltaF_F0')
        if isfield(output,'mean')
            output_mean = output.mean(:,ind);
        else
            output_mean = squeeze(mean(img(mask_rows,mask_cols,:),[1 2]));
        end
        if isfield(output,'baseline')
            baseline = output.baseline(:,ind);
        else
            baseline = squeeze(mean(img(mask_rows,mask_cols,bsline_wind(1):bsline_wind(end)),'all'));
        end
        output_new.deltaF_F0(:,ind) = (output_mean - baseline)./baseline;
    end
end
end