function runExperimentAnalysis(dataset_def_filename,conditions,...
                            roi_func_modes,exp_settings,plot_settings,varargin)
%RUNEXPERIMENTANALYSIS Runs analyis on experiments in multiple dishes,
%defined in a dataset definition file, wrapper function for
%reporter-specific functions
%  
%   Inputs 
%   ------ 
%   dataset_def_filename : char
%                          path to Dataset definition file
%   roi_func_modes : char or cell
%                   single or list of roi_func_modes ('separate' or
%                   'combine')
%   exp_settings: ExperimentSettings object or cell array
%                 instance of ExperimentalSettings object containing
%                 parameters for experimental recording, stimulation times, 
%                 and desired baseline window, or cell array of separate
%                 ExperimentSettings objects for each dish within dataset
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
%   To do:
%   --------------- 
%   Write runGEVIExperimentAnalysis function

% AUTHOR    : Aman Aberra 
def = loadDatasetDefinition(dataset_def_filename);
if all(strcmp(def.reporter,'GluSnFR3'))
    runGluSnFR3ExperimentAnalysis(def,conditions,roi_func_modes,...
                                exp_settings,plot_settings,varargin{:});
elseif all(strcmp(def.reporter,'Archon'))
    runArchonExperimentAnalysis(def,conditions,roi_func_modes,...
                                exp_settings,plot_settings,varargin{:});
elseif all(strcmp(def.reporter,'Archon_LGI1pHmScarlet'))
    runArchonLGI1pHmScarletExperimentAnalysis(def,conditions,roi_func_modes,...
                                exp_settings,plot_settings,varargin{:});
else
    error('Not implemented for input reporter: %s',def.reporter{1});
end