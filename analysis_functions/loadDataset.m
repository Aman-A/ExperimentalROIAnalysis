function [data,norm_data] = loadDataset(dataset_filename,roi_func_mode,varargin)
%LOADDATASET ... 
%  
%   Inputs 
%   ------ 
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
in = sl.in.processVarargin(in,varargin);

[~,dataset_name,ext] = fileparts(dataset_filename);
dataset_filepath = fullfile(in.dataset_fold,[dataset_name '.mat']); % save compiled dataset
if in.load_compiled_dataset && exist(dataset_filepath,'file')
    all_data = load(dataset_filepath);
    data = all_data.data;
    if isfield(all_data,'norm_data')
        norm_data = all_data.norm_data;
    else
        norm_data = []; 
    end
    fprintf('Loaded compiled dataset from %s\n',dataset_filepath);
else
    % Load processed data and compile
    if strcmp(ext,'.csv')
        dataset_def = readmatrix(dataset_filename,'NumHeaderLines',1,'OutputType','char');
        % Format: 
        % exp_date, reporter, dish,roiset_filename,transform_type,registration_rec
        exp_dates = dataset_def(:,1);
        reporters = dataset_def(:,2);
        dishes = dataset_def(:,3); 
        roiset_filenames = dataset_def(:,4);
        transform_types = dataset_def(:,5);
        registration_recs = dataset_def(:,6);
        norm_suff = dataset_def(:,7); % suffix in name of normalized data file        
    else
       error('Format %s not implemented yet\n',ext);
    end
    num_dishes = length(dishes);
    data = cell(num_dishes,1);
    norm_data = cell(num_dishes,1); % normalized data (if exists)
    tic; 
    num_norm_loaded = 0; 
    for i = 1:num_dishes
        exp_data_fold = fullfile(in.data_fold,exp_dates{i},reporters{i},dishes{i});
        roiset_filename_no_ext = getROIset_name(roiset_filenames{i},...
                                                 transform_types{i},...
                                                  registration_recs{i});  
        summary_data_file = sprintf('%s_%s_%s_%s_%s',exp_dates{i},reporters{i},dishes{i},...
                                   roi_func_mode,roiset_filename_no_ext);
        summary_data_filepath = fullfile(exp_data_fold,[summary_data_file '.mat']);
        if exist(summary_data_filepath,'file')
            datai = load(summary_data_filepath);
            data{i} = datai;
            fprintf('Loaded %s (%g of %g)\n',summary_data_filepath,i,num_dishes);
            if ~isempty(norm_suff{i}) % check for normalization 
                
                norm_data_file = [summary_data_file '_' norm_suff{i} '.mat']; 
                norm_data_filepath = fullfile(exp_data_fold,norm_data_file);
                if exist(norm_data_filepath,'file')
                    norm_data{i} = load(norm_data_filepath);
                    num_norm_loaded = num_norm_loaded + 1; 
                    fprintf('   Loaded normalized data: %s\n',norm_data_filepath)
                else
                    fprintf('   !!Normalized data file not found: %s \n',norm_data_filepath)
                end
            end
        else
            fprintf('%s does not exist, skipping...\n',summary_data_file);
        end
    end
    elapsed_time = toc; 
    fprintf('Finished loading dataset: %s in %.2f sec\n',dataset_name,elapsed_time)
    if any(~isempty(norm_suff))
        fprintf('   Loaded %g of %g normalized datasets\n',...
                num_norm_loaded,sum(~cellfun(@isempty,norm_suff,'UniformOutput',1)));
    end
    if in.save_compiled_dataset
        if ~exist(in.dataset_fold,'dir')
            mkdir(in.dataset_fold);
        end
        save_data = struct(); 
        save_data.data = data;
        if any(~isempty(norm_suff))
            save_data.norm_data = norm_data;
        end
        save(dataset_filepath,'-STRUCT','save_data');
        fprintf('Saved compiled dataset to %s\n',dataset_filepath);
    end
end
end