function rois = detectROIs(recording,intens_thresh,area_thresh,roi_radius,varargin)
% Detect ROIs from image
% default intens_thresh = 2.9e3, area_thresh = 4
% if intens_thresh < 1, uses as quantile cutoff based on values in image
in.center_mode = 1; % 0 - off, 1 - cetner based on points, 2 - center based on peak value
in.plot_fig = 1;
in = sl.in.processVarargin(in,varargin);

if ischar(recording) % path to recording file
    recording = Recording(recording);    
end

if isempty(roi_radius) || roi_radius == 0
    % use polygons
    use_circ_rois = 0;
else
    use_circ_rois = 1; 
end

recording.load(); 
vals = recording.vals; 
% Binarize using threshold
if intens_thresh < 1
    intens_thresh = quantile(recording.vals(:),intens_thresh);
end
vals(recording.vals<intens_thresh) = 0; 
vals(recording.vals>=intens_thresh) = 1; 
% Fill 
vals_holes = bwareaopen(vals,area_thresh);
vals_filled = imfill(vals_holes,'holes');
% Get contours
[B,L] = bwboundaries(vals_filled,'noholes');
B2 = cellfun(@(x) [x(:,2),x(:,1)],B,'UniformOutput',0); % rearrange [x y]
if use_circ_rois
    if in.center_mode == 1 % make circular ROIs using center of boundary points
        centers = cell2mat(cellfun(@(x) mean(x,1),B2,'UniformOutput',0));
    elseif in.center_mode == 2 % make circular ROIs centered on peak intensity within boundary
        rois_poly = ROIs(B2);
        rois_poly.recenterROIs(recording.vals);
        center_x = cellfun(@(x) mean(x),rois_poly.x,'UniformOutput',1);
        center_y = cellfun(@(x) mean(x),rois_poly.y,'UniformOutput',1);
        centers = [center_x,center_y];
    end
    rois = ROIs([centers,roi_radius*ones(size(centers,1),1)]); 
else % polygons
    rois = ROIs(B2); % use boundaries to make ROIs
end
if in.plot_fig
    figure; 
    recording.plot(); 
    rois.plot('g'); 
    caxis(quantile(recording.vals(:),[0.6 0.999]))
    colormap(inferno(1000))
end