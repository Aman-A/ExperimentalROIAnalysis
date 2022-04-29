function [data,def,AP_data,lgi1_data] = loadArchonLGI1pHmScarletDataset(dataset_def_filename,...
                                                   roi_func_mode,varargin)
%LOADARCHONLGI1PHMSCARLETDATASET Compiles data from multiple dishes defined in dataset
%definition file and loads for Archon/LGI1pHmScarlet experiments
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
in.extra_conditions_suffix = 'APwave'; % string - suffix to use for summary data file for
                                 % extra_conditions
in.lgi1_condition = 'lgi1_pHmScarlet';    
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
    AP_data = all_data.AP_data; 
    lgi1_data = all_data.lgi1_data;   
    fprintf('Loaded compiled dataset from %s in %.3f sec\n',dataset_filepath, elapsed_time);
else
    % Load processed data and compile
    def = loadDatasetDefinition(dataset_def_filename);
    num_dishes = size(def,1);
    data = cell(num_dishes,1);
    AP_data = cell(num_dishes,1); % AP waveform characterization data (single train)
    lgi1_data = cell(num_dishes,1); % LGI1 pHmScarlet imaging
    tic; 
    num_loaded = 0;
    num_ap_data_loaded = 0; 
    num_lgi1_data_loaded = 0;
    for i = 1:num_dishes
        exp_data_fold = fullfile(in.data_fold,def.exp_date{i},def.reporter{i},def.dish{i});
        roiset_filename_no_ext = getROIset_name(def.roiset_filename{i},...
                                                 def.transform_type{i},...
                                                  def.registration_rec{i});  
        summary_data_file_base = sprintf('%s_%s_%s_%s_%s',def.exp_date{i},def.reporter{i},def.dish{i},...
                                       roi_func_mode,roiset_filename_no_ext);
        if isempty(in.summary_data_file_suffix)
           summary_data_file = summary_data_file_base; 
        else
            summary_data_file = sprintf('%s_%s',summary_data_file_base,...
                                        in.summary_data_file_suffix);
        end
        summary_data_filepath = fullfile(exp_data_fold,[summary_data_file '.mat']);
        AP_data_file = sprintf('%s_%s',summary_data_file_base, ...
                                in.extra_conditions_suffix);
        AP_data_filepath = fullfile(exp_data_fold,[AP_data_file '.mat']);
        lgi1_data_file = sprintf('%s_%s_%s',summary_data_file_base,...
                                in.lgi1_condition,def.lgi1_trial_name{i});        
        lgi1_data_filepath = fullfile(exp_data_fold,[lgi1_data_file '.mat']);
        if exist(summary_data_filepath,'file')
            datai = load(summary_data_filepath);
            data{i} = datai;
            fprintf('Loaded %s (%g of %g)\n',summary_data_filepath,i,num_dishes);
            num_loaded = num_loaded + 1; 
            % Load AP waveform data
            if exist(AP_data_filepath,'file')
                AP_data{i} = load(AP_data_filepath);
                num_ap_data_loaded = num_ap_data_loaded + 1; 
                fprintf('   Loaded AP waveform data: %s\n',AP_data_filepath)
            end
            % Load LGI1 imaging data
            if exist(lgi1_data_filepath,'file')
                lgi1_data{i} = load(lgi1_data_filepath);
                num_lgi1_data_loaded = num_lgi1_data_loaded + 1; 
                fprintf('   Loaded LGI1 data: %s\n',lgi1_data_filepath)
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
    
    fprintf('   Loaded %g of %g AP waveform datasets\n',...
            num_ap_data_loaded,num_dishes);    
    fprintf('   Loaded %g of %g LGI1 datasets\n',...
                num_lgi1_data_loaded,num_dishes);
    % Save compiled dataset to .mat file
    if in.save_compiled_dataset && num_loaded > 0
        if ~exist(in.dataset_fold,'dir')
            mkdir(in.dataset_fold);
        end
        save_data = struct(); 
        save_data.def = def; 
        save_data.data = data;
        save_data.AP_data  = AP_data;
        save_data.lgi1_data = lgi1_data;        
        fprintf('Saving...\n')
        save(dataset_filepath,'-STRUCT','save_data');
        fprintf('Saved compiled dataset to %s\n',dataset_filepath);
    end
end
end