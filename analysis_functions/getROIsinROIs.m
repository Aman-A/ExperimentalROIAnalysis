function [roi1_inds,roi2_inds] = getROIsinROIs(rois1,rois2)
%GETROISINROIS For each ROI in rois1, get ROI in rois2 containing it (if
%exists)
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 

% Get center of ROIs
if isnumeric(rois1.x)
    x1 = rois1.x; 
    y1 = rois1.y;     
else
    % center of mass of each roi (polygons/lines))
    x1 = cellfun(@mean,rois1.x); 
    y1 = cellfun(@mean,rois1.x); 
end
roi1_inds = false(length(x1),1); % set to true if containined in an ROI in rois2
roi2_inds = nan(length(x1),1); % set to index of ROI in rois2 if contained
for i = 1:rois2.num_rois
    in_roi = inpolygon(x1,y1,rois2.x{i},rois2.y{i});
    roi1_inds(in_roi) = true; 
    roi2_inds(in_roi) = i; 
end
roi2_inds = roi2_inds(roi1_inds);
roi1_inds = find(roi1_inds); 

end
