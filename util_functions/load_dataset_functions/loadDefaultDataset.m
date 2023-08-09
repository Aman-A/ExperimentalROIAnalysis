function [data,def,extra_data] = loadDefaultDataset(dataset_def_filename,...
                                                   roi_func_mode,varargin)
%LOADDEFAULTDATASET Compiles data from multiple dishes defined in dataset
%definition file and loads
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

% AUTHOR    : Aman Aberra 
in.data_fold = getDataFold();
in.load_compiled_dataset = 1;
in.save_compiled_dataset = 1;
in.dataset_fold = './datasets';
in.summary_data_file_suffix = [];
in = sl.in.processVarargin(in,varargin);

[~,dataset_name,~] = fileparts(dataset_def_filename);
dataset_filepath = fullfile(in.dataset_fold,[dataset_name '.mat']); % save compiled dataset
if in.load_compiled_dataset && exist(dataset_filepath,'file')
    fprintf('Compiled dataset found, loading...\n');
    tic
    all_data = load(dataset_filepath);
    elapsed_time = toc; 
    data = all_data.data;
    def = all_data.def; 
    if isfield(all_data,'extra_data')
        extra_data = all_data.extra_data;
    else
        extra_data = {}; 
    end    
    fprintf('Loaded compiled dataset from %s in %.3f sec\n',dataset_filepath, elapsed_time);
else
    % Load processed data and compile
    def = loadDatasetDefinition(dataset_def_filename);
    % get data suffix names in alphabetical order
    suffixes = sort(def.Properties.VariableNames(~cellfun(@isempty,regexp(def.Properties.VariableNames,'suffix'),'UniformOutput',1)));
    suffixes(strcmp(suffixes,'data_suffix')) = []; % remove suffix of default data (loaded first below)

    num_dishes = size(def,1);
    data = cell(num_dishes,1);
    extra_data = repmat({cell(num_dishes,1)},1,length(suffixes)); % extra data files specified by <name>_suffix    
    tic; 
    num_loaded = 0;
    num_extra_loaded = zeros(1,length(suffixes));    
    for i = 1:num_dishes
        if any(strcmp(def.Properties.VariableNames,'data_fold'))
            data_fold = def.data_fold{i}; % allow for different data folders for each experiment
        else
            data_fold = in.data_fold;
        end
        exp_data_fold = fullfile(data_fold,def.exp_date{i},def.reporter{i},def.dish{i});
        roiset_filename_no_ext = getROIset_name(def.roiset_filename{i},...
                                                 def.transform_type{i},...
                                                  def.registration_rec{i});  
        summary_data_file = sprintf('%s_%s_%s_%s_%s',def.exp_date{i},def.reporter{i},def.dish{i},...
                                       roi_func_mode,roiset_filename_no_ext);
        if ~isempty(in.summary_data_file_suffix) % append suffix
            summary_data_file = [summary_data_file '_' in.summary_data_file_suffix];
        elseif any(strcmp(def.Properties.VariableNames,'data_suffix')) && ~isempty(def.data_suffix{i})             
            summary_data_file = [summary_data_file '_' def.data_suffix{i}];                    
        end
        summary_data_filepath = fullfile(exp_data_fold,[summary_data_file '.mat']);
        if exist(summary_data_filepath,'file')
            datai = load(summary_data_filepath);
            data{i} = datai;
            fprintf('Loaded %s (%g of %g)\n',summary_data_filepath,i,num_dishes);
            num_loaded = num_loaded + 1; 
            % Load extra data files, specified by <name>_suffix            
            for j = 1:length(suffixes)
                if ~isempty(def.(suffixes{j}){i})
                    data_name = suffixes{j}(1:regexp(suffixes{j},'_suffix')-1); % get name of data file alone                    
                    data_roiset_col_name = ['roiset_filename_' data_name];
                    transform_type_col_name = ['transform_type_' data_name];
                    registration_rec_col_name = ['registration_rec_' data_name];
                    if any(strcmp(def.Properties.VariableNames,data_roiset_col_name))
                        roiset_filename_ij = def.(data_roiset_col_name){i};
                        if any(strcmp(def.Properties.VariableNames,transform_type_col_name))
                            transform_type_ij = def.(transform_type_col_name){i};
                        else
                            transform_type_ij = '';
                        end
                        if any(strcmp(def.Properties.VariableNames,registration_rec_col_name))
                            registration_rec_ij = def.(registration_rec_col_name){i};
                        else
                            registration_rec_ij = '';
                        end
                        roiset_filename_no_ext = getROIset_name(roiset_filename_ij,...
                                                                  transform_type_ij,...
                                                                    registration_rec_ij);  
                        data_file = sprintf('%s_%s_%s_%s_%s_%s.mat',def.exp_date{i},def.reporter{i},def.dish{i},...
                                       roi_func_mode,roiset_filename_no_ext,def.(suffixes{j}){i});
                    else
                        data_file = [summary_data_file '_' def.(suffixes{j}){i} '.mat']; 
                    end
                    data_filepath = fullfile(exp_data_fold,data_file);
                    if exist(data_filepath,'file')
                        extra_data{j}{i} = load(data_filepath);
                        num_extra_loaded(j) = num_extra_loaded(j) + 1;
                        fprintf('   Loaded %s data: %s\n',suffixes{j},data_filepath)
                    else
                        fprintf('   !!%s data file not found: %s \n',suffixes{j},data_filepath)
                    end
                end
            end            
        else
            fprintf('%s does not exist, skipping...\n',summary_data_file);
        end
    end
    elapsed_time = toc; 
    if num_loaded > 0
        fprintf('Finished loading dataset: %s in %.2f sec\n',dataset_name,elapsed_time)
    else
        fprintf('No data was loaded\n')
    end
    for j = 1:length(suffixes)
        num_dataj = sum(~cellfun(@isempty,def.(suffixes{j}),'UniformOutput',1));
        if num_dataj > 0
            fprintf('   Loaded %g of %g %s extra datasets\n',...
                    num_extra_loaded(j),num_dataj,suffixes{j});
        end
    end   
    % Save compiled dataset to .mat file
    if in.save_compiled_dataset && num_loaded > 0
        if ~exist(in.dataset_fold,'dir')
            mkdir(in.dataset_fold);
        end
        save_data = struct(); 
        save_data.def = def; 
        save_data.data = data;
        save_data.extra_data = extra_data; 
        save_data.suffixes = suffixes;
        fprintf('Saving...\n')
        save(dataset_filepath,'-STRUCT','save_data');
        fprintf('Saved compiled dataset to %s\n',dataset_filepath);
    end
end
end