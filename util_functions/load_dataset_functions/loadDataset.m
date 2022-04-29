function [data,def,varargout] = loadDataset(dataset_def_filename,...
                                           roi_func_mode,varargin)
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
def = loadDatasetDefinition(dataset_def_filename);
if all(strcmp(def.reporter,'GluSnFR3'))
    [data,~,norm_data,train_data] = loadDefaultDataset(dataset_def_filename,...
                                                   roi_func_mode,varargin{:});
    varargout = {norm_data,train_data};
elseif all(strcmp(def.reporter,'Archon'))
    [data,~,norm_data,train_data] = loadDefaultDataset(dataset_def_filename,...
                                                   roi_func_mode,varargin{:});
    varargout = {norm_data,train_data};
elseif all(strcmp(def.reporter,'Archon_LGI1pHmScarlet'))
    [data,~,AP_data,lgi1_data] = loadArchonLGI1pHmScarletDataset(dataset_def_filename,...
                                                   roi_func_mode,varargin{:});
    varargout = {AP_data,lgi1_data};
else
    error('Not implemented for input reporter: %s',def.reporter{1});
end