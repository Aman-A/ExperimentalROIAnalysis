function rois = detectROIs(recording,intens_thresh,area_thresh,roi_radius,varargin)
% Detect ROIs from image (intended for Synapsin-mRuby images)
% default intens_thresh = 2.9e3, area_thresh = 4
% if intens_thresh < 1, uses as quantile cutoff based on values in image
% area_thresh = [min_area] or [min_area max_area]
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
pixel_size = recording.pixel_size;
vals = max(recording.vals,[],3); % max Z projection if recording is image stack 
% Binarize using threshold
if intens_thresh < 1
    intens_thresh = quantile(recording.vals(:),intens_thresh);
end
vals(recording.vals<intens_thresh) = 0; 
vals(recording.vals>=intens_thresh) = 1;
vals = logical(vals); 
% Fill 
% remove objects below area_thresh
% vals_holes = bwareaopen(vals,area_thresh(1));
area_thresh_px = area_thresh/pixel_size^2; % convert to pixels 
if length(area_thresh_px) == 1 % input min cutoff only
   % assign max possible for upper range
    area_thresh_px = [area_thresh_px recording.imsize(1)*recording.imsize(2)];
end
vals_holes = bwareafilt(vals,area_thresh_px);
vals_filled = imfill(vals_holes,'holes');
% Get contours
[B,L] = bwboundaries(vals_filled,4,'noholes'); % draw boundaries on regions connected by edges (not just corners)
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
centers_um0 = centers*pixel_size; % convert to um
if in.min_distance > 0
    center2center_dists = sqrt((centers_um0(:,1) - centers_um0(:,1)').^2 + ... 
                                (centers_um0(:,2)-centers_um0(:,2)').^2);
    diag_inds = 1:size(center2center_dists,1) + 1:numel(center2center_dists); % indices of diagonal elements
    center2center_dists(diag_inds) = nan; 
    min_neighbor_dist = min(center2center_dists,[],2,'omitnan');
    close_rois = min_neighbor_dist < in.min_distance; % rois with another roi < min_distance away
    centers_um = centers_um0(~close_rois,:);
    centers = centers(~close_rois,:);
    B3 = B2(~close_rois);
    fprintf('Excluded %g ROIs with adjacent neighbors < %.1f um away\n',...
            sum(close_rois),in.min_distance); 
else
    close_rois = false(length(B2),1);
    B3 = B2; 
end
% Exclude ROIs to close to edge
if in.min_distance_to_edge > 0
    % left, right, bottom, top
    imsize = recording.imsize(1:2)*pixel_size;     
    edge_dists = [centers_um(:,1),imsize(2)-centers_um(:,1),centers_um(:,2),imsize(1)-centers_um(:,2)];
    edge_rois = any(edge_dists < in.min_distance_to_edge,2);
%     centers_um = centers_um(~edge_rois,:);
    centers = centers(~edge_rois,:);
    B4 = B3(~edge_rois);
    fprintf('Excluded %g ROIs < %.1f um away from image borders\n',...
                sum(edge_rois),in.min_distance_to_edge); 
else
    B4 = B3; 
end
%% Make ROIs
if use_circ_rois
    rois = ROIs([centers,roi_radius*ones(size(centers,1),1)]); 
else % polygons
    rois = ROIs(B4); % use boundaries to make ROIs
end
fprintf('Detected %g ROIs!\n',rois.num_rois)
if in.plot_fig
    fig1 = figure('Units','inches');
    imshowpair(vals,vals_holes,'falsecolor'); ax = gca;
    fig1.Position = [0.42 6.4 20.5 5.2]; 
    title(sprintf('Excluded regions with areas < %g and > %g \\mu m^2 (green) and neighbors < %g \\mu m apart (red)',...
        area_thresh(1),area_thresh(2),in.min_distance))
    axis equal; axis tight;
    ax.Position = [0.05 0.05 0.9 0.9];
    ax.YDir = 'normal';
    % plot ROIs that were excluded due to proximity
    rois_close = ROIs(B2(close_rois));
    rois_close.plot('r')
%     InSet = get(ax, 'TightInset');
%     set(ax, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
%     set(gca, 'LooseInset', get(gca,'TightInset'))
%     fig1.Position(3:4) = [19.3 5];
    fig2 = figure('Units','inches','Position',[0.1 1 20.5 5.2]); 
    recording.plot(); ax = gca;
    rois.plot('g',gca,1,1); 
    caxis(quantile(recording.vals(:),[0.6 0.999]))
    colormap(inferno(1000));      
    ax.Position = [0.05 0.05 0.9 0.9];
%     InSet = get(ax, 'TightInset');
%     set(ax, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
end
end