classdef Recording < matlab.mixin.Copyable % Stack of images from recording 
    properties        
        data_fold char {mustBeTextScalar}
        exp_date char {mustBeTextScalar} % YYYYMMDD format 
        reporter char {mustBeTextScalar}
        dish char {mustBeTextScalar}
        condition char {mustBeTextScalar}
        position char {mustBeTextScalar} % name of position (TODO: make class, load from micromanager)
        img_name char {mustBeTextScalar} % file name
        filedir char {mustBeTextScalar} % full path to directory containing file
        filepath char {mustBeTextScalar} % full path to file
        format char {mustBeTextScalar}    % image file format
        time_start
        loaded = false 
        imsize % [rows x columns x time points]
    end
    properties (SetAccess = private)
       vals % make sure raw data isn't altered after being loaded
    end
    methods
        function obj = Recording(img_name,position,condition,dish,reporter,...
                                exp_date,data_fold,format)
            if nargin > 0
                obj.img_name = img_name;
                obj.position = position; 
                obj.condition = condition;
                obj.dish = dish;
                obj.reporter = reporter; 
                obj.exp_date = exp_date;                 
            end            
            if nargin > 7
                obj.data_fold = data_fold;
            else
                obj.data_fold = pwd; % assume current directory is root
            end
            if nargin > 8
               obj.format = format;
            else
               split_obj_name = strsplit(img_name,'.'); 
               if length(split_obj_name) == 1
                   error('Must include file format in img_name or as input argument'); 
               else
                   obj.format = split_obj_name{2};
               end
            end
            obj.filedir = fullfile(data_fold,exp_date,reporter,dish,...
                                    condition);            
            obj.filepath = fullfile(obj.filedir,img_name); 
            d = dir(obj.filepath);             
            [Y, M, D, H, MI, S] = datevec(d.datenum); % file creation time to sec precision
            obj.time_start = datetime(Y,M,D,H,MI,S);
        end
        function load(obj,print_status)
            if nargin < 2
               print_status = 1; 
            end
            if strcmp(obj.format,'fits')
                obj.vals = fitsread(obj.filepath); 
            else
               error('Other file formats not implemented yet');  
            end
            obj.loaded = true; 
            obj.imsize = size(obj.vals);             
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