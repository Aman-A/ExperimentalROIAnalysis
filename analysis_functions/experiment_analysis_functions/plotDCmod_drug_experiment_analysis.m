function [data_raw,def,drug_data] = plotDCmod_drug_experiment_analysis(dataset_def_filename,reporter,roi_func_mode,...
                                            mode_str,load_compiled_dataset,varargin)
%PLOTDCMOD_DRUG_EXPERIMENT_ANALYSIS ... 
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
in.plot_figs = 1:5; % 1 - mean peaks in control. vs each drug condition as line/scatter plot
                    % 2 - mean peaks within cell in control. vs each drug condition as line/scatter plot
                    % 3 - mean peaks in control. vs each drug condition as CDFs
                    % 4 - change in DC modulation within cell in control. vs each drug
                    % 5 - change in DC modulation within ROI in control. vs each drug
in.plot_amps = [-1,1];
in.amp_labels = [];
in.amp_cols = [0 0 1;1 0 0];
in.min_num_trials_per_amp = 2; % require number of trials at each amplitude
in.drug_names = {'1mM_KCl','4.5mM_KCl'};
in.drug_cols = {'b','r'};
in.include_title = 1; 
in.save_figs = 0;
in.data_raw = []; 
in.def = []; 
in.drug_data = []; 
in.cdf_bin_width = 0.1;
in.sort_amps = 1; % sort cells/ROI amplitude so is -1 mA suppressing, +1 mA facilitating polarity
[~,in.fig_fold] = fileparts(dataset_def_filename);
in = sl.in.processVarargin(in,varargin);
%%
analysis_fold = fileparts(which('plotDCmod_drug_experiment_analysis'));
fig_fold = fullfile(analysis_fold,in.fig_fold);
if isempty(in.data_raw) % load/make dataset
    dataset_def_file = fullfile(analysis_fold,'..','dataset_files',dataset_def_filename);
    opts = struct();
    opts.data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments');
    opts.dataset_fold = fullfile(analysis_fold,'datasets');
    opts.load_compiled_dataset = load_compiled_dataset;
    [data_raw,def,drug_data] = loadDataset(dataset_def_file,reporter,roi_func_mode,mode_str,...
                            opts);
else % Pre-loaded data was input to function
    data_raw = in.data_raw;
    def = in.def; 
    drug_data = in.drug_data; 
end
%%
num_amps = length(in.plot_amps);
num_dishes = length(data_raw); 
subthresh_amps = cellfun(@(x) str2num(x),def.subthresh_amps,'UniformOutput',0); %#ok<*ST2NM> 
drug_subthresh_amps = cellfun(@(x) str2num(x),def.subthresh_amps_drug,'UniformOutput',0); %#ok<*ST2NM> 
suprathresh_amps = cellfun(@(x) str2num(x),def.suprathresh_amps,'UniformOutput',0);
drug_name_dishes = def.drug_suffix; 
for d = in.drug_names
    drug_name_dishes(strncmp(d,drug_name_dishes,length(d))) = d;
end
if isempty(in.amp_labels)
    in.amp_labels = numericVec2chars(in.plot_amps,'%g mA');
