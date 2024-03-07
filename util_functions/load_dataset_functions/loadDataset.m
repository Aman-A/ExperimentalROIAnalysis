function [data,def,varargout] = loadDataset(dataset_def_filename,reporter,...
                                           roi_func_mode,mode_str,varargin)
%LOADDATASET Compiles data from multiple dishes defined in dataset
%definition file and loads, helper function for reporter specific
%functions
%  
%   Inputs 
%   ------ 
%   dataset_def_filename : char
%                          path to Dataset definition file
%   roi_func_mode : char/string
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
if nargin < 3 || isempty(mode_str)
   mode_str = 'default';
end
% def = loadDatasetDefinition(dataset_def_filename);
if ~isempty(regexp(reporter,'GluSnFR3','ONCE')) || ~isempty(regexp(reporter,'GCaMP','ONCE')) ...
        || ~isempty(regexp(reporter,'vGlut-pHluorin','ONCE'))
    [data,def,extra_data] = loadDefaultDataset(dataset_def_filename,...
                                                   roi_func_mode,varargin{:});
    varargout = extra_data;    
elseif ~isempty(regexp(reporter,'Archon','ONCE'))
    if strcmp(reporter,'Archon') && strcmp(mode_str,'default')
        [data,def,extra_data] = loadDefaultDataset(dataset_def_filename,...
                                                   roi_func_mode,varargin{:});
        varargout = extra_data;
    else % for paired pulse experiments with or without LGIphmScarlet indicator
        [data,def,AP_data,lgi1_data] = loadArchonLGI1pHmScarletDataset(dataset_def_filename,...
                                                       roi_func_mode,varargin{:});
        varargout = {AP_data,lgi1_data};
    end
% elseif ~isempty(regexp(reporter,'GCaMP','ONCE'))
%     [data,def,norm_data,train_data] = loadDefaultDataset(dataset_def_filename,...
%                                                    roi_func_mode,varargin{:});
%     varargout = {norm_data,train_data};
else
    error('Not implemented for input reporter: %s',reporter);
end