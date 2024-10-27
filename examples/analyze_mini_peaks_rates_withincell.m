%% Analyze mini peaks and rates within cell
% 1) Specify the experiment folder (where all data from single
% experiment is saved) and trial folder (specific folder where trial to be
% analyzed is saved). If these are the same, just set trial_folder =
% exp_folder. If more than one trial is in this folder, also specify the file
% name of the specific recording to be analyzed, otherwise if this is left 
% blank, the first recording is grabbed automatically 
% Path to data and ROIs
data_folder = fullfile(getDataFold('emma'),'thesis_experiments');
% data_folder = fullfile('/Volumes/Emma Drive/data/','thesis_experiments',exp_date);
exp_date = '241011';
dish = 'dish01'; 
cond_names = {'control','post_stim'};
cond_names_plot = {'Control','Post stimulus'};
% Plotting settings
plot_fig = 1; % set to 1 to generate plot
save_fig = 1; % set to 1 to save plot
set_unif_yax = 1;  % use uniform y axis limits for rates and peaks
cond_cols = {0.4*[1 1 1],'r'};
% 2) Specify ROI set zip file (output of saving ROIs in ImageJ)
roiset_filename = 'RoiSet'; % leave out file extension

exp_folder = fullfile(data_folder,'GluSnFR3_SynmRuby',dish);
%% Get data
nconds = length(cond_names);
mean_mini_rates_all = zeros(1,nconds); % [control, post_stim] - average rate across all ROIs
mean_mini_rates = zeros(1,nconds); % [control, post_stim] - average rate in ROIs with >=1 mini
mean_mini_peaks = zeros(1,nconds); % [control, post_stim] - average peak in ROIs with >=1 mini
ylim_rates = zeros(nconds,2);
ylim_peaks = zeros(nconds,2);
fig = figure; 
for i = 1:nconds
    img_data_folder = fullfile(exp_folder,cond_names{i});
    img_names = getImagesWithinDir(img_data_folder);
    mini_data_folder = fullfile(exp_folder,cond_names{i},['mini_analysis_' roiset_filename]);
    mini_ratesi = cell(1,length(img_names));
    mini_peaksi = cell(1,length(img_names)); % mean within trial
    for j = 1:length(img_names)
        rec = Recording(fullfile(img_data_folder,img_names{j}));
        mini_datafilename = fullfile(mini_data_folder,[rec.img_name '_' roiset_filename '_mini_data.mat']);
        mini_data = load(mini_datafilename);
        mini_peaks = mini_data.mini_output.mini_peaks_deltaF_F;
        % mini_peaks = mini_peaks(~cellfun(@isempty,mini_peaks,'UniformOutput',1));
        n_minis = cellfun(@length,mini_peaks,'UniformOutput',1);
        total_time = mini_data.mini_output.t(end) + mini_data.mini_output.t(2) - mini_data.mini_output.t(1);
        mini_rate = n_minis/total_time; % minis/sec (Hz) for each ROI
        mean_mini_peaks_ij = cellfun(@mean,mini_peaks,'UniformOutput',1); % mean peak for each ROI                
        % store
        mini_ratesi{j} = mini_rate'; 
        mini_peaksi{j} = mean_mini_peaks_ij'; 
    end    
    mini_ratesi = cell2mat(mini_ratesi);
    mini_peaksi = cell2mat(mini_peaksi);

    mean_mini_ratesi_roi = mean(mini_ratesi,2); % average across trials, within ROI
    mean_mini_peaksi_roi = mean(mini_peaksi,2,'omitnan'); % average across trials, within ROI
    mean_mini_peaksi_roi(mean_mini_peaksi_roi == 0) = nan;

    if plot_fig        
        ax = subplot(2,nconds,i); % rates
        plotBarPlot_ErrBars_Points(1000*mini_ratesi,'pt_cols',cond_cols{i},...
                                    'bar_cols',cond_cols{i})        
        if i == 1
            ylabel('Rate (mHz)')
        end
        title(cond_names_plot{i});
        ylim_rates(i,:) = ax.YLim;
        ax = subplot(2,nconds,nconds+i); % peaks
        plotBarPlot_ErrBars_Points(mini_peaksi*100,'pt_cols',cond_cols{i},...
                                        'bar_cols',cond_cols{i})
        xlabel('Trial')
        if i == 1
            ylabel('Peak \Delta F/F_{0} (%)')
        end  
        ylim_peaks(i,:) = ax.YLim;
    end
    % mean across rois
    
    mean_mini_rates_all(i) = mean(mean_mini_ratesi_roi); % average rate across all ROIs
    mean_mini_rates(i) = mean(mean_mini_ratesi_roi(~isnan(mean_mini_peaksi_roi))); % average rate in ROIs with >=1 mini
    mean_mini_peaks(i) = mean(mean_mini_peaksi_roi,'omitnan'); % average peak in ROIs with >=1 mini
end
if plot_fig 
    % set uniform yaxes
    if set_unif_yax
        ylim_rates_plot = [min(ylim_rates(:,1)),max(ylim_rates(:,2))];
        ylim_peaks_plot = [min(ylim_peaks(:,1)),max(ylim_peaks(:,2))];    
        for i = 1:nconds
            ax = subplot(2,nconds,i);
            ax.YLim = ylim_rates_plot;
            ax = subplot(2,nconds,nconds+i);
            ax.YLim = ylim_peaks_plot;
        end
    end
    if save_fig
        printFig(fig,exp_folder,['rates_peaks_mean_sem' roiset_filename])
    end
end