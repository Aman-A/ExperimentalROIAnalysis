function rois = detectROIs(recording,intens_thresh,area_thresh,roi_radius,varargin)
% Detect ROIs from image
% default intens_thresh = 2.9e3, area_thresh = 4
% if intens_thresh < 1, uses as quantile cutoff based on values in image
in.center_mode = 2; % 0 - off, 1 - cetner based on points, 2 - center based on peak value
in.plot_fig = 1;
in.min_distance = 3.2; % microns, set to 0 to skip (3.2 = 8 pixel diam ROI on ixon 897 with 40x)
in.min_distance_to_edge = 3.2; % microns
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
vals = recording.vals(:,:,1); 
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
%% Get centers
if in.center_mode == 1 % make circular ROIs using center of boundary points
    centers = cell2mat(cellfun(@(x) mean(x,1),B2,'UniformOutput',0));
elseif in.center_mode == 2 % make circular ROIs centered on peak intensity within boundary
    rois_poly = ROIs(B2);
    rois_poly.recenterROIs(recording.vals(:,:,1));
    center_x = cellfun(@(x) mean(x),rois_poly.x,'UniformOutput',1);
    center_y = cellfun(@(x) mean(x),rois_poly.y,'UniformOutput',1);
    centers = [center_x,center_y];
end
%% Apply exclusion criteria
% Exclude ROIs too close to other ROIs
centers_um = centers*recording.pixel_size; % convert to um
if in.min_distance > 0
    center2center_dists = sqrt((centers_um(:,1) - centers_um(:,1)').^2 + (centers_um(:,2)-centers_um(:,2)').^2);
    diag_inds = 1:size(center2center_dists,1) + 1:numel(center2center_dists); % indices of diagonal elements
    center2center_dists(diag_inds) = nan; 
    min_neighbor_dist = min(center2center_dists,[],2,'omitnan');
    close_rois = min_neighbor_dist < in.min_distance; % rois with another roi < min_distance away
    centers_um = centers_um(~close_rois,:);
    centers = centers(~close_rois,:);
    B2 = B2(~close_rois);
    fprintf('Excluded %g ROIs with adjacent neighbors < %.1f um away\n',...
            sum(close_rois),in.min_distance); 
end
% Exclude ROIs to close to edge
if in.min_distance_to_edge > 0
    % left, right, bottom, top
    imsize = recording.imsize(1:2)*recording.pixel_size;     
    edge_dists = [centers_um(:,1),imsize(2)-centers_um(:,1),centers_um(:,2),imsize(1)-centers_um(:,2)];
    edge_rois = any(edge_dists < in.min_distance_to_edge,2);
%     centers_um = centers_um(~edge_rois,:);
    centers = centers(~edge_rois,:);
    B2 = B2(~edge_rois);
    if sum(edge_rois) > 0
        fprintf('Excluded %g ROIs with adjacent neighbors < %.1f um away\n',...
                sum(edge_rois),in.min_distance); 
    end
end
%% Make ROIs
if use_circ_rois
    rois = ROIs([centers,roi_radius*ones(size(centers,1),1)]); 
else % polygons
    rois = ROIs(B2); % use boundaries to make ROIs
end
if in.plot_fig
    figure; 
    recording.plot(); 
    rois.plot('g',gca,1,1); 
end
end