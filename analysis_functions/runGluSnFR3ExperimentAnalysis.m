function runGluSnFR3ExperimentAnalysis(def_or_dataset_def_filename,conditions,...
                            roi_func_modes,exp_settings,plot_settings,varargin)
%RUNGLUSNFR3EXPERIMENTANALYSIS Runs analyis on experiments in multiple dishes,
%defined in a dataset definition file, wrapper function for
%reporter-specific functions
%  
%   Inputs 
%   ------ 
%   def_or_dataset_def_filename : char or table
%                          path to Dataset definition file or pre-loaded
%                          Dataset definition table
%   conditions: char or cell
%               single or list of conditions (folder names) to analyze 
%               within each dish
%   roi_func_modes : char or cell
%                   single or list of roi_func_modes ('separate' or
%                   'combine')
%   exp_settings: ExperimentSettings object or cell array
%                 instance of ExperimentalSettings object containing
%                 parameters for experimental recording, stimulation times, 
%                 and desired baseline window, or cell array of separate
%                 ExperimentSettings objects for each dish within dataset
%   plot_settings: struct or cell array
%                 settings struct for plotTrial/plotTrials or cell array of
%                 structs
%                 Individual fields can also be specified for each dish in 
%                 Dataset definition file by adding column with following 
%                 format: 
%                   <setting_name>_<roi_func_mode>
%                 see plotTrialSettings.m for all settings
%                 Ex: y_lim_combine or y_lim_separate
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
%   To do:
%   --------------- 
%   Make compatible with multiple/modified roisets for different trials and
%   conditions. One approach would be to make an ExperimentROIs object 
%   with set of ROIs for each trial (e.g. if using
%   automatic coregistration or manually editing trial-to-trial). Make
%   function allowing manual editing of this object with GUI. Use single
%   filename of this object in dataset definition file. Switch in this
%   function would detect if roiset_filename is single ROIs object or this
%   new ExperimentROIs object and run analysis accordingly. Or this could
%   be done in plotTrials_multipleConditions/plotTrials by slicing an
%   object array of ROIs

% AUTHOR    : Aman Aberra 

in.plot_exp_summary_stats_inds = []; % specify which plots in 
                                            % plotExpDefaultSummaryStats to 
                                            % plot for each dish, or leave
                                            % empty/set to 0 for none
in.extra_exp_settings = []; % ExperimentSettings for train trials                                            
in = sl.in.processVarargin(in,varargin);
if ischar(def_or_dataset_def_filename)
    def = loadDatasetDefinition(def_or_dataset_def_filename);
else
    def = def_or_dataset_def_filename; 
end
num_dishes = size(def,1);
def_vars = def.Properties.VariableNames;
if ischar(roi_func_modes)
    roi_func_modes = {roi_func_modes};
end
if isa(exp_settings,'ExperimentSettings')
    % replicate single input exp_settings for all dishes
    if length(exp_settings) == num_dishes % object array of ExperimentSettings
        exp_settings_all = num2cell(exp_settings); % convert to cell array
    elseif length(exp_settings) == 1
        exp_settings_all = repmat({exp_settings},num_dishes,1);    
    else
        error('Mismatch between number of ExperimentSettings (%g) and number of dishes (%g)\n',...
             length(exp_settings),num_dishes);
    end
end
if isa(plot_settings,'struct') 
    % replicate single input plot_settings for all dishes
    plot_settings_all = repmat({plot_settings},num_dishes,1);