end
%% extract peaks and deltaF/F0 traces
% Control condition
data = data_raw; 
out = extractSubthreshModResponses(data,def,in.plot_amps,in.min_num_trials_per_amp);
peaks_before = out.peaks_before; 
peaks_during = out.peaks_during;
dish_inds = out.dish_inds{1};
dF_al2_before = out.dF_al2_before;
dF_al2_during = out.dF_al2_during;
num_rois_per_dish = out.num_rois; 
num_rois_total = sum(num_rois_per_dish);
roi_in_dish_index = out.roi_in_dish_index;
% extract peaks and deltaF/F0 traces from drug condition
out_drug = extractSubthreshModResponses(drug_data,def,in.plot_amps,in.min_num_trials_per_amp);
peaks_before_drug = out_drug.peaks_before; 
peaks_during_drug = out_drug.peaks_during;
dF_al2_before_drug = out_drug.dF_al2_before;
dF_al2_during_drug = out_drug.dF_al2_during;
ta = data{1}.exp_settings(1).getTimeVector(size(dF_al2_before{1},1));
ta = ta - ta(data{1}.exp_settings(1).baseline_wind+1);
%% Get mean of before DC peaks in control vs. drug condition
% [num_rois x num_stim x num_amps]
peaks_before_cont_mat = cell2mat(reshape(peaks_before,1,1,length(peaks_before)));
peaks_before_drug_mat = cell2mat(reshape(peaks_before_drug,1,1,length(peaks_before_drug)));
peaks_during_cont_mat = cell2mat(reshape(peaks_during,1,1,length(peaks_during)));
peaks_during_drug_mat = cell2mat(reshape(peaks_during_drug,1,1,length(peaks_during_drug)));
% average responses for each amplitude
mean_peaks_cont_before = squeeze(mean(peaks_before_cont_mat,2,'omitnan'));
mean_peaks_drug_before = squeeze(mean(peaks_before_drug_mat,2,'omitnan'));
mean_peaks_cont_during = squeeze(mean(peaks_during_cont_mat,2,'omitnan'));
mean_peaks_drug_during = squeeze(mean(peaks_during_drug_mat,2,'omitnan'));
% average responses before DC for all DC trials
mean_peaks_cont_before_all = mean(peaks_before_cont_mat,[2 3],'omitnan');
mean_peaks_drug_before_all = mean(peaks_before_drug_mat,[2 3],'omitnan');
mean_peaks_cont_before_cell = zeros(num_dishes,1); % keep different amplitudes separate
mean_peaks_drug_before_cell = zeros(num_dishes,1);
mean_peaks_cont_before_cell_all = zeros(num_dishes,1); % average all trials
mean_peaks_drug_before_cell_all = zeros(num_dishes,1);
mean_peaks_cont_during_cell = zeros(num_dishes,length(in.plot_amps));
mean_peaks_drug_during_cell = zeros(num_dishes,length(in.plot_amps));
for i = 1:num_dishes
    mean_peaks_cont_before_cell_all(i) = mean(mean_peaks_cont_before_all(dish_inds == i,:),'omitnan');
    mean_peaks_drug_before_cell_all(i) = mean(mean_peaks_drug_before_all(dish_inds == i,:),'omitnan');
    for j = 1:length(in.plot_amps)
        mean_peaks_cont_before_cell(i,j) = mean(peaks_before_cont_mat(dish_inds == i,:,j),[1 2],'omitnan');
        mean_peaks_drug_before_cell(i,j) = mean(peaks_before_drug_mat(dish_inds == i,:,j),[1 2],'omitnan');
        mean_peaks_cont_during_cell(i,j) = mean(peaks_during_cont_mat(dish_inds == i,:,j),[1 2],'omitnan');
        mean_peaks_drug_during_cell(i,j) = mean(peaks_during_drug_mat(dish_inds == i,:,j),[1 2],'omitnan');
    end
end
% Calculate peak modulation
% [num_rois x num_amps]
peak_mod_cont = mean_peaks_cont_during./mean_peaks_cont_before; % ratio
peak_mod_drug = mean_peaks_drug_during./mean_peaks_drug_before;
peak_mod_cont_per = 100*(peak_mod_cont - 1); % percent change
peak_mod_drug_per = 100*(peak_mod_drug - 1); % percent change
% within cell
peak_mod_cont_cell = mean_peaks_cont_during_cell./mean_peaks_cont_before_cell; % ratio
peak_mod_drug_cell = mean_peaks_drug_during_cell./mean_peaks_drug_before_cell;
peak_mod_cont_cell_per = 100*(peak_mod_cont_cell - 1); % percent change
peak_mod_drug_cell_per = 100*(peak_mod_drug_cell - 1); % percent change
% Get dish indices for each drug condition 
dish_inds_drug = cell(1,length(in.drug_names));
roi_inds_drug = false(length(dish_inds),length(in.drug_names)); % indices of rois with data in either condition
num_rois_drug = zeros(1,length(in.drug_names));
num_cells_drug = zeros(1,length(in.drug_names));
for i = 1:length(in.drug_names)
    dish_inds_drug{i} = find(strcmp(drug_name_dishes,in.drug_names{i}))';
    for j = dish_inds_drug{i}
        roi_inds_drug(dish_inds == j,i) = true;
    end   
    num_rois_drug(i) = sum(roi_inds_drug(:,i));
    num_cells_drug(i) = length(dish_inds_drug{i});
