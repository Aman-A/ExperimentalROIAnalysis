classdef circROIs < handle % Set of circular ROIs
    properties
        x0 % original center x's
        y0 % original center y's
        x % current center x's
        y % current center y's
        radius % radius in pixels        
        names % names from ImageJ
        num_rois % number of rois
        roi_set_filename char {mustBeTextScalar} % file name
        roi_set_filedir char {mustBeTextScalar} % directory
        roi_set_filepath char {mustBeTextScalar} % full path
        loaded = false 
    end
    methods
        function obj = circROIs(roi_set_filename,roi_set_filedir,print_status)
            if nargin < 3                
               print_status = 1; 
            end
            if nargin > 1
                obj.roi_set_filedir = roi_set_filedir;
            else
                obj.roi_set_filepath = pwd; % assume in current directory
            end
            if nargin > 0
                split_roi_set_filename = strsplit(roi_set_filename,'.'); 
                if length(split_roi_set_filename) == 1
                    obj.roi_set_filename = [roi_set_filename '.zip']; % add file extension (assume zip) 
                else
                    obj.roi_set_filename = roi_set_filename; 
                end                
                obj.roi_set_filepath = fullfile(obj.roi_set_filedir,obj.roi_set_filename);
                ROIarray = ReadImageJROI(obj.roi_set_filepath); % load .zip ROI set
                obj.num_rois = length(ROIarray); 
                obj.loaded = true;
                if print_status > 0
                    fprintf('Loaded %g ROIs from %s\n',obj.num_rois,obj.roi_set_filepath); 
                end
            else
                obj.loaded = false;
            end            
           
            if obj.loaded
                obj.processROIs(ROIarray); 
            end
        end
        function processROIs(obj,ROIarray)
            roi_types = cellfun(@(x) x.strType,ROIarray,'UniformOutput',0);                        
            if all(strcmp(roi_types,roi_types{1})) % All ROIs have same shape
                % format of vnRectBounds ['nTop', 'nLeft', 'nBottom', 'nRight']
                if strcmp(roi_types{1},'Oval') % assume circle
                    obj.radius = cellfun(@(x) (x.vnRectBounds(4) - x.vnRectBounds(2))/2,...
                                        ROIarray,'UniformOutput',1)';
                    obj.x0 = cellfun(@(x,r) floor(x.vnRectBounds(2) + r + 1),...
                                        ROIarray,num2cell(obj.radius)','UniformOutput',1)'; % get middle pixel row and column
                    obj.y0 = cellfun(@(x,r) floor(x.vnRectBounds(3) - r + 1),...
                                        ROIarray,num2cell(obj.radius)','UniformOutput',1)'; % imagej is 0 indexed, add 1                    
                    obj.x = obj.x0; % current is same as original initially
                    obj.y = obj.y0; % current is same as original initially
                    obj.names = cellfun(@(x) x.strName,ROIarray,'UniformOutput',0);
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
            %   obj : instance of circROIs class
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
                mask = getMask(obj,i,size(vals,[1 2])); % single mask for all ROIs
                mask_inds = find(mask);
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
        function mask = getMask(obj,roi_inds,imsize)
            %GETMASK Outputs composite mask for all input circular ROIs
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
            % Get masks
            % ImageJ includes pixels in which *center* of pixel falls within ROI
            % Ex: for 5 x 5 circle (radius = 2.5), area should = 21 (4
            % corners from square circumscribing circle are excluded)
            xi = obj.x(roi_inds); yi = obj.y(roi_inds); radiusi = obj.radius(roi_inds);
            [X,Y] = meshgrid(1:imsize(2)+0.5,1:imsize(1)+0.5); % shift to middle of pixels, change to 1 index
            xyr = permute([xi,yi,radiusi],[3,2,1]); % transpose to put different ROIs in 3rd dimension
            mask = any(hypot(X - xyr(1, 1, :), Y - xyr(1, 2, :)) <= xyr(1, 3, :), 3);
        end
        function plot(obj,col,ax,plot_current,num_pts) % plot current ROIs to axis ax 
                                          % with num_pts points in each
                                          % curve
            if nargin < 5
                num_pts = 30;
            end
            if nargin < 4
               plot_current = 1; % 1 for current, 0 for starting ROI positions
            end
            if nargin < 3                
                figure;
                ax = gca; % make new axis
            end
            if nargin < 2
                col = 'y';
            end
            theta = linspace(0,2*pi,num_pts);
            hold on; % add to ax
            for i = 1:obj.num_rois
                if plot_current
                    xi = obj.x(i); yi = obj.y(i);
                else
                    xi = obj.x0(i); yi = obj.y0(i);
                end
                plot(ax,obj.radius(i)*cos(theta) + xi,...
                    obj.radius(i)*sin(theta) + yi,'-','Color',col)
            end
        end
    end
end