function [data,def,lgi1_data] = loadArchonLGI1pHmScarletDataset(dataset_def_filename,...
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
    if isfield(all_data,'norm_data')
        norm_data = all_data.norm_data;
    else
        norm_data = []; 
    end
    if isfield(all_data,'train_data')
        train_data = all_data.train_data;
    else
        train_data = []; 
    end    
    fprintf('Loaded compiled dataset from %s in %.3f sec\n',dataset_filepath, elapsed_time);
else
    % Load processed data and compile
    def = loadDatasetDefinition(dataset_def_filename);
    num_dishes = size(def,1);
    data = cell(num_dishes,1);
    norm_data = cell(num_dishes,1); % normalized data (if exists)
    train_data = cell(num_dishes,1); % data from train protocol applied in each condition (if exists)
    tic; 
    num_loaded = 0;
    num_norm_loaded = 0; 
    num_train_loaded = 0;
    for i = 1:num_dishes
        exp_data_fold = fullfile(in.data_fold,def.exp_date{i},def.reporter{i},def.dish{i});
        roiset_filename_no_ext = getROIset_name(def.roiset_filename{i},...
                                                 def.transform_type{i},...
                                                  def.registration_rec{i});  
        if isempty(in.summary_data_file_suffix)
            summary_data_file = sprintf('%s_%s_%s_%s_%s',def.exp_date{i},def.reporter{i},def.dish{i},...
                                       roi_func_mode,roiset_filename_no_ext);
        else
            summary_data_file = sprintf('%s_%s_%s_%s_%s_%s',def.exp_date{i},def.reporter{i},def.dish{i},...
                                       roi_func_mode,roiset_filename_no_ext,in.summary_data_file_suffix);
        end
        summary_data_filepath = fullfile(exp_data_fold,[summary_data_file '.mat']);
        if exist(summary_data_filepath,'file')
            datai = load(summary_data_filepath);
            data{i} = datai;
            fprintf('Loaded %s (%g of %g)\n',summary_data_filepath,i,num_dishes);
            num_loaded = num_loaded + 1; 
            if any(strcmp(def.Properties.VariableNames,'norm_suffix')) && ...
                        ~isempty(def.norm_suffix{i}) % check for normalization 
                
                norm_data_file = [summary_data_file '_' def.norm_suffix{i} '.mat']; 
                norm_data_filepath = fullfile(exp_data_fold,norm_data_file);
                if exist(norm_data_filepath,'file')
                    norm_data{i} = load(norm_data_filepath);
                    num_norm_loaded = num_norm_loaded + 1; 
                    fprintf('   Loaded normalized data: %s\n',norm_data_filepath)
                else
                    fprintf('   !!Normalized data file not found: %s \n',norm_data_filepath)
                end
            end
            if any(strcmp(def.Properties.VariableNames,'train_suffix')) && ...
                    ~isempty(def.train_suffix{i}) % check for train trials
                
                train_data_file = [summary_data_file '_' def.train_suffix{i} '.mat']; 
                train_data_filepath = fullfile(exp_data_fold,train_data_file);
                if exist(train_data_filepath,'file')
                    train_data{i} = load(train_data_filepath);
                    num_train_loaded = num_train_loaded + 1; 
                    fprintf('   Loaded train protocol data: %s\n',train_data_filepath)
                else
                    fprintf('   !!Train protocol data file not found: %s \n',train_data_filepath)
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
    if any(strcmp(def.Properties.VariableNames,'norm_suffix'))    
        num_norm = sum(~cellfun(@isempty,def.norm_suffix,'UniformOutput',1));
        if num_norm > 0
            fprintf('   Loaded %g of %g normalized datasets\n',...
                    num_norm_loaded,num_norm);
        end
    end
    if any(strcmp(def.Properties.VariableNames,'train_suffix'))
        num_train = sum(~cellfun(@isempty,def.train_suffix,'UniformOutput',1));
        fprintf('   Loaded %g of %g train protocol datasets\n',...
                num_train_loaded,num_train);
    end
    % Save compiled dataset to .mat file
    if in.save_compiled_dataset && num_loaded > 0
        if ~exist(in.dataset_fold,'dir')
            mkdir(in.dataset_fold);
        end
        save_data = struct(); 
        save_data.def = def; 
        save_data.data = data;
        if any(strcmp(def.Properties.VariableNames,'norm_suffix')) && any(~isempty(def.norm_suffix))
            save_data.norm_data = norm_data;
        end
        if any(strcmp(def.Properties.VariableNames,'train_suffix')) && any(~isempty(def.train_suffix))
            save_data.train_data = train_data;
        end
        fprintf('Saving...\n')
        save(dataset_filepath,'-STRUCT','save_data');
        fprintf('Saved compiled dataset to %s\n',dataset_filepath);
    end
end
end