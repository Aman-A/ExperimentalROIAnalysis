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
        filedir char {mustBeTextScalar} % full path to directory containing file
        img_name % file name
        n_files uint16 {mustBeNumeric} % number of files, allows for multi-file recording
        filepath % full path to file
        format char {mustBeTextScalar}    % image file format
        pixel_size = 0.4; % size of individual pixel in µm (for scale bar) 
                          % default for Andor iXon Ultra 897 (Thor)
        bin_size = 1; % pixel binning (must be symmetric, i.e. 1x1, 2x2, etc.)
        exposure_time = []; % sec, extract from fits file metadata
        em_gain = []; % for EMCCD camera, extract from fits file metadata
        time_start
        loaded = false 
        imsize = [0 0 0]; % [rows x columns x time points]
        vals = []; % make sure raw data isn't altered after being loaded
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
                parseFileNames(obj,img_name,in);                
            end
        end
        function parseFileNames(obj,img_name,in)
            if ischar(img_name)
                img_name = {img_name};                           
            end
            obj.n_files = length(img_name);
            obj.img_name = cell(obj.n_files,1);
            obj.filepath = cell(obj.n_files,1);
            obj.time_start = cell(obj.n_files,1);
            for i = 1:obj.n_files
                [path_to_img,name,ext] = fileparts(img_name{i});
                if i == 1 % directory and format for multi-file recording 
                          % required to be the same for all files
                    % Get filedir
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
                end
                obj.img_name{i} = name;                
                % Build full path to file
                obj.filepath{i} = fullfile(obj.filedir,[obj.img_name{i},obj.format]);            
                if exist(obj.filepath{i},'file')
                    d = dir(obj.filepath{i});
                    [Y, M, D, H, MI, S] = datevec(d.datenum); % file creation time to sec precision
                    obj.time_start{i} = datetime(Y,M,D,H,MI,S);
                else
                    error('%s does not exist\n',obj.filepath{i});
                end
            end
            if strcmp(obj.format,'.fits')
                getFitsInfo(obj);
            elseif strcmp(obj.format,'.tiff') || strcmp(obj.format,'.tif')
                getTiffInfo(obj);
            else
                error('''%s'' file format currently not supported',obj.format)
            end
%             if obj.n_files == 1 % convert to char strings
%                 obj.img_name = obj.img_name{1}; 
%                 obj.filepath = obj.filepath{1}; 
%             end
        end
        function load(obj,file_inds,print_status)
            if nargin < 2
                file_inds = 1:obj.n_files; 
            end
            if nargin < 3
               print_status = 1; 
            end            
            obj.vals = [];
            current_frames = 0; 
            for i = file_inds
                if strcmp(obj.format,'.fits')
                    if exist(obj.filepath{i},'file')
                        obj.vals = cat(3,obj.vals,fitsread(obj.filepath{i})); 
                    else % try getting local data_fold and reconstruct path
                        data_fold_loc = getDataFold(); 
                        filedir_loc = fullfile(data_fold_loc,obj.exp_date,obj.reporter,...
                                            obj.dish,obj.condition);
                        filepath_loc = fullfile(filedir_loc,[obj.img_name{i},obj.format]);
                        if exist(filepath_loc,'file')
                            obj.data_fold = data_fold_loc;
                            obj.filedir = filedir_loc;
                            obj.filepath{i} = filepath_loc; 
                        end  
                        obj.vals = cat(3,obj.vals,fitsread(obj.filepath{i})); % now try loading again
                    end             
                elseif strcmp(obj.format,'.tiff') || strcmp(obj.format,'.tif')   
                      obj.vals = cat(3,obj.vals,single(tiffreadVolume(obj.filepath{i}))); % 8.6 sec (ssd), 35.5 sec (hd)
                else
                   error('Other file formats not implemented yet');  
                end
                if print_status > 0
                    fprintf('Loaded %g x %g x %g image stack from %s\n',...
                        size(obj.vals,[1 2]),size(obj.vals,3)-current_frames,obj.filepath{i});
                end
                current_frames = size(obj.vals);
            end
            obj.loaded = true;             
        end
        function obj_unloaded = unload(obj,print_status)
            if nargin < 2
               print_status = 1; 
            end
            if nargout == 1 % output instance without data values
                obj_unloaded = copy(obj);
                obj_unloaded.vals = []; 
                obj_unloaded.loaded = false; 
            else % operate on current instance
                obj.vals = []; 
                obj.loaded = false;
            end            
            if print_status > 0
                fprintf('Unloaded image stack\n'); 
            end
        end
        function info = getFitsInfo(obj)            
            for i = 1:obj.n_files
                info = fitsinfo(obj.filepath{i});   
                obj.imsize(3) = obj.imsize(3) + info.PrimaryData.Size(3); 
                if i == 1
                    obj.imsize(1:2) = info.PrimaryData.Size(1:2); 
                    if any(strcmp('EXPOSURE',info.PrimaryData.Keywords(:,1)))
                        obj.exposure_time = ...
                            info.PrimaryData.Keywords{strcmp(info.PrimaryData.Keywords(:,1),'EXPOSURE'),2};
                    end
                    if any(strcmp('GAIN',info.PrimaryData.Keywords(:,1)))
                        obj.em_gain = ...
                            info.PrimaryData.Keywords{strcmp(info.PrimaryData.Keywords(:,1),'GAIN'),2};
                    end
                    if any(strcmp('HBIN',info.PrimaryData.Keywords(:,1)))
                        hbin = info.PrimaryData.Keywords{strcmp(info.PrimaryData.Keywords(:,1),'HBIN'),2};
                        vbin = info.PrimaryData.Keywords{strcmp(info.PrimaryData.Keywords(:,1),'VBIN'),2};
                        if hbin == vbin
                            obj.bin_size = hbin;
                        else
                            obj.bin_size = [hbin vbin]; % [horizontal bin size, vertical bin size]
                            fprintf('WARNING: Non-uniform pixel binning, currently not handled by other functions\n');
                        end
                    end
                end
            end
        end
        function info = getTiffInfo(obj)           
            for i = 1:obj.n_files
                info = imfinfo(obj.filepath{i});
                obj.imsize(3) = obj.imsize(3) + length(info);
                if i == 1
                    obj.imsize(1:2) = [info(1).Height,info(1).Width];
                    img_desc = info.ImageDescription; 
                    [~,exp_ind] = regexp(img_desc,'Exposure1 = ','ONCE');
                    s_ind = regexp(img_desc(exp_ind:end),'s');
                    if ~isempty(exp_ind) % get exposure time for HCImage multi-page tiff 
                        obj.exposure_time = str2double(img_desc(exp_ind+1:exp_ind+s_ind-3));
                    end
                    [~,pixel_size_ind] = regexp(img_desc,'factor = ','ONCE'); 
                    if ~isempty(pixel_size_ind)
                        [~,end_ind] = regexp(img_desc(pixel_size_ind:end),'\n','ONCE');
                        obj.pixel_size = str2double(img_desc(pixel_size_ind+1:pixel_size_ind+end_ind-3));
                    end
                end
            end
        end
        function plot(obj,frame)
            if nargin < 2
                frame = 1; % frame index to plot (3rd dimension/time)
            end
            if ~obj.loaded
                obj.load(); 
            end
            imagesc(obj.vals(:,:,frame)); 
            colorbar; 
            axis equal; axis tight; axis off; 
            set(gca,'YDir','normal')
        end
    end    
end