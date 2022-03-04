function dataset_def = loadDatasetDefinition(dataset_filename)
%LOADDATASETDEFINITIONFILE Load dataset definition from definition file 
%  
%   Inputs 
%   ------ 
%   dataset_filename : string
%                    full path to dataset definition file 
%   xlsx or csv file, following format headers required:
%   exp_date, reporter, dish, roiset_filename, transform_type, 
%    registration_rec
%   Optional headers:
%    norm_suffix, train_suffix, Notes
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   dataset_def : table
%      outputs dataset definition csv file as a table
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
[~,~,ext] = fileparts(dataset_filename);
req_vars = {'exp_date','reporter','dish','roiset_filename'};
if strcmp(ext,'.csv') || strcmp(ext,'.xlsx') || isempty(ext) % assume csv if empty
%     dataset_def = readmatrix(dataset_filename,'NumHeaderLines',1,'OutputType','char');
    opts = detectImportOptions(dataset_filename);
    opts = setvartype(opts, 'char'); % import all as chars 
    dataset_def = readtable(dataset_filename,opts);
    assert(isempty(setdiff(req_vars,dataset_def.Properties.VariableNames)),...
          [sprintf('Dataset definition is required to have following headers:\n'),...
             sprintf('%s\n',req_vars{:})])
    % Format:
    % exp_date, reporter,
    % dish,roiset_filename,(transform_type,registration_rec,...)
else
    error('Format %s not implemented yet\n',ext);
end