classdef ROIs < matlab.mixin.Copyable % Set of circular ROIs
    % TODO: Make plot_inds method to plot selected ROI indices (instead of
    % all ROIs). Maybe make it wrapper for plot function, modify plot
    properties
        % circle ROI properties
         x0 % original center x's
         y0 % original center y's
         x  % current center x's
         y  % current center y's
         radius % radius in pixels        
        % Rectangular ROI properties
         r0 % original edge positions [min row, max row, min column, max column]        
         r  % current edge positions [min row, max row, min column, max column]
        names % names from ImageJ
        num_rois % number of rois
        types % Cell array of ROItypes, e.g. 'Oval'/'Circle' or 'Rectangle'
        roiset_filename char {mustBeTextScalar} % file name
        format char {mustBeTextScalar} % file extension (default '.zip')
        roiset_filedir char {mustBeTextScalar} % directory file is in
        roiset_filepath char {mustBeTextScalar} % full path to file
        loaded = false 
        y_inverted = false; 
        registration_rec char {mustBeTextScalar} % full path to recording for coregistration
        transform_type = 'none'; 
    end
    methods
        function obj = ROIs(file_or_roi_array,varargin)            
            % Inputs:
            %   file_or_roi_array : matrix/cell array or string
            %                       Input list of ROIs in cell array,
            %                       syntax defined below, or filename of
            %                       ImageJ ROIs saved as zip file to be
            %                       loaded
            % Optional inputs:
            in.roiset_filedir = pwd; % directory from which to load ImageJ 
                                      % roi file, if not included in 
                                      % file_or_roi_array arg
            in.print_status = 1; 
            in.names = {}; 
            in = sl.in.processVarargin(in,varargin);
            if nargin == 0
                return; % allow for empty ROIs object for no input
            end
            if ischar(file_or_roi_array)
               roiset_filename = file_or_roi_array;                
               load_roi = true;
            else
               obj.roiset_filename = 'none';
               load_roi = false;
            end            
            
            if load_roi
                [path_to_roiset,roiset_name,ext] = fileparts(roiset_filename);
                if isempty(path_to_roiset)
                    obj.roiset_filedir = in.roiset_filedir;
                else
                    obj.roiset_filedir = path_to_roiset;
                end
                obj.roiset_filename = roiset_name;            
                if isempty(ext)
                   obj.format= '.zip'; % assume zip format 
                else
                    obj.format = ext; 
                end                                
                obj.roiset_filepath = fullfile(obj.roiset_filedir,...
                                                [obj.roiset_filename obj.format]);
                ROIarray = ReadImageJROI(obj.roiset_filepath); % load .zip ROI set
                obj.num_rois = length(ROIarray);         
                obj.loaded = true;
                if in.print_status > 0
                    fprintf('Loaded %g ROIs from %s\n',obj.num_rois,obj.roiset_filepath); 
                end
                % Process ROIs into easier to work with format
                obj.processROIs(ROIarray);    
            else
                if iscell(file_or_roi_array) % cell array of polygon ROIs defined as [Npoints x 2] arrays
                    % NOTE: REQUIRES ALL ROIS TO BE SAME FORMAT
                    obj.num_rois = length(file_or_roi_array);  
                    if isempty(in.names)
                       obj.names = arrayfun(@(x) sprintf('ROI%g',x),0:obj.num_rois-1,...
                                            'UniformOutput',0)';
                    end
                    obj.types = repmat({'Polygon'},obj.num_rois,1);
                    obj.x0 = cell(obj.num_rois,1);
                    obj.y0 = cell(obj.num_rois,1);
                    obj.x = cell(obj.num_rois,1);
                    obj.y = cell(obj.num_rois,1);
                    for i = 1:obj.num_rois
                        % format: [x,y] Npoints x 2 array of polygon boundary
                        obj.x0{i} = file_or_roi_array{i}(:,1);
                        obj.x{i} = file_or_roi_array{i}(:,1);
                        obj.y0{i} = file_or_roi_array{i}(:,2);
                        obj.y{i} = file_or_roi_array{i}(:,2);
