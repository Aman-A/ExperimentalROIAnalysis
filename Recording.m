classdef Recording < matlab.mixin.Copyable % Stack of images from recording 
    properties        
        data_fold char {mustBeTextScalar} % top level folder where data folder is stored
        exp_date char {mustBeTextScalar} % YYYYMMDD format 
        reporter char {mustBeTextScalar} % reporter name
        dish char {mustBeTextScalar} % dish name 
        div uint16 {mustBeNumeric} % days in vitro (DIV)
        microscope char {mustBeTextScalar} % name of microscope used (e.g. 'Thor', 'Loki', etc.)
        condition char {mustBeTextScalar}
        position char {mustBeTextScalar} % name of position (TODO: make class, load from micromanager)
        img_name char {mustBeTextScalar} % file name
        filedir char {mustBeTextScalar} % full path to directory containing file
        filepath char {mustBeTextScalar} % full path to file
        format char {mustBeTextScalar}    % image file format
        pixel_size = 0.4; % size of individual pixel in µm (for scale bar) 
                          % default for Andor iXon Ultra 897 (Thor)
        bin_size = 1; % pixel binning (must be symmetric, i.e. 1x1, 2x2, etc.)
        exposure_time = []; % sec, extract from fits file metadata
        em_gain = []; % for EMCCD camera, extract from fits file metadata
        time_start
        loaded = false 
        imsize % [rows x columns x time points]
        vals % make sure raw data isn't altered after being loaded
    end
%     properties (SetAccess = private)
%        vals % make sure raw data isn't altered after being loaded
%     end
    methods
        function obj = Recording(img_name,varargin)
%             Recording(img_name,position,condition,dish,reporter,...
%                                 exp_date,data_fold,format)
            % Optional arguments to specify source of data and/or location
            % within default file structure            
            in.condition = '';
            in.dish = '';
            in.reporter = '';
            in.exp_date = '';
            in.div = '';
            in.data_fold = ''; % top level folder for experiment data, should follow
                               % a defined file_structure. 'default' is
                               % only one implemented currently. Leave
                               % empty if using absolute/relative path to
                               % specify file location within img_name
                               % string
            in.position = ''; 
            in.format = '';
            in.file_structure = 'default'; % <exp_date>/<reporter>/<dish>/<condition>
                                           % other structures not implemented
            in.pixel_size = obj.pixel_size;
            in.bin_size = obj.bin_size; 
            in = sl.in.processVarargin(in,varargin);       
            % Get object properties
            obj.exp_date = in.exp_date;
            obj.reporter = in.reporter;
            obj.dish = in.dish;
            obj.div = in.div;
            obj.condition = in.condition;            
            obj.data_fold = in.data_fold;
            obj.position = in.position; % (not used currently)
            obj.pixel_size = in.pixel_size; 
            obj.bin_size = in.bin_size; 
            % Check if file path is in img name
            if nargin > 0
                [path_to_img,name,ext] = fileparts(img_name); 
                if isempty(path_to_img)
                    if isempty(obj.data_fold) 
                        % No path in file name and no data_fold given, 
                        % assume file is in current directory
                        obj.filedir = pwd;
                    else
                        % Build directory path using experiment properties, 
                        % e.g. data_fold/exp_date/reporter/dish/condition
                        if strcmp(in.file_structure,'default')                        
                            assert(all([~isempty(obj.exp_date),~isempty(obj.reporter),...
                                        ~isempty(obj.dish),~isempty(obj.condition)]),...
                                        ['If specifying data_fold, need to input exp_date,',...
                                        'reporter, dish, and condition\n']);
                            obj.filedir = fullfile(obj.data_fold,obj.exp_date,...
                                                    obj.reporter,obj.dish,obj.condition);                                            
                        else
                            error('%s file_structure not implemented',in.file_structure);
                        end
                    end                
                else
                   % File name includes path, assume relative path to current
                   % directory
                   obj.filedir = path_to_img;               
                end
                obj.img_name = name;
                % Get file format
                if isempty(in.format)
                    if isempty(ext)                   
                       obj.format = '.fits'; % assume .fits
                    else
                        obj.format = ext;                    
                    end                
                else
                   obj.format = in.format; 
                end                        
                % Build full path to file
                obj.filepath = fullfile(obj.filedir,[obj.img_name,obj.format]); 
                if exist(obj.filepath,'file')
                    d = dir(obj.filepath);             
                    [Y, M, D, H, MI, S] = datevec(d.datenum); % file creation time to sec precision
                    obj.time_start = datetime(Y,M,D,H,MI,S);
                else
                   error('%s does not exist\n',obj.filepath);  
                end
            end
        end
        function load(obj,print_status)
            if nargin < 2
               print_status = 1; 
            end
            if strcmp(obj.format,'.fits')
                if exist(obj.filepath,'file')
                    obj.vals = fitsread(obj.filepath); 
                else % try getting local data_fold and reconstruct path
                    data_fold_loc = getDataFold(); 
                    filedir_loc = fullfile(data_fold_loc,obj.exp_date,obj.reporter,...
                                        obj.dish,obj.condition);
                    filepath_loc = fullfile(filedir_loc,[obj.img_name,obj.format]);
                    if exist(filepath_loc,'file')
                        obj.data_fold = data_fold_loc;
                        obj.filedir = filedir_loc;
                        obj.filepath = filepath_loc; 
                    end  
                    obj.vals = fitsread(obj.filepath); % now try loading again
                end
%                 if ispc
%                     obj.vals = flipud(obj.vals); 
%                     fprintf('Flipping y axis, check!!\n'); 
%                 end
                info = fitsinfo(obj.filepath); 
                obj.exposure_time = ...
                    info.PrimaryData.Keywords{strcmp(info.PrimaryData.Keywords(:,1),'EXPOSURE'),2};
                obj.em_gain = ...
                    info.PrimaryData.Keywords{strcmp(info.PrimaryData.Keywords(:,1),'GAIN'),2};
            elseif strcmp(obj.format,'.tiff') || strcmp(obj.format,'.tif')
                tiff_info = imfinfo(obj.filepath);
                obj.vals = zeros(tiff_info(1).Height,tiff_info(1).Width,length(tiff_info));
                for i = 1:size(obj.vals,3)
                    obj.vals(:,:,i) = imread(obj.filepath,'tiff',i);
                end
            else
               error('Other file formats not implemented yet');  
            end
            obj.loaded = true; 
            obj.imsize = size(obj.vals);            
            if length(obj.imsize) == 2
               obj.imsize = [obj.imsize 1];  
            end
            if print_status > 0                
                fprintf('Loaded %g x %g x %g image stack from %s\n',...
                         obj.imsize,obj.filepath); 
            end
        end
        function obj_unloaded = unload(obj,print_status)
            if nargin < 2
               print_status = 1; 
            end
            if nargout == 1 % output instance without data values
                obj_unloaded = copy(obj);
                obj_unloaded.vals = []; 
                obj_unloaded.loaded = 0; 
            else % operate on current instance
                obj.vals = []; 
            end
            obj.loaded = false;
            if print_status > 0
                fprintf('Unloaded image stack\n'); 
            end
        end
    end
    
end