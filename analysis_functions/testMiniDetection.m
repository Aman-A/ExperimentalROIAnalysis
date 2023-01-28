function [m,detected_minis,actual_minis,means] = testMiniDetection(rec_file,...
                        roi_file,exp_settings,detect_mini_settings,varargin)
%TESTMINIDETECTION ... 
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
if nargin == 0
    rec_file = fullfile(getDataFold('sam'),'Mini_Analysis_Odin','20230124 D3','1.3mM_sucrose.fits');
    roi_file = fullfile(getDataFold('sam'),'Mini_Analysis_Odin','20230124 D3','RoiSet.zip'); 
    exp_settings = ExperimentSettings([],0.1,0.05,'sec',100); 
    detect_mini_settings = detectMinisPresets('odin_100Hz',100);
    detect_mini_settings.plot_figs = 0;
    detect_mini_settings.save_figs = 0; 
    detect_mini_settings.plot_filt_output_roi_index = 0; 
end
in.save_mini_output = 1;
in.data_dir = '';
in.actual_mini_data_file = ''; % ground truth mini data
in.show_diff_image = [1]; 
in.plot_all_traces = 1; 
in.save_figs = 0; 
in.invert_rois_y = 1; % invert y coord of ROIs due to mismatch between ImageJ and MATLAB convention
in.load_processed_data = 1; 
in.detect_mini_col = 'r';
in.actual_mini_col = 'b';
in.mini_wind = 30e-3*exp_settings.sampling_rate; % Default 30 ms window to define mini timings as the same
in = sl.in.processVarargin(in,varargin);

ps = plotTrialSettings;
ps.plot_func = '';
ps.roi_func_mode = 'separate';
ps.funcs = {'mean','baseline'};
ps.show_diff_image = in.show_diff_image; 
ps.save_fig = in.save_figs; 
ps.show_roi_labels = 1;
ps.load_processed_data = in.load_processed_data;
if isempty(in.data_dir) 
    in.data_dir = fileparts(rec_file); % directory recording is in
else
    % combine with file name to get full path
    rec_file = fullfile(in.data_dir,rec_file); 
    roi_file = fullfile(in.data_dir,roi_file);
end
rec = Recording(rec_file);
rois = ROIs(roi_file);
if in.invert_rois_y    
    rois.invert_y(rec.imsize);
end
%% Extract traces in ROIs and plot baseline image with ROIs overlaid
datai = plotTrial(rec,exp_settings,rois,[],ps);
means = datai.func_output.mean;
% t = datai.func_output.trec; % time vector
%% Run mini detection and save output
detected_minis = detectMinis(means,exp_settings.sampling_rate,detect_mini_settings);
if in.save_mini_output    
    saveMiniOutput(detected_minis,rec,rois,exp_settings);
end
%% Load ground truth minis
if isempty(in.actual_mini_data_file) % assume file is named after dish folder and in same directory as recording
    [~,dish_fold] = fileparts(in.data_dir);
    actual_mini_data_file = fullfile(in.data_dir,[dish_fold '.xlsx']); 
else
    actual_mini_data_file = in.actual_mini_data_file; 
end
mini_frames_mat = readmatrix(actual_mini_data_file);
actual_minis = cell(1,size(mini_frames_mat,2)); % each element is peak frame of 'actual' minis in corresponding ROI
for i = 1:size(actual_minis,2)
    actual_minis{i} = mini_frames_mat(~isnan(mini_frames_mat(:,i)),i);