end
%% Sort amplitudes for each cell so that -1 mA suppresses, +1 mA facilitates 
flipped_amp_rois = false(num_rois_total,1);
flipped_amp_cells = false(num_dishes,1);

if in.sort_amps
    fprintf('Sorting current polarity based on modulation\n')
    fprintf('NOTE: amplitudes must be symmetrical, e.g. [-1,-0.5,0.5,1] mA\n')
    for i = 1:num_rois_total
        [~,max_ind] = max(abs(peak_mod_cont_per(i,:)));        
        if ( (peak_mod_cont_per(i,max_ind) > 0 && in.plot_amps(max_ind) < 0) ... % negative current facilitates
            ||  (peak_mod_cont_per(i,max_ind) < 0 && in.plot_amps(max_ind) > 0)) % or positive current suppresses
            peak_mod_cont_per(i,:) = fliplr(peak_mod_cont_per(i,:)); % flip polarity
            peak_mod_drug_per(i,:) = fliplr(peak_mod_drug_per(i,:)); % flip polarity of drug condition to match
            flipped_amp_rois(i) = true; 
        end        
    end
    for i = 1:num_dishes
        [~,max_ind] = max(abs(peak_mod_cont_cell_per(i,:)));        
        if ( (peak_mod_cont_cell_per(i,max_ind) > 0 && in.plot_amps(max_ind) < 0) ... % negative current facilitates
            ||  (peak_mod_cont_cell_per(i,max_ind) < 0 && in.plot_amps(max_ind) > 0)) % or positive current suppresses
            peak_mod_cont_cell_per(i,:) = fliplr(peak_mod_cont_cell_per(i,:)); % flip polarity
            peak_mod_drug_cell_per(i,:) = fliplr(peak_mod_drug_cell_per(i,:)); % flip polarity of drug condition to match
            flipped_amp_cells(i) = true; 
        end  
    end
end
%% Plot mean peaks within ROI in control. vs each drug condition as line/scatter plot
if any(in.plot_figs == 1)
    fig = figure('Units','inches');
    fig.Position(3:4) = [11.5 5.9]; 
    for i = 1:length(in.drug_names)
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end
        mean_peaks_cont_beforei = mean_peaks_cont_before_all(roi_inds_drug(:,i));
        mean_peaks_drug_beforei = mean_peaks_drug_before_all(roi_inds_drug(:,i));       
        for j = 1:num_rois_drug(i)
            plot(ax,[1,2],[mean_peaks_cont_beforei(j),mean_peaks_drug_beforei(j)],...
                'Color',0.8*[1 1 1],'LineWidth',0.25); hold on;
        end
        e = errorbar(ax,[1,2],[mean(mean_peaks_cont_beforei,'omitnan');mean(mean_peaks_drug_beforei,'omitnan')],...
            [std(mean_peaks_cont_beforei,0,'omitnan');std(mean_peaks_drug_beforei,0,'omitnan')]/sqrt(num_rois_drug(i)),...
            'k-','LineWidth',2,'MarkerSize',10);
        box(ax,'off');
        ax.XTick = [1 2]; 
        ax.XTickLabel = {'Control',strrep(in.drug_names{i},'_',' ')};
        if i == 1
            ylabel(ax,'Mean peak \Delta F/F_{0}');
        end
        ax.XLim = [0.9 2.1]; 
        [h,p] = ttest(mean_peaks_cont_beforei,mean_peaks_drug_beforei);
        if h
            plot(ax,1.5,ax.YLim(2)*0.95,'r','Marker','*');
        end 
        if in.include_title
            title(sprintf('%g boutons in %g cells',num_rois_drug(i),length(dish_inds_drug{i})))
        end
        per_changei = 100*(mean_peaks_drug_beforei-mean_peaks_cont_beforei)./mean_peaks_cont_beforei; 
        fprintf('Mean change (+/- SEM): %.3f +/- %.3f\n (n = %g boutons, %g cells)\n',...
                mean(per_changei),std(per_changei)/sqrt(num_rois_drug(i)),num_rois_drug(i),length(dish_inds_drug{i}));
    end
    if in.save_figs
        printFig(fig,fig_fold,sprintf('mean_peaks_before_scatter_%gdishes',num_dishes)); 
    end
