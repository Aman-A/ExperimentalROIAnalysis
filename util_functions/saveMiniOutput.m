function saveMiniOutput(mini_output,rec,rois,exp_settings,varargin)
%SAVEMINIOUTPUT ... 
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
in.mini_output_folder = fullfile(rec.filedir,'mini_analysis'); % default save to folder recording is in
in = sl.in.processVarargin(in,varargin);
rec_name = rec.img_name; 

if ~exist(in.mini_output_folder,'dir')
    mkdir(in.mini_output_folder)
    fprintf('Created %s to save output\n',in.mini_output_folder)
end
file_pre = sprintf('%s_%s',rec_name,rois.roiset_filename);
%% Save to .mat file
mini_output_mat_file = fullfile(in.mini_output_folder,[file_pre '_mini_data.mat']);
recording = rec.unload(); % don't save recording data
save(mini_output_mat_file,'mini_output','rois','exp_settings','recording')
%% Save spreadsheets
% Save ROI fluorescence values
writecell(rois.names',fullfile(in.mini_output_folder,[file_pre '_F.csv']))
writematrix(mini_output.F,fullfile(in.mini_output_folder,[file_pre '_F.csv']),'WriteMode','append');
% Save ROI mini peaks, baselines, and peak frame, and traces as separate
% tabs
num_minis_roi = cellfun(@length,mini_output.mini_frames,'UniformOutput',1);
num_rois = length(mini_output.mini_frames);
max_minis = max(num_minis_roi);
% Convert to cell array to write columns with different numbers of elements
if max_minis == 0
    fprintf('No minis to save\n')
    return
end
mini_peaks = cell(max_minis,num_rois);
mini_baselines = cell(max_minis,num_rois);
mini_frames = cell(max_minis,num_rois);
for i = 1:num_rois
    n_minisi = length(mini_output.mini_frames{i});
    mini_peaks(1:n_minisi,i) = num2cell(mini_output.mini_peaks_deltaF_F{i});
    mini_baselines(1:n_minisi,i) = num2cell(mini_output.mini_baselines{i});
    mini_frames(1:n_minisi,i) = num2cell(mini_output.mini_frames{i});
end
mini_stats_filename = fullfile(in.mini_output_folder,[file_pre '_minis.xlsx']);
writecell([rois.names';mini_peaks],mini_stats_filename,'Sheet','Peaks',...
        'WriteMode','overwritesheet')
writecell([rois.names';mini_baselines],mini_stats_filename,'Sheet','Baselines',...
        'WriteMode','overwritesheet')
writecell([rois.names';mini_frames],mini_stats_filename,'Sheet','Frames',...
        'WriteMode','overwritesheet')
try
    writecell(rois.names(mini_output.mini_roi_inds)',mini_stats_filename,'Sheet','Traces',...
            'WriteMode','overwritesheet')
    writematrix(mini_output.mini_deltaF_F_traces,mini_stats_filename,'Sheet','Traces',...
            'WriteMode','append')
catch
    % Write mini traces to separate CSV if unable to save to same
    % spreadsheet
    mini_traces_filename = fullfile(in.mini_output_folder,[file_pre '_mini_traces.csv']);
    writecell(rois.names(mini_output.mini_roi_inds)',mini_traces_filename,...
            'WriteMode','overwrite');
    writematrix(mini_output.mini_deltaF_F_traces,mini_traces_filename,...
            'WriteMode','append')
    fprintf('Wrote %g mini traces to %s\n',size(mini_output.mini_deltaF_F_traces,2),...
            mini_traces_filename)
end
fprintf('Saved mini output to %s\n',in.mini_output_folder)
end