end
% get dish-specific modifiers of plotTrialSettings stored in
% dataset_definition (alternative to inputting cell array of plot_settings 
% structs), e.g. transform_mode, registration_rec, etc
plotTrialSettings_fields = fieldnames(plotTrialSettings); % general settings
mod_fields_all = intersect(plotTrialSettings_fields,def_vars); % fieldnames should match plotTrialSettings
suffix_fields = def_vars(~cellfun(@isempty,regexp(def_vars,'_suffix'),'UniformOutput',1));
for k = 1:length(roi_func_modes)
    % check for plot_settings modifiers in dataset definition file
    roi_func_modek = roi_func_modes{k};    
    plotTrialSettings_fieldsk = strcat(plotTrialSettings_fields,'_',roi_func_modek); % roi_func_mode specific settings    
    mod_fields_funck = intersect(plotTrialSettings_fieldsk,def_vars);
    for i = 1:num_dishes
        % set starting options, then modify for ith dish and kth roi_func_mode
        psi = plot_settings_all{i}; 
        psi.roi_func_mode = roi_func_modek;
        exp_settingsi = exp_settings_all{i}; 
        % update plot_settings with modifiers for all dishes and
        % roi_func_modes
        for n = 1:length(mod_fields_all)
            fieldn = mod_fields_all{n}; % fieldname in dataset/plot_settings same            
            psi.(fieldn) = def.(fieldn){i}; 
        end
        if any(strcmp(mod_fields_all,'registration_rec'))
            % assign full path to registration recording for proper loading
            psi.registration_rec = PathToRegistrationRec(def.registration_rec{i},psi);
            if isfield(in.extra_exp_settings,'registration_rec') 
                % separate ExperimentSettings for registration recording
                registration_rec_settings = in.extra_exp_settings.registration_rec;
                if length(registration_rec_settings) == num_dishes
                    psi.registration_rec_settings = registration_rec_settings(i);
                else
                    psi.registration_rec_settings = registration_rec_settings;
                end
            end
        end         
        psi_main = psi; % plotSettings for main experiment conditions
        % update plot_settings with modifiers for this dish and
        % roi_func_mode
        for n = 1:length(mod_fields_funck)        
            fieldn = mod_fields_funck{n}; % field name in dataset definition            
            % fieldname in plot_settings
            fieldnk = extractBefore(mod_fields_funck{n},['_',roi_func_modek]);
            if isnumeric(plot_settings.(fieldnk))
                psi_main.(fieldnk) = str2num(def.(fieldn){i}); %#ok<ST2NM> 
            else
                psi_main.(fieldnk) = def.(fieldn){i}; 
            end
        end
        % currently only allow for single roiset for all trials
        roiset_filenamei = def.roiset_filename{i};
        out = plotTrials_multipleConditions(conditions,psi_main,exp_settingsi,...
                                      roiset_filenamei);
        % Save summary figs
        if ~isempty(in.plot_exp_summary_stats_inds) && all(in.plot_exp_summary_stats_inds~=0)
            plotExpDefaultSummaryStats(out,out.plot_settings,...
                                       'plot_inds',in.plot_exp_summary_stats_inds,...
                                       'roi_set_filename',roiset_filenamei,...
                                       'save_fig',psi_main.save_fig) 
        end
        % check for extra conditions, denoted by <condition>_suffix, e.g.
        % train_suffix        
        for n = 1:length(suffix_fields)            
            fieldn = suffix_fields{n};
            if strcmp(fieldn,'norm_suffix')
                continue; % skip glutamate normalization, run analysis manually
            end
            fieldn_name = fieldn(1:(regexp(fieldn,'_suffix')-1));
            if isfield(in.extra_exp_settings,fieldn_name)
                exp_settingsn = in.extra_exp_settings.(fieldn_name); 
            else
                error('Need to input ExperimentSettings object for %s extra condition',fieldn_name);
            end              
            roiset_filename_no_exti = getROIset_name(roiset_filenamei,...
                                                     psi.transform_type,...
                                                     psi.registration_rec);  
            summary_fig_dir_in = fullfile(psi.data_fold,psi.exp_date,psi.reporter,...
                                         psi.dish,fieldn_name,...
                                        ['figs_',roiset_filename_no_exti]);
            summary_datafile_in = sprintf('%s_%s_%s_%s_%s_train',psi.exp_date,...
                                          psi.reporter,psi.dish,psi.roi_func_mode,...
                                           roiset_filename_no_exti);
            out = plotTrials_multipleConditions({fieldn_name},psi,exp_settingsn,...
                                          roiset_filenamei,...
                                          'summary_fig_dir',summary_fig_dir_in,...
                                          'summary_datafile',summary_datafile_in,...
                                          'plot_overlaid',0); % skip overlay
        end

    end
end

end
function path_to_rec = PathToRegistrationRec(registration_rec,ps)
    [path,name] = fileparts(registration_rec);     
    if isempty(path) % 
        error('Input registration_rec %s does not specify condition folder',...
            registration_rec)
    elseif isempty(regexp(path,'/','ONCE')) % input as <condition>/<img_name> 
        path_to_rec = fullfile(ps.data_fold,ps.exp_date,ps.reporter,...
                             ps.dish,path,name);
    else
        error('Input registration_rec %s\n Needs to be path relative to experiment folder or full path',...
             registration_rec)
    end
end