end
%% Plot mean peaks within cell in control. vs each drug condition as line/scatter plot
if any(in.plot_figs==2)
    fig = figure('Units','inches');
    fig.Position(3:4) = [11.5 5.9]; 
    for i = 1:length(in.drug_names)
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end          
        mean_peaks_cont_beforei = mean_peaks_cont_before_cell_all(dish_inds_drug{i});
        mean_peaks_drug_beforei = mean_peaks_drug_before_cell_all(dish_inds_drug{i});       
        for j = 1:num_cells_drug(i)
            plot(ax,[1,2],[mean_peaks_cont_beforei(j),mean_peaks_drug_beforei(j)],...
                'Color',0.8*[1 1 1],'LineWidth',0.25); hold on;
        end
        e = errorbar(ax,[1,2],[mean(mean_peaks_cont_beforei,'omitnan');mean(mean_peaks_drug_beforei,'omitnan')],...
            [std(mean_peaks_cont_beforei,0,'omitnan');std(mean_peaks_drug_beforei,0,'omitnan')]/sqrt(num_cells_drug(i)),...
            'k-','LineWidth',2,'MarkerSize',10);
        box(ax,'off');
        ax.XTick = [1 2]; 
        ax.XTickLabel = {'Control',strrep(in.drug_names{i},'_',' ')};
        if i == 1
            ylabel(ax,'Mean peak \Delta F/F_{0}');
        end
        ax.XLim = [0.9 2.1]; 
        [h,p] = ttest(mean_peaks_cont_beforei,mean_peaks_drug_beforei);
        if h
            plot(ax,1.5,ax.YLim(2)*0.95,'r','Marker','*');
        end 
        if in.include_title
            title(sprintf('%g boutons in %g cells',num_rois_drug(i),length(dish_inds_drug{i})))
        end
        % average within cell
        per_changei = 100*(mean_peaks_drug_beforei-mean_peaks_cont_beforei)./mean_peaks_cont_beforei; 
        fprintf('Mean change (+/- SEM): %.3f +/- %.3f\n (n = %g boutons, %g cells)\n',...
                mean(per_changei),std(per_changei)/sqrt(num_rois_drug(i)),num_rois_drug(i),length(dish_inds_drug{i}));
    end
    if in.save_figs
        printFig(fig,fig_fold,sprintf('mean_peaks_before_scatter_wcell_%gdishes',num_dishes)); 
    end
end
%% Plot mean peaks within ROI in control. vs each drug condition as CDFs
if any(in.plot_figs == 3)
    fig = figure('Units','inches');
    fig.Position(3:4) = [11.5 5.9]; 
    for i = 1:length(in.drug_names)
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end
        mean_peaks_cont_beforei = mean_peaks_cont_before_all(roi_inds_drug(:,i));
        mean_peaks_drug_beforei = mean_peaks_drug_before_all(roi_inds_drug(:,i));       
        [Nc,edgesc] = histcounts(mean_peaks_cont_beforei,'BinWidth',in.cdf_bin_width,'Normalization','cdf');
        [Nd,edgesd] = histcounts(mean_peaks_drug_beforei,'BinWidth',in.cdf_bin_width,'Normalization','cdf');
        plot(edgesc(1:end-1)+diff(edgesc(1:2))/2,Nc,'k','LineWidth',1);
        hold on;
        plot(edgesd(1:end-1)+diff(edgesd(1:2))/2,Nd,in.drug_cols{i},'LineWidth',1);
        box(ax,'off');       
        if i == 1
            ylabel(ax,'Proportion')
        end
        xlabel(ax,'Mean peak \Delta F/F_{0}')
        
        [h,p] = ttest(mean_peaks_cont_beforei,mean_peaks_drug_beforei);
        if h
            plot(ax,ax.XLim(1) + diff(ax.XLim)*0.5,ax.YLim(2),'r','Marker','*');
        end 
        legend(ax,{'Control',strrep(in.drug_names{i},'_',' ')},'Location','southeast');
        if in.include_title
            title(sprintf('%g boutons in %g cells',num_rois_drug(i),length(dish_inds_drug{i})))
        end
    end
    if in.save_figs
        printFig(fig,fig_fold,sprintf('mean_peaks_before_CDF_%gdishes',num_dishes)); 
    end