%                         if length(file_or_roi_array{i}) == 3 % Circle
%                             % format: [center x, center y, radius]
%                             obj.x0 = file_or_roi_array{i}(1);
%                             obj.x = obj.x0;
%                             obj.y0 = file_or_roi_array{i}(1);
%                             obj.y = obj.y0;
%                             obj.radius = file_or_roi_array{i}(3);  
%                             obj.types{i} = 'Circle';
%                         elseif length(file_or_roi_array{i}) == 4 % Rectangle
%                             % format: [min row, max row, min column, max column]
%                             obj.r0 = file_or_roi_array{i};
%                             obj.r = obj.r0;
%                             obj.types{i} = 'Rectangle';
%                         end
                    end
                else % ROIs of single type defined with array
                    obj.num_rois = size(file_or_roi_array,1);  
                    if isempty(in.names)
                       obj.names = arrayfun(@(x) sprintf('ROI%g',x),0:obj.num_rois-1,...
                                            'UniformOutput',0)';
                    end
                    if size(file_or_roi_array,2) == 3 % Circle
                        % format: [center x, center y, radius]
                        obj.x0 = file_or_roi_array(:,1);
                        obj.x = obj.x0;
                        obj.y0 = file_or_roi_array(:,2);
                        obj.y = obj.y0;
                        obj.radius = file_or_roi_array(:,3);                        
                        obj.types = repmat({'Circle'},obj.num_rois,1);
                    elseif size(file_or_roi_array,2) == 4 % Rectangle
                        % format: [min row, max row, min column, max column]
                        obj.r0 = file_or_roi_array;
                        obj.r = obj.r0;
                        obj.types = repmat({'Rectangle'},obj.num_rois,1);
                    end
                end
                obj.loaded = false;
            end             
        end
        function processROIs(obj,ROIarray)
            % Process ImageJ ROI array output by ReadImageJROI.m function
            % to easier to work with format 
            if obj.num_rois == 1
                ROIarray = {ROIarray};
            end
            roi_names = cellfun(@(x) x.strName,ROIarray,'UniformOutput',0)';      
            [obj.names,sorted_inds] = sort(roi_names); %#ok<TRSRT>
            ROIarray = ROIarray(sorted_inds); 
            obj.types = cellfun(@(x) x.strType,ROIarray,'UniformOutput',0);                     
            if all(strcmp(obj.types,obj.types{1})) % All ROIs have same shape
                % format of vnRectBounds ['nTop', 'nLeft', 'nBottom', 'nRight']                
                if strcmp(obj.types{1},'Oval') % assume circle
                    obj.radius = cellfun(@(x) (x.vnRectBounds(4) - x.vnRectBounds(2))/2,...
                                        ROIarray,'UniformOutput',1)';
                    obj.x0 = cellfun(@(x,r) floor(x.vnRectBounds(2) + r + 1),...
                                        ROIarray,num2cell(obj.radius)','UniformOutput',1)'; % get middle pixel row and column
                    obj.y0 = cellfun(@(x,r) floor(x.vnRectBounds(3) - r + 1),...
                                        ROIarray,num2cell(obj.radius)','UniformOutput',1)'; % imagej is 0 indexed, add 1                                        
                    obj.x = obj.x0; % current is same as original initially
                    obj.y = obj.y0; % current is same as original initially                    
                elseif strcmp(obj.types{1},'Rectangle')
                    % TODO: finish
                    % format: r = [min row, max row, min column, max column]
                    obj.r0 = nan(length(ROIarray),4);
                    obj.r = nan(length(ROIarray),4);
                    for i = 1:length(ROIarray)
                        obj.r0(i,:) = ROIarray{i}.vnRectBounds([1 3 2 4]);
                        obj.r(i,:) = obj.r0(i,:);
                    end
                elseif strcmp(obj.types{1},'Polygon')
                    obj.x0 = cellfun(@(x) [x.mnCoordinates(:,1);x.mnCoordinates(1,1)],... % add first point to end
                                     ROIarray,'UniformOutput',0); % x coords
                    obj.y0 = cellfun(@(x) [x.mnCoordinates(:,2);x.mnCoordinates(1,2)],...
                                     ROIarray,'UniformOutput',0); % y coords
                    obj.x = obj.x0; % current is same as original initially
                    obj.y = obj.y0; % current is same as original initially           
                else
                    error('Other shapes not implemented');
                end
            else % ROIs have different shapes, process individually
                error('Non-uniform shape ROIarray not implemented')
            end
        end
        function shift_dists = recenterROIs(obj,vals,print_status)
            %   Inputs 
            %   ------ 
            %   obj : instance of ROIs class
            %   img : M x N image matrix
            %         Image to use to recenter ROIs
            %   print_status : integer
            %                   set to 0 for no output, 1 to print
            %                   distances shifted for all ROIs
            if nargin < 3
               print_status = 0;  
            end                        
            x_new = zeros(obj.num_rois,1); y_new = zeros(obj.num_rois,1);
            for i = 1:obj.num_rois                
                mask = getMask(obj,size(vals,[1 2]),i); % single mask for all ROIs
                mask_inds = find(mask==1);
                [~,max_ind] = max(vals(mask_inds));
                max_ind = mask_inds(max_ind);
                [y_new(i),x_new(i)] = ind2sub(size(mask),max_ind);
            end            
            shift_dists = sqrt((x_new-obj.x).^2 + (y_new-obj.y).^2);
            if print_status > 0
                fprintf('ROI shift distances:\n');
                for i = 1:obj.num_rois
                    fprintf('%s: %g pixels\n',obj.names{i},...
                        shift_dists(i));
                end
            end
            obj.x = x_new;
            obj.y = y_new;
        end
        function shift_dists = recenterROIsLoop(obj,vals,mean_shift_threshold,print_status)
           if nargin < 4
              print_status = 0; 
           end
            if nargin < 3
              mean_shift_threshold = 0; % keep recentering until mean shift is <= this value
           end
           shift_dists = mean_shift_threshold*ones(obj.num_rois,1)+1;            
           num_shifts = 0;
           while mean(shift_dists) > mean_shift_threshold
              shift_dists = obj.recenterROIs(vals,print_status-1); 
              num_shifts = num_shifts + 1; 
           end
           if print_status > 0
               fprintf('After %g shifts, final mean shift = %.2g pixels\n',num_shifts,mean(shift_dists));
           end
        end
        function [mask,mask_rows,mask_cols] = getMask(obj,imsize,roi_inds)
            %GETMASK Outputs composite mask for all input  ROIs
            %
            %   Inputs
            %   ------
            %   imsize : [rows columns]
            %            Image dimensions, should be 2D (first 2 dimensions
            %            for 3D image stack/movie)
            %   Optional Inputs
            %   ---------------
            %   Outputs
            %   -------
            %   Examples
            %   ---------------
            
            % AUTHOR    : Aman Aberra
            % Get masks
            % ImageJ includes pixels in which *center* of pixel falls within ROI
            % Ex: for 5 x 5 circle (radius = 2.5), area should = 21 (4
            % corners from square circumscribing circle are excluded)
            if nargin < 3
               roi_inds = 1:obj.num_rois; 
            end
            if all(strcmp(obj.types,'Circle')) || all(strcmp(obj.types,'Oval'))
                xi = obj.x(roi_inds); yi = obj.y(roi_inds); radiusi = obj.radius(roi_inds);
                [X,Y] = meshgrid(1:imsize(2)+0.5,1:imsize(1)+0.5); % shift to middle of pixels, change to 1 index
                xyr = permute([xi,yi,radiusi],[3,2,1]); % transpose to put different ROIs in 3rd dimension
                mask_log = any(hypot(X - xyr(1, 1, :), Y - xyr(1, 2, :)) <= xyr(1, 3, :), 3);
                mask = nan(imsize); 
                mask(mask_log) = 1; 
            elseif all(strcmp(obj.types,'Rectangle'))
                % format: r = [min row, max row, min column, max column]        
                mask = nan(imsize);
                if iscell(obj.r)
                    tic
                    for i = 1:length(roi_inds)
%                        min_rowi = obj.r{i}(1); max_rowi = obj.r{i}(2);
%                        min_coli = obj.r{i}(3); max_coli = obj.r{i}(4); 
                       min_rowi = obj.r(roi_inds(i),1); max_rowi = obj.r(roi_inds(i),2);
                       min_coli = obj.r(roi_inds(i),3); max_coli = obj.r(roi_inds(i),4); 
                       mask(min_rowi:max_rowi,min_coli:max_coli) = 1; % include pixels within ith roi 
                    end
                    toc
                else
                    for i = 1:length(roi_inds)
                       min_rowi = obj.r(roi_inds(i),1); max_rowi = obj.r(roi_inds(i),2);
                       min_coli = obj.r(roi_inds(i),3); max_coli = obj.r(roi_inds(i),4); 
                       mask(min_rowi:max_rowi,min_coli:max_coli) = 1; % include pixels within ith roi 
                    end
                    % slower method?
%                     ri = permute(obj.r(roi_inds,:),[3,2,1]); % transpose to put different ROIs in 3rd dimension
%                     [X,Y] = meshgrid(1:imsize(2)+0.5,1:imsize(1)+0.5); % shift to middle of pixels, change to 1 index                    
%                     mask = any(X >= ri(1,3,:) & X <= ri(1,4,:) & ...
%                                Y >= ri(1,1,:) & Y <= ri(1,2,:), 3);                
%                                       
                end  
            elseif all(strcmp(obj.types,'Polygon'))
                mask = nan(imsize);
               [xgrid, ygrid] = meshgrid(1:imsize(2), 1:imsize(1));
                for i = 1:length(roi_inds)
                   xvi = obj.x{roi_inds(i)};
                   yvi = obj.y{roi_inds(i)}; 
                   maski = inpolygon(xgrid,ygrid,xvi,yvi); 
                   mask(maski) = 1; 
                end
            else
                error('getMask not implemented yet for non-uniform ROI arrays'); 
            end            
            mask_inds = find(mask==1);
            [mask_rows,mask_cols] = ind2sub(size(mask),mask_inds);
        end
        
        function plot(obj,col,ax,plot_current,show_labels,num_pts) 
            % plot current ROIs to axis ax with num_pts points in each curve
            if nargin < 6
                num_pts = 30;
            end
            if nargin < 5
               show_labels = 0;  
            end
            if nargin < 4
               plot_current = 1; % 1 for current, 0 for starting ROI positions
            end
            if nargin < 3                
%                 figure;
                ax = gca; % make new axis
            end
            if nargin < 2
                col = 'y';
            end
            theta = linspace(0,2*pi,num_pts);
            hold(ax,'on'); % add to ax            
            for i = 1:obj.num_rois
                if strcmp(obj.types{i},'Oval') || strcmp(obj.types{i},'Circle')
                    if plot_current
                        xi = obj.x(i); yi = obj.y(i);
                    else
                        xi = obj.x0(i); yi = obj.y0(i);
                    end
                    x_ptsi = obj.radius(i)*cos(theta) + xi;
                    y_ptsi = obj.radius(i)*sin(theta) + yi;
                elseif strcmp(obj.types{i},'Rectangle')
                    if plot_current
                        ri = obj.r(i,:);                        
                    else
                        ri = obj.r0(i,:); 
                    end
                    x_ptsi = [ri(3),ri(3),ri(4),ri(4),ri(3)];
                    y_ptsi = [ri(1),ri(2),ri(2),ri(1),ri(1)];
                    xi = mean(x_ptsi); yi = mean(y_ptsi); % for label below
                elseif strcmp(obj.types{i},'Polygon')
                    if plot_current
                       x_ptsi = obj.x{i}; y_ptsi = obj.y{i}; 
                    else
                       x_ptsi = obj.x0{i}; y_ptsi = obj.y0{i}; 
                    end
                    xi = mean(x_ptsi); yi = mean(y_ptsi); % for label below
                end
                if isnumeric(col) && size(col,1) == obj.num_rois && size(col,2) == 3
                    coli = col(i,:);
                else
                    coli = col; 
                end
                plot(ax,x_ptsi,y_ptsi,'-','Color',coli); hold(ax,'on'); 
                if show_labels
%                     namei = obj.names{i}; 
%                     if strncmp(namei,'ROI',3)
%                        namei = namei(4:end); % remove 'ROI' to save space                     
%                     end
                    namei = num2str(i,'%g'); 
                    text(ax,xi*1.025,yi,namei,'FontName','Arial','FontSize',12,...
                          'Color',coli); 
                end
            end
        end
        function invert_y(obj,imsize)
        % Invert y coordinate of ROIs based on size of source image
        % imsize : vector containing [height, width, time_points]
            if strcmp(obj.types{1},'Polygon')
                obj.y0 = cellfun(@(x) imsize(1) - x,obj.y0,'UniformOutput',0);
                obj.y = cellfun(@(x) imsize(1) - x,obj.y,'UniformOutput',0);
            elseif strcmp(obj.types{1},'Oval')
                obj.y0 = imsize(1) - obj.y0;
                obj.y = imsize(1) - obj.y;
            elseif strcmp(obj.types{1},'Rectangle')
                obj.r0(1:2) = imsize(1) - obj.r0(1:2);
                obj.r(1:2) = imsize(1) - obj.r(1:2);
            end
            fprintf('Flipping y coordinate of imported ROIs, check!!\n');
            obj.y_inverted = true;
        end
        function shift(obj,shift_vec)
        % shift_vec : [shift_x shift_y] (in pixels) applied to all ROIs
        % if 1x2, applies same shift to all ROIs, if num_rois x 2, can apply
        % different shift to all ROIs
            if iscell(obj.x)
                for i = 1:size(shift_vec,1)
                    obj.x{i} = obj.x{i} + shift_vec(i,1);
                    obj.y{i} = obj.y{i} + shift_vec(i,1);
                end
            else
                obj.x = obj.x + shift_vec(:,1); 
                obj.y = obj.y + shift_vec(:,2); 
            end
        end
        function affine2d(obj,T)
        % Apply forward affine transformation using 3x3 matrix T, convention 
        % given in affine2d.m documentation: [x y 1] = [u v 1] * T, with
        % T given by [a b 0; c d 0; e f 1]; 
        r_new = [obj.x, obj.y, ones(obj.num_rois,1)] * T;
        obj.x = r_new(:,1); 
        obj.y = r_new(:,2); 
        end
        function removeROIs(obj,roi_inds)            
            if all(strcmp(obj.types,'Oval'))
                obj.x0(roi_inds) = []; 
                obj.y0(roi_inds) = []; 
                obj.x(roi_inds) = []; 
                obj.y(roi_inds) = []; 
                obj.names(roi_inds) = [];  
                obj.types(roi_inds) = []; 
                obj.num_rois = size(obj.x,1); 
            else
                error('Not implemented yet for shapes other than Oval')
            end
        end
        function num_pixels = getNumPixels(obj,imsize,roi_inds)
            if nargin < 3
                roi_inds = 1:obj.num_rois;
            end
            num_pixels = zeros(length(roi_inds),1);
            for i = 1:length(roi_inds)
                mask = getMask(obj,imsize(1:2),roi_inds(i));
                num_pixels(i) = sum(mask == 1,'all'); % get number of pixels in this ROI
            end
        end
    end    
end