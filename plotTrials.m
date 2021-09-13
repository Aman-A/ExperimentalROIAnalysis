function [deltaF_F0,peaks_deltaF_F0,mean_peak_deltaF_F0,std_peak_deltaF_F0] = ...
                plotTrials(data_fold,exp_date,reporter,dish,condition,position,...
                   img_names,exp_settings,roi_set_filename,...
                   show_diff_image,filt_width,funcs,roi_func_mode,... % Optional 
                   save_processed_data,load_processed_data)
%PLOTTRIALS Plot set of trials on same axis   
if nargin < 10
   show_diff_image = []; 
   filt_width = 0; % gaussian filter width, used on peak deltaF to refine 
                   % ROI positions
   
   funcs = {'mean','std','baseline','deltaF_F0'}; % functions to compute
   roi_func_mode = 'combine';
   save_processed_data = 1;
   load_processed_data = 0; 
end
filedir = fullfile(data_fold,exp_date,reporter,dish,condition);            
if isempty(img_names) % assume all .fits files are relevant trial data
    d = dir(filedir); 
    file_names = {d.name};
    creation_time = [d.datenum];
    [~,inds] = sort(creation_time,'ascend');
    file_names = file_names(inds);
    [~,~,file_exts] = cellfun(@(x) fileparts(x),file_names,'UniformOutput',0);
    is_fits = cellfun(@(x) strcmp(x,'.fits'),file_exts,'UniformOutput',1);
    is_not_hidden = cellfun(@(x) ~strcmp(x(1),'.'),file_names,'UniformOutput',1);
    img_names = file_names(is_fits & is_not_hidden);
    % returns names sorted by time of creation
end
num_trials = length(img_names); 
fig = figure; 
trace_axis = gca; 
func_outputs = cell(1,num_trials); 
deltaF_F0 = cell(1,num_trials); 
for i = 1:num_trials
    img_namei = img_names{i}; 
    datai = plotTrial(data_fold,exp_date,reporter,dish,condition,position,...
                   img_namei,exp_settings,roi_set_filename,...
                   trace_axis,show_diff_image,filt_width,funcs,roi_func_mode,... % Optional 
                   save_processed_data,load_processed_data);
    func_outputs{i} = datai.func_output; 
    deltaF_F0{i} = datai.func_output.deltaF_F0;
end
deltaF_F0 = cell2mat(deltaF_F0); 
peaks_deltaF_F0 = max(deltaF_F0,[],1); % peaks within trial
mean_peak_deltaF_F0 = mean(peaks_deltaF_F0);
std_peak_deltaF_F0 = std(peaks_deltaF_F0,0);
fprintf('%s: Peak deltaF_F0 across trials (mean +/- std) = %.3f +/- %.3f\n',...
         condition, mean_peak_deltaF_F0,std_peak_deltaF_F0); 
end