function rois = detectROIs(recording,intens_thresh,area_thresh,roi_radius,varargin)
% Detect ROIs from image (intended for Synapsin-mRuby images)
% default intens_thresh = 2.9e3, area_thresh = 4 (in microns)
% if intens_thresh < 1, uses as quantile cutoff based on values in image
% area_thresh = [min_area] or [min_area max_area]
in.center_mode = 2; % 0 - off, 1 - cetner based on points, 2 - center based on peak value
in.plot_figs = 1;
in.save_figs = 0;
in.min_distance = 3.2; % microns, set to 0 to skip (3.2 = 8 pixel diam ROI on ixon 897 with 40x)
in.min_distance_to_edge = 2; % microns
in.filt_width = 0; % gaussian filter window (pixels), set to 0 for no filter
in.filt_type = 'gaussian'; % 'gaussian' or 'log' (inputs to fspecial.m)
in = sl.in.processVarargin(in,varargin);

if ischar(recording) % path to recording file
    recording = Recording(recording);    
    recording.load(); 
    vals = recording.vals;
    pixel_size = recording.pixel_size;
    imsize = recording.imsize; 
elseif isa(recording,'Recording')
    recording.load(); 
    vals = recording.vals;
    pixel_size = recording.pixel_size;
    imsize = recording.imsize; 
else
    vals = recording;
    vals0 = vals; % original, unfiltered image
    pixel_size = 0.4; % default (um) for 40x with EMCCDs
    imsize = size(vals); 
end

if isempty(roi_radius) || roi_radius == 0
    % use polygons
    use_circ_rois = 0;
else
    use_circ_rois = 1; 
end

% vals = max(vals,[],3); % max Z projection if recording is image stack 
vals = mean(vals,3); % mean Z projection if recording is image stack 
if in.filt_width > 0
%     vals = imgaussfilt(vals,in.filt_width); 
%     fprintf('Applied gaussian filter with width = %g pixels\n',in.filt_width); 
    hsize = 2*ceil(2*in.filt_width)+1;  % default imgaussfilt def of filter size
    h = fspecial(in.filt_type,hsize,in.filt_width);
    vals = imfilter(vals,h,'replicate');
    if strcmp(in.filt_type,'log')
        vals = -vals;
    end
    fprintf('Applied %s filter with width %g pixels\n',in.filt_type,in.filt_width)
end
% Binarize using threshold
if intens_thresh < 1
    intens_thresh_val = quantile(vals(:),intens_thresh);
else
    intens_thresh_val = intens_thresh;     
end
vals_bin = zeros(size(vals)); 
vals_bin(vals>=intens_thresh_val) = 1;
vals_bin = logical(vals_bin); 
% Fill 
% remove objects below area_thresh
% vals_holes = bwareaopen(vals,area_thresh(1));
area_thresh_px = area_thresh/pixel_size^2; % convert to pixels 
if length(area_thresh_px) == 1 % input min cutoff only
   % assign max possible for upper range
    area_thresh_px = [area_thresh_px imsize(1)*imsize(2)];
end
vals_holes = bwareafilt(vals_bin,area_thresh_px);
vals_filled = imfill(vals_holes,'holes');
% Get contours
[B,L] = bwboundaries(vals_filled,4,'noholes'); % draw boundaries on regions connected by edges (not just corners)
B2 = cellfun(@(x) [x(:,2),x(:,1)],B,'UniformOutput',0); % rearrange [x y]
%% Get centers
if in.center_mode == 1 % make circular ROIs using center of boundary points
    centers = cell2mat(cellfun(@(x) mean(x,1),B2,'UniformOutput',0));
elseif in.center_mode == 2 % make circular ROIs centered on peak intensity within boundary
    rois_poly = ROIs(B2);
    rois_poly.recenterROIs(vals);
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
    imsize_um = imsize(1:2)*pixel_size;     
    edge_dists = [centers_um(:,1),imsize_um(2)-centers_um(:,1),centers_um(:,2),imsize_um(1)-centers_um(:,2)];
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
if in.plot_figs
    fig1 = figure('Units','inches');
    imshowpair(vals_bin,vals_holes,'falsecolor'); ax = gca;
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
    ax = gca;
    if isa(recording,'Recording')
        recording.plot(); 
        caxis(ax,quantile(recording.vals(:),[0.6 0.999]))
    else
        imagesc(vals0)
        axis(ax,'equal','tight','off')
        ax.YDir = 'normal';
        colorbar; 
        caxis(ax,quantile(vals0(:),[0.6 0.999]))
    end    
    rois.plot('g',ax,1,1); 
    
    colormap(ax,inferno(1000));      
    ax.Position = [0.05 0.05 0.9 0.9];
%     InSet = get(ax, 'TightInset');
%     set(ax, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
    if in.save_figs        
        fig_dir = recording.filedir; 
        printFig(fig1,fig_dir,'DetectedRoiSet_thresh')
        printFig(fig2,fig_dir,'DetectedRoiSet_final')
    end
end
end