end
assert(length(actual_minis) == length(detected_minis.mini_frames),'Number of ROIs do not match')
%% Calculate true positives, false positive, and false negatives
% Use to calculate precision (aka positive predictive value or 1 - false discovery
% rate) and recall (aka sensitivity or true positive rate)
tp = zeros(rois.num_rois,1); % true positives (matched in detected and actual minis within in.mini_wind)
fp = zeros(rois.num_rois,1); % false positives (only in detected)
fn = zeros(rois.num_rois,1); % false negatives (only in actual)
tps = cell(1,rois.num_rois); 
fps = cell(1,rois.num_rois);
fns = cell(1,rois.num_rois);
for i = 1:size(actual_minis,2)
    true_mini_framesi = actual_minis{i};
    detected_mini_framesi = detected_minis.mini_frames{i};        
    [tpi,fni,fpi] = compareEventTimes(true_mini_framesi,detected_mini_framesi,in.mini_wind);
    tp(i) = length(tpi); 
    fp(i) = length(fpi);
    fn(i) = length(fni);
    tps{i} = tpi;
    fps{i} = fpi;
    fns{i} = fni; 
end
% ROI-wise precision and recall
m = struct(); % mini metrics
m.tp = tp;
m.fp = fp;
m.fn = fn;
m.precision_rois = tp./(tp + fp); % aka positive predictive value, 1 - false discovery rate
m.recall_rois = tp./(tp + fn); % aka sensitivity, true positive rate
m.F1_rois = 2 * m.precision_rois .* m.recall_rois ...
                    ./(m.precision_rois + m.recall_rois);
% Precision and recall for all minis
m.tp_all = sum(tp); 
m.fp_all = sum(fp); 
m.fn_all = sum(fn); 
m.precision = m.tp_all/(m.tp_all + m.fp_all);
m.recall = m.tp_all./(m.tp_all + m.fn_all); 
m.F1 = 2 * m.precision * m.recall ...
                    /(m.precision + m.recall);
fprintf('Recording %s:\n',rec_file)
fprintf('Precision = %.3f (1 - FDR), Recall = %.3f (TPR), F1 = %.3f\n',...
         m.precision,m.recall,m.F1)
%% Plot traces with minis overlaid
if in.plot_all_traces
    % Detected in red, actual in black (default)
    offset_factor = quantile(max(means,[],1)-mean(means,1),0.8)*1.1; 
    
    fig = figure('Units','inches','Position',[0.4479    1.3021   19.0625    8.9583]); 
    ax = gca;
    plotROIfunc(datai.func_output,'mean',exp_settings.stim_vals,...
                [],'ax',ax,...
                'show_legend',0,'rois',rois,'offset_factor',offset_factor,...
                'sbar_len',offset_factor/2,'title_on',0);
    offset = linspace(rois.num_rois*offset_factor,...
                                        0,rois.num_rois);
    cols = lines(rois.num_rois);
    for i = 1:rois.num_rois
        Fi = means(:,i);
        non_nan_frames = find(~isnan(Fi));
        Fi = Fi - Fi(non_nan_frames(1),:) + offset(i); % start all traces at 0 for plot    
        if ~isempty(tps{i}) % match in detected and actual, default black
            plot(tps{i},Fi(tps{i}),'o',...
                'MarkerEdgeColor','k',... % cols(i,:)
                'MarkerFaceColor','none','MarkerSize',6,'LineWidth',1.5);
        end
        if ~isempty(fps{i}) % detected only (false positives), default red
            plot(fps{i},Fi(fps{i}),'.',...
                    'MarkerEdgeColor',in.detect_mini_col,... % cols(i,:)
                    'MarkerFaceColor','none','MarkerSize',12,'LineWidth',1.5);
        end    
        if ~isempty(fns{i}) % Actual only (false negatives), default blue
            plot(fns{i},Fi(fns{i}),'*','MarkerEdgeColor',in.actual_mini_col,...
                    'MarkerFaceColor',in.actual_mini_col,'MarkerSize',6);
        end
    end
    ax.XLim = [1,size(means,1)];
    if in.save_figs
        printFig(fig,fullfile(rec.filedir,'mini_analysis'),[rec.img_name,...
                        sprintf('_meanF_with_minis_th%.1f_snrth%.1f',...
                                    detect_mini_settings.threshold,...
                                    detect_mini_settings.snr_thresh)])
    end
end
end