end
%% Quantify modulation within cell in control vs. in drug 
if any(in.plot_figs == 4)
    fig = figure('Units','inches');
    fig.Position(3:4) = [11.5 5.9]; 
    x_vals = (1:length(in.plot_amps)) + [-0.25;0.25];
    % x_vals = x_vals(:);
    for i = 1:length(in.drug_names)
        fprintf('DC modulation in %s:\n',in.drug_names{i});
        dish_cols = lines(num_rois_drug(i));
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end        
        peak_mod_cont_cell_peri = peak_mod_cont_cell_per(dish_inds_drug{i},:);
        peak_mod_drug_cell_peri = peak_mod_drug_cell_per(dish_inds_drug{i},:);
        hi = zeros(length(in.plot_amps),1); % test null hypothesis (1 reject) on dc modulation within amplitude by drug i
        p_vali = zeros(length(in.plot_amps),1); % p values 
        for j = 1:length(in.plot_amps)
            l = plot(ax,x_vals(:,j),[peak_mod_cont_cell_peri(:,j),peak_mod_drug_cell_peri(:,j)],...
                 'LineWidth',0.25); hold on; % color [in.amp_cols(j,:), 0.4]
            for k = 1:length(l)
                l(k).Color = dish_cols(k,:);
            end
            mean_peakmodij = mean([peak_mod_cont_cell_peri(:,j),peak_mod_drug_cell_peri(:,j)],1,'omitnan');
            sem_peakmodij = std([peak_mod_cont_cell_peri(:,j),peak_mod_drug_cell_peri(:,j)],0,1,'omitnan')/sqrt(num_cells_drug(i));
            errorbar(ax,x_vals(:,j),mean_peakmodij,sem_peakmodij,...
                'Color','k','LineStyle','-','LineWidth',2,'MarkerSize',10);    
            fprintf(' %s:\n',in.amp_labels{j});
            fprintf('   Change in control (mean +/- SEM): %.2f +/- %.2f %%\n',...
                    mean_peakmodij(1),sem_peakmodij(1));
            fprintf('   Change in %s (mean +/- SEM): %.2f +/- %.2f %%\n',in.drug_names{i},...
                    mean_peakmodij(2),sem_peakmodij(2));     
            % stats
            [hi(j),p_vali(j)] = ttest(peak_mod_cont_cell_peri(:,j),peak_mod_drug_cell_peri(:,j),...
                               'Alpha',0.05/length(in.plot_amps)); % use bonferroni correction
            if hi(j)                
                % calculate change in modulation (mean ± sem)
                [delta_mod,var_mod] = calcPerErrWithVariance(mean_peakmodij(2),mean_peakmodij(1),...
                                                            sem_peakmodij(2),sem_peakmodij(1)); 
                fprintf('   %.2f +/- %.2f change in modulation (p = %.3f)\n',...
                        delta_mod,var_mod,p_vali(j));
            else
                fprintf('  No significant difference in DC modulation by %s\n',in.amp_labels{j})
            end 
        end        
        % add significance markers
        for j = 1:length(in.plot_amps)
             if hi(j)
                plot(ax,mean(x_vals(:,j)),ax.YLim(2)*0.95,'r','Marker','*');
             end
        end
        box(ax,'off');
        ax.XLim = [x_vals(1)-0.25,x_vals(end)+0.25]; 
        ax.XTick = 1:length(in.plot_amps);
        ax.XTickLabel = in.amp_labels;
        if i == 1
            ylabel(ax,'Change in mean peak \Delta F/F_{0} (%)');
        end
        title(ax,strrep(in.drug_names{i},'_',' '));
    end
    setAxesUniformYLim(fig);
    if in.save_figs
        printFig(fig,fig_fold,sprintf('peak_mod_control_vs_%s_wcell_%gdishes',...
                                in.drug_names{1},num_dishes)); 
    end
