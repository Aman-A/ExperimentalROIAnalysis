function [data,def,varargout] = loadDataset(dataset_def_filename,...
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
def = loadDatasetDefinition(dataset_def_filename);
if all(strcmp(def.reporter,'GluSnFR3'))
    [data,~,norm_data,train_data] = loadDefaultDataset(dataset_def_filename,...
                                                   roi_func_mode,varargin{:});
    varargout = {norm_data,train_data};    
elseif ~isempty(regexp(def.reporter{1},'Archon','ONCE'))
    if all(strcmp(def.reporter,'Archon')) && strcmp(mode_str,'default')
        [data,~,norm_data,train_data] = loadDefaultDataset(dataset_def_filename,...
                                                   roi_func_mode,varargin{:});
        varargout = {norm_data,train_data};
    else % for paired pulse experiments with or without LGIphmScarlet indicator
        [data,~,AP_data,lgi1_data] = loadArchonLGI1pHmScarletDataset(dataset_def_filename,...
                                                       roi_func_mode,varargin{:});
        varargout = {AP_data,lgi1_data};
    end
else
    error('Not implemented for input reporter: %s',def.reporter{1});
end