end
%% Quantify modulation within ROI in control vs. in drug 
if any(in.plot_figs == 5)
    fig = figure('Units','inches');
    fig.Position(3:4) = [11.5 5.9]; 
    x_vals = (1:length(in.plot_amps)) + [-0.25;0.25];
    % x_vals = x_vals(:);
    for i = 1:length(in.drug_names)
        fprintf('DC modulation in %s:\n',in.drug_names{i});
        dish_cols = lines(num_rois_drug(i));
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end
        peak_mod_cont_peri = peak_mod_cont_per(roi_inds_drug(:,i),:);
        peak_mod_drug_peri = peak_mod_drug_per(roi_inds_drug(:,i),:);
        
        hi = zeros(length(in.plot_amps),1); % test null hypothesis (1 reject) on dc modulation within amplitude by drug i
        p_vali = zeros(length(in.plot_amps),1); % test null hypothesis (1 reject) on dc modulation within amplitude by drug i
        for j = 1:length(in.plot_amps)
            l = plot(ax,x_vals(:,j),[peak_mod_cont_peri(:,j),peak_mod_drug_peri(:,j)],...
                 'LineWidth',0.25); hold on; % color [in.amp_cols(j,:), 0.4]
            for k = 1:length(l)
                l(k).Color = dish_cols(k,:);
            end
            mean_peakmodij = mean([peak_mod_cont_peri(:,j),peak_mod_drug_peri(:,j)],1,'omitnan');
            sem_peakmodij = std([peak_mod_cont_peri(:,j),peak_mod_drug_peri(:,j)],0,1,'omitnan')/sqrt(num_rois_drug(i));
            errorbar(ax,x_vals(:,j),mean_peakmodij,sem_peakmodij,...
                'Color','k','LineStyle','-','LineWidth',2,'MarkerSize',10);    
            fprintf(' %s:\n',in.amp_labels{j});
            fprintf('   Change in control (mean +/- SEM): %.2f +/- %.2f %%\n',...
                    mean_peakmodij(1),sem_peakmodij(1));
            fprintf('   Change in %s (mean +/- SEM): %.2f +/- %.2f %%\n',in.drug_names{i},...
                    mean_peakmodij(2),sem_peakmodij(2));     
            % stats
            [hi(j),p_vali(j)] = ttest(peak_mod_cont_peri(:,j),peak_mod_drug_peri(:,j),...
                              'Alpha',0.05/length(in.plot_amps));
            if hi(j)                
                % calculate change in modulation (mean ± sem)
                [delta_mod,var_mod] = calcPerErrWithVariance(mean_peakmodij(2),mean_peakmodij(1),...
                                                            sem_peakmodij(2),sem_peakmodij(1)); 
                fprintf('   %.2f +/- %.2f change in modulation (p = %.3f)\n',...
                        delta_mod,var_mod,p_vali(j));
            else
                fprintf('  No significant difference in DC modulation by %s\n',in.amp_labels{j})
            end 
        end        
        % add significance markers
        for j = 1:length(in.plot_amps)
             if hi(j)
                plot(ax,mean(x_vals(:,j)),ax.YLim(2)*0.95,'r','Marker','*');
             end
        end
        box(ax,'off');
        ax.XLim = [x_vals(1)-0.25,x_vals(end)+0.25]; 
        ax.XTick = 1:length(in.plot_amps);
        ax.XTickLabel = in.amp_labels;
        if i == 1
            ylabel(ax,'Change in mean peak \Delta F/F_{0} (%)');
        end    
        title(ax,strrep(in.drug_names{i},'_',' '));
    end
    setAxesUniformYLim(fig);
    if in.save_figs
        printFig(fig,fig_fold,sprintf('peak_mod_control_vs_%s_wROI_%gdishes',...
                                in.drug_names{1},num_dishes)); 
    end
end