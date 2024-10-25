function [data_raw,def_raw,drug_data_raw,out,out_drug,varargout] = plotDCmod_drug_experiment_analysis(dataset_def_filename,reporter,roi_func_mode,...
                                            mode_str,load_compiled_dataset,varargin)
%PLOTDCMOD_DRUG_EXPERIMENT_ANALYSIS(dataset_def_filename,reporter,roi_func_mode,...
%                                            mode_str,load_compiled_dataset,varargin) 
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
in.plot_figs = 1:10; % 1 - mean peaks in control. vs each drug condition as line/scatter plot
                    % 2 - mean peaks within cell in control. vs each drug condition as line/scatter plot
                    % 3 - mean peaks in control. vs each drug condition as CDFs
                    % 4 - change in DC modulation within cell in control. vs each drug
                    % 5 - change in DC modulation within ROI in control. vs each drug
                    % 6 - CDFs of DC modulation across ROIs 
                    % 7 - Mean stim-averaged traces before and during DC OVERLAID in control and drug
                    % 8 - Mean stim-averaged traces before and during DC SIDE BY SIDE in control and drug
                    % 9 - Mean stim-averaged traces before DC SIDE BY SIDE in control and all drug (same fig)
                    % 10 - peak vs. ap within trains
                    % control and drug (side by side)
in.plot_amps = [-1,1];
in.plot_amps_units = 'mA';
in.amp_labels = [];
in.amp_cols = [0 0 1;1 0 0];
in.min_num_trials_per_amp = 2; % require number of trials at each amplitude
in.control_name = 'Control';
in.drug_names = {'1mM_KCl','4.5mM_KCl'};
in.drug_cols = {'b','r'};
in.include_title = 1; 
in.save_figs = 0;
in.data_raw = []; 
in.def_raw = []; 
in.drug_data_raw = []; 
in.cdf_bin_width = 0.1;
in.sort_amps = 1; % sort cells/ROI amplitude so is -1 mA suppressing, +1 mA facilitating polarity
in.norm_traces = 0; % 1 - average across ROIs then normalize mean peaks during to mean peaks before
                    % 2 - normalize peaks during to peaks before within
                    % ROI, then average and normalize to peaks before
in.scalebar_xlen = 0.1; % sec
in.scalebar_ylen = 0.05; % percent deltaF/F               
in.trace_ylim = []; 
in.cdf_figsize = [11.5 5.9];
in.trace_figsize = [11.5 5.9];
in.train_figsize = [23 4.4];
in.remove_nonbi_mod = 0;
in.analysis_fold = pwd; 
in.spike_thresh = 3; % peak = 3xstd(baseline) above baseline for spike
in.qc_settings = 'off'; 
in.exclude_dishes = [];
in.train_plot_mode = 'normroi'; % abs, normroi, cell, cell_normroi, cell_sep, cell_normroi_sep
in.train_add_regress = 0; 
in.peak_mode = 'raw'; % 'raw' to use peaks of raw trace or 'dF' to use peaks from trial/stim averaged dF trace
in.spike_window = 60*1e-3; % sec
in.print_level = 1;
[~,in.fig_fold] = fileparts(dataset_def_filename);
in = sl.in.processVarargin(in,varargin);
%%
fig_fold = fullfile(in.analysis_fold,in.fig_fold);
if isempty(in.data_raw) % load/make dataset
    dataset_def_file = fullfile(in.analysis_fold,'..','dataset_files',dataset_def_filename);
    opts = struct();
    opts.data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments');
    opts.dataset_fold = fullfile(in.analysis_fold,'datasets');
    opts.load_compiled_dataset = load_compiled_dataset;
    [data_raw,def_raw,drug_data_raw] = loadDataset(dataset_def_file,reporter,roi_func_mode,mode_str,...
                            opts);
else % Pre-loaded data was input to function
    data_raw = in.data_raw;
    def_raw = in.def_raw; 
    drug_data_raw = in.drug_data_raw; 
end
data = data_raw; 
def = def_raw; 
drug_data = drug_data_raw; 
if ~isempty(in.exclude_dishes)
    data(in.exclude_dishes) = [];
    def(in.exclude_dishes,:) = [];
    drug_data(in.exclude_dishes) = [];
    fprintf('Excluding dishes: ')
    fprintf('%g ',in.exclude_dishes)
    fprintf('\n')
end
%%
num_dishes = length(data); 
% num_amps = length(in.plot_amps);
% subthresh_amps = cellfun(@(x) str2num(x),def.subthresh_amps,'UniformOutput',0); %#ok<*ST2NM> 
% drug_subthresh_amps = cellfun(@(x) str2num(x),def.subthresh_amps_drug,'UniformOutput',0); %#ok<*ST2NM> 
% suprathresh_amps = cellfun(@(x) str2num(x),def.suprathresh_amps,'UniformOutput',0);
drug_name_dishes = def.drug_suffix; 
for d = in.drug_names
    drug_name_dishes(strncmp(d,drug_name_dishes,length(d))) = d;
end
if isempty(in.amp_labels)
    in.amp_labels = numericVec2chars(in.plot_amps,sprintf('%%g %s',in.plot_amps_units));
end
%% extract peaks and deltaF/F0 traces
% Control condition
out = extractSubthreshModResponses(data,def,in.plot_amps,in.min_num_trials_per_amp,...
                                   in.spike_thresh,'qc_settings',in.qc_settings,...
                                   'print_level',in.print_level,...
                                   'spike_window',in.spike_window);
% extract peaks and deltaF/F0 traces from drug condition
out_drug = extractSubthreshModResponses(drug_data,def,in.plot_amps,...
                                        in.min_num_trials_per_amp,in.spike_thresh,...
                                        'exclude_rois',out.exclude_rois,...
                                        'print_level',0,'qc_settings','off',...
                                        'spike_window',in.spike_window);

if in.sort_amps
    [out,flipped_amp_rois,flipped_amp_cells,removed_rois] = ...
        sortSubthreshModResponses(out,in.plot_amps,in.plot_amps,'sort_by_mode',1,...
                                'remove_nonbi_mod',in.remove_nonbi_mod);
    [out_drug,~,~] = ...
        sortSubthreshModResponses(out_drug,in.plot_amps,in.plot_amps,'sort_by_mode',3,...
                                'remove_nonbi_mod',removed_rois,...
                                'flipped_amp_rois',flipped_amp_rois,....
                                'flipped_amp_cells',flipped_amp_cells);
end

% peaks_before = out.peaks_before; 
% peaks_during = out.peaks_during;
dish_inds = out.dish_inds;
dF_al2_before = out.dF_al2_before;
dF_al2_during = out.dF_al2_during;
num_rois_per_dish = out.num_rois; 
num_rois_total = sum(num_rois_per_dish,'omitnan');
roi_in_dish_index = out.roi_in_dish_index;
% success_before_mat = out.success_before_mat;
% success_during_mat = out.success_during_mat;
% success_after_mat = out.success_after_mat;
% Pr_before = mean(success_before_mat,[2 3],'omitnan');

% peaks_before_drug = out_drug.peaks_before; 
% peaks_during_drug = out_drug.peaks_during;
% dish_inds_drug = out_drug.dish_inds{1};
% num_rois_per_dish_drug = out_drug.num_rois; 
% num_rois_total_drug = sum(num_rois_per_dish_drug);
% roi_in_dish_index_drug = out.roi_in_dish_index;

% dF_al2_before_drug = out_drug.dF_al2_before;
% dF_al2_during_drug = out_drug.dF_al2_during;
ta = data{1}.exp_settings(1).getTimeVector(size(dF_al2_before{1},1));
ta = ta - ta(data{1}.exp_settings(1).baseline_wind+1);
spike_window = in.spike_window; 
% spike_window = data{1}.plot_settings.spike_window; % used for peak calculation (sec)
spike_wind_inds = ta > 0 & ta < spike_window;
% stim averaged traces in each roi
% [num_time_points x num_rois x num_amps]
mean_dF_al2_before = out.mean_dF_al2_before;
mean_dF_al2_during = out.mean_dF_al2_during;
mean_dF_al2_before_drug = out_drug.mean_dF_al2_before;
mean_dF_al2_during_drug = out_drug.mean_dF_al2_during;

%% Get mean of before DC peaks in control vs. drug condition
% [num_rois x num_stim x num_amps]
% peaks_before_cont_mat = cell2mat(reshape(peaks_before,1,1,length(peaks_before)));
% peaks_before_drug_mat = cell2mat(reshape(peaks_before_drug,1,1,length(peaks_before_drug)));
% peaks_during_cont_mat = cell2mat(reshape(peaks_during,1,1,length(peaks_during)));
% peaks_during_drug_mat = cell2mat(reshape(peaks_during_drug,1,1,length(peaks_during_drug)));
% % average responses for each amplitude
% mean_peaks_cont_before = squeeze(mean(peaks_before_cont_mat,2,'omitnan'));
% mean_peaks_drug_before = squeeze(mean(peaks_before_drug_mat,2,'omitnan'));
% mean_peaks_cont_during = squeeze(mean(peaks_during_cont_mat,2,'omitnan'));
% mean_peaks_drug_during = squeeze(mean(peaks_during_drug_mat,2,'omitnan'));
% % Calculate peak modulation
% % [num_rois x num_amps]
if strcmp(in.peak_mode,'raw')    
    peak_mod_cont_per = out.peaks_mod_during_per;
    peak_mod_drug_per = out_drug.peaks_mod_during_per;
    % average responses before DC for all DC trials

    mean_peaks_cont_before_all = mean(out.mean_peaks_before,2,'omitnan');
    mean_peaks_drug_before_all = mean(out_drug.mean_peaks_before,2,'omitnan');    
else
    peak_mod_cont_per = out.peaks_mod_during_dF_per;
    peak_mod_drug_per = out_drug.peaks_mod_during_dF_per;
    mean_peaks_cont_before_all = mean(out.mean_peaks_before_dF,2,'omitnan');
    mean_peaks_drug_before_all = mean(out_drug.mean_peaks_before_dF,2,'omitnan');    
end
% TODO: GET CELL AVERAGES WITH PEAKS FROM AVERAGED TRACES (peak_mode =
% 'df')
mean_peaks_cont_before_cell = out.mean_peaks_before_cell; 
mean_peaks_drug_before_cell =  out_drug.mean_peaks_before_cell;
mean_peaks_cont_before_cell_all =  mean(mean_peaks_cont_before_cell,2);
mean_peaks_drug_before_cell_all =  mean(mean_peaks_drug_before_cell,2);
% Calculate peak modulation within cell
peak_mod_cont_cell_per = out.peaks_mod_during_cell_per;
peak_mod_drug_cell_per = out_drug.peaks_mod_during_cell_per;

% Get dish indices for each drug condition 
dish_inds_drug = cell(1,length(in.drug_names));
roi_inds_drug = false(length(dish_inds),length(in.drug_names)); % indices of rois with data in either condition
num_rois_drug = zeros(1,length(in.drug_names));
num_cells_drug = zeros(1,length(in.drug_names));
flipped_rois=  cell(1,length(in.drug_names));
for i = 1:length(in.drug_names)
    dish_inds_drug{i} = find(strcmp(drug_name_dishes,in.drug_names{i}))';
    for j = dish_inds_drug{i}
        roi_inds_drug(dish_inds == j,i) = true;
    end   
    num_rois_drug(i) = sum(roi_inds_drug(:,i));
    num_cells_drug(i) = length(dish_inds_drug{i});
    flipped_rois{i} = flipped_amp_rois(roi_inds_drug(:,i)); % flipped rois within drug condition
end

%% Plot mean peaks before DC within ROI in control. vs each drug condition as bar/scatter plot
if any(in.plot_figs == 1)
    fig = figure('Units','inches');
    if length(in.drug_names) > 1
        fig.Position(3:4) = [11.5 5.9]; 
    else
        fig.Position(3:4) = [4.3 6]; 
    end
    for i = 1:length(in.drug_names)
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end
        mean_peaks_cont_beforei = mean_peaks_cont_before_all(roi_inds_drug(:,i));
        mean_peaks_drug_beforei = mean_peaks_drug_before_all(roi_inds_drug(:,i));              
        for j = 1:num_rois_drug(i)        
            plot(ax,[1,2],100*[mean_peaks_cont_beforei(j),mean_peaks_drug_beforei(j)],...
                'Color',0.8*[1 1 1],'LineWidth',0.25); hold on;
        end
        e = errorbar(ax,[1,2],100*[mean(mean_peaks_cont_beforei,'omitnan');mean(mean_peaks_drug_beforei,'omitnan')],...
            100*[std(mean_peaks_cont_beforei,0,'omitnan');std(mean_peaks_drug_beforei,0,'omitnan')]/sqrt(num_rois_drug(i)),...
            'k-','LineWidth',2,'MarkerSize',10);
        box(ax,'off');
        ax.XTick = [1 2]; 
        ax.XTickLabel = {in.control_name,strrep(in.drug_names{i},'_',' ')};
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
        fprintf('Within ROI: Mean change (+/- SEM): %.3f +/- %.3f\n (n = %g boutons, %g cells)\n',...
                mean(per_changei),std(per_changei)/sqrt(num_rois_drug(i)),num_rois_drug(i),length(dish_inds_drug{i}));
    end
    if in.save_figs
        printFig(fig,fig_fold,sprintf('mean_peaks_before_scatter_rnb%g_%gdishes_pk%s',...
                                    in.remove_nonbi_mod,num_dishes,in.peak_mode)); 
    end
end
%% Plot mean peaks before within cell in control. vs each drug condition as bar/line plot
if any(in.plot_figs==2)
    fig = figure('Units','inches');
    if length(in.drug_names) > 1
        fig.Position(3:4) = [11.5 5.9]; 
    else
        fig.Position(3:4) = [4.3 6]; 
    end
    for i = 1:length(in.drug_names)
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end          
        mean_peaks_cont_beforei = mean_peaks_cont_before_cell_all(dish_inds_drug{i});
        mean_peaks_drug_beforei = mean_peaks_drug_before_cell_all(dish_inds_drug{i});       
        plotBarPlot_ErrBars_Points(100*[mean_peaks_cont_beforei,mean_peaks_drug_beforei],...
                                'x_vals',[1 2],'connect_pts',1,...
                                'bar_cols',{'k',in.drug_cols{i}},'pt_cols',0.4*[1 1 1],...
                                'pt_marker','.','pt_size',100,'bar_alphas',0.4,...
                                'bar_labels',{in.control_name,strrep(in.drug_names{i},'_',' ')});
        % plotBarPlot_ErrBars_Points(100*mean_peaks_drug_beforei,'x_vals',[4 5],'connect_pts',1,...
        %                         'bar_cols',in.drug_cols{i},'pt_cols',in.drug_cols{i},...
        %                         'pt_marker','.','pt_size',100,'bar_alphas',0.4)                
        ax.XTickLabelRotation = 30; 
        if i == 1
            ylabel(ax,'Mean peak \Delta F/F_{0} (%)');
        end
        % ax.XLim = [0.9 2.1];
        % paired t-test
        if length(dish_inds_drug{i}) > 2
            [h,p1] = ttest(mean_peaks_cont_beforei,mean_peaks_drug_beforei);
            [p2,h] = ranksum(mean_peaks_cont_beforei,mean_peaks_drug_beforei);
            if h
                plot(ax,1.5,ax.YLim(2)*0.95,'r','Marker','*');
            end 
        end
        if in.include_title
            title(sprintf('%g boutons in %g cells',num_rois_drug(i),length(dish_inds_drug{i})))
        end
        % average within cell
        per_changei = 100*(mean_peaks_drug_beforei-mean_peaks_cont_beforei)./mean_peaks_cont_beforei; 
        fprintf('Within cell: Mean change (+/- SEM): %.3f +/- %.3f\n (n = %g boutons, %g cells)\n',...
                mean(per_changei),std(per_changei)/sqrt(num_rois_drug(i)),num_rois_drug(i),length(dish_inds_drug{i}));
        if length(dish_inds_drug{i}) > 2
            fprintf('    paired t-test p = %.3f\n',p1);
            fprintf('    Wilcoxon rank sum p = %.3f\n',p2);
        end
        ax.FontName = 'Arial';
        ax.FontSize = 22; 
    end
    setAxesUniformLim(fig,'YLim');
    if in.save_figs
        printFig(fig,fig_fold,sprintf('mean_peaks_before_bar_wcell_rnb%g_%gdishes_pk%s',...
                                    in.remove_nonbi_mod,num_dishes,in.peak_mode)); 
    end
end
%% Plot mean peaks before within ROI in control. vs each drug condition as CDFs
if any(in.plot_figs == 3)
    fprintf('********CDF of mean peaks before DC, effect of drug********\n')
    fig = figure('Units','inches');
    % fig.Position(3:4) = [11.5 5.9]; 
    fig.Position(3:4) = [5 2.25]; 
    for i = 1:length(in.drug_names)
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end
        mean_peaks_cont_beforei = mean_peaks_cont_before_all(roi_inds_drug(:,i));
        mean_peaks_drug_beforei = mean_peaks_drug_before_all(roi_inds_drug(:,i));       
        [Nc,edgesc] = histcounts(mean_peaks_cont_beforei,...
                        'BinWidth',in.cdf_bin_width,'Normalization','cdf');
        [Nd,edgesd] = histcounts(mean_peaks_drug_beforei,...
                        'BinWidth',in.cdf_bin_width,'Normalization','cdf');
        plot(edgesc(1:end-1)+diff(edgesc(1:2))/2,Nc,'k','LineWidth',1.5);
        hold on;
        plot(edgesd(1:end-1)+diff(edgesd(1:2))/2,Nd,in.drug_cols{i},'LineWidth',1.5);
        box(ax,'off');       
        if i == 1
            ylabel(ax,'Proportion')
        end
        xlabel(ax,'Peak \DeltaF/F_{0}')
        ax.YLim = [0 1];
        % [h,p] = ttest(mean_peaks_cont_beforei,mean_peaks_drug_beforei);
        % [h,p] = kstest2(mean_peaks_cont_beforei,mean_peaks_drug_beforei);
        [p,h] = signrank(mean_peaks_cont_beforei,mean_peaks_drug_beforei);
        % if h
            % plot(ax,ax.XLim(1) + diff(ax.XLim)*0.5,ax.YLim(2),'r','Marker','*');            
        % end 
        fprintf('Wilcoxon signed rank test, effect of %s drug on mean peak before DC (%g boutons in %g cells): p = %f\n',...
                    in.drug_names{i},num_rois_drug(i),length(dish_inds_drug{i}),p);
        legend(ax,{in.control_name,strrep(in.drug_names{i},'_',' ')},'Location','southeast');
        if in.include_title
            title(sprintf('%g boutons in %g cells',num_rois_drug(i),length(dish_inds_drug{i})))
        end
        ax.FontName = 'Arial';
        ax.FontSize = 10; 
    end
    % setAxesUniformLim(fig,'XLim',[0 0.8]);
    if in.save_figs
        printFig(fig,fig_fold,sprintf('mean_peaks_before_CDF_rnb%g_%gdishes_pk%s',...
                                      in.remove_nonbi_mod,num_dishes,in.peak_mode)); 
    end
end
%% Plot mean peaks before and during within cell in control vs. in drug
% TODO
%% Quantify modulation within cell in control vs. in drug - bar plot
if any(in.plot_figs == 4)
    fig = figure('Units','inches');
    fig.Position(3:4) = [11.5 5.9]; 
    x_vals = (1:length(in.plot_amps)) + [-0.25;0.25];
    % x_vals = x_vals(:);
    for i = 1:length(in.drug_names)
        fprintf('\n***Within-cell DC modulation in %s:\n',in.drug_names{i});
        dish_cols = lines(num_rois_drug(i));
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end        
        peak_mod_cont_cell_peri = peak_mod_cont_cell_per(dish_inds_drug{i},:);
        peak_mod_drug_cell_peri = peak_mod_drug_cell_per(dish_inds_drug{i},:);
        if length(dish_inds_drug{i}) > 2
            [ranovatbl,rm] = run_2way_rm_anova(cat(3,peak_mod_cont_cell_peri,...
                                                       peak_mod_drug_cell_peri),...
                                                       'var_names',...
                                                       {'Amp','Drug'});        
            if ranovatbl.pValue(4) < 0.05
                fprintf('   2-way RM ANOVA: Drug x amp interaction significant (p = %.2f)\n',...
                    ranovatbl.pValue(4))
            else
                fprintf('   2-way RM ANOVA: Drug x amp interaction not significant (p = %.2f)\n',...
                    ranovatbl.pValue(4))
            end
        end
        % main effect of amp on % modulation (2)
        % main effect of drug on % modulation (3)
        % interaction (effect of amp changes with drug condition) (4)
        hi = zeros(length(in.plot_amps),1); % test null hypothesis (1 reject) on dc modulation within amplitude by drug i
        p_vali = zeros(length(in.plot_amps),1); % p values 
        % x_vals = {[1 2],[4 5]};
        % for k = 1:2
        %     plotBarPlot_ErrBars_Points([peak_mod_cont_cell_peri(:,k),peak_mod_drug_cell_peri(:,k)],...
        %                             'x_vals',x_vals{k},'connect_pts',1,...
        %                             'bar_cols',{'k',in.drug_cols{i}},'pt_cols',0.4*[1 1 1],...
        %                             'pt_marker','.','pt_size',100,'bar_alphas',0.4,...
        %                             'bar_labels',{in.control_name,strrep(in.drug_names{i},'_',' ')});
        % end
        for j = 1:length(in.plot_amps)
            l = plot(ax,x_vals(:,j),[peak_mod_cont_cell_peri(:,j),peak_mod_drug_cell_peri(:,j)],...
                 'LineWidth',0.25); hold on; % color [in.amp_cols(j,:), 0.4]
            for k = 1:length(l)
                l(k).Color = dish_cols(k,:);
            end
            mean_peakmodij = mean([peak_mod_cont_cell_peri(:,j),...
                                peak_mod_drug_cell_peri(:,j)],1,'omitnan');
            sem_peakmodij = std([peak_mod_cont_cell_peri(:,j),...
                                peak_mod_drug_cell_peri(:,j)],0,1,'omitnan')/sqrt(num_cells_drug(i));
            errorbar(ax,x_vals(:,j),mean_peakmodij,sem_peakmodij,...
                'Color','k','LineStyle','-','LineWidth',2,'MarkerSize',10);    
            fprintf(' %s:\n',in.amp_labels{j});
            fprintf('   Change in control (mean +/- SEM): %.2f +/- %.2f %%\n',...
                    mean_peakmodij(1),sem_peakmodij(1));
            fprintf('   Change in %s (mean +/- SEM): %.2f +/- %.2f %%\n',in.drug_names{i},...
                    mean_peakmodij(2),sem_peakmodij(2));  
            if length(dish_inds_drug{i}) > 2                
                % stats
                % [hi(j),p_vali(j)] = ttest(peak_mod_cont_cell_peri(:,j),peak_mod_drug_cell_peri(:,j),...
                %                    'Alpha',0.05/length(in.plot_amps)); % use bonferroni correction
                [p_vali(j),hi(j)] = signrank(peak_mod_cont_cell_peri(:,j),peak_mod_drug_cell_peri(:,j),...
                                   'Alpha',0.05/length(in.plot_amps)); % use bonferroni correction
                if hi(j)                
                    % calculate change in modulation (mean ± sem)
                    [delta_mod,var_mod] = calcPerErrWithVariance(mean_peakmodij(2),mean_peakmodij(1),...
                                                                sem_peakmodij(2),sem_peakmodij(1)); 
                    fprintf('   %.2f +/- %.2f change in modulation (p = %.3f, signrank)\n',...
                            delta_mod,var_mod,p_vali(j));
                else
                    fprintf('  No significant difference in DC modulation by %s (p = %.3f, signrank)\n',...
                            in.amp_labels{j},p_vali(j))
                end             
            end
        end        
        if length(dish_inds_drug{i}) > 2
            % add significance markers
            for j = 1:length(in.plot_amps)
                 if hi(j)
                    plot(ax,mean(x_vals(:,j)),ax.YLim(2)*0.95,'r','Marker','*');
                 end
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
    if length(in.drug_names) > 1
        setAxesUniformLim(fig,'YLim');
    end
    if in.save_figs
        printFig(fig,fig_fold,sprintf('peak_mod_control_vs_%s_wcell_rnb%g_%gdishes_pk%s',...
                                in.drug_names{1},in.remove_nonbi_mod,num_dishes,in.peak_mode)); 
    end
end
%% Quantify modulation within ROI in control vs. in drug - bar plot
if any(in.plot_figs == 5)
    fig = figure('Units','inches');
    fig.Position(3:4) = [11.5 5.9];     
    x_vals = (1:length(in.plot_amps)) + [-0.25;0.25];
    % x_vals = x_vals(:);
    for i = 1:length(in.drug_names)
        fprintf('\n***Within-ROI DC modulation in %s:\n',in.drug_names{i});
        dish_cols = lines(num_rois_drug(i));
        if length(in.drug_names) > 1
            ax = subplot(1,length(in.drug_names),i);           
        else
            ax = gca;
        end
        peak_mod_cont_peri = peak_mod_cont_per(roi_inds_drug(:,i),:);
        peak_mod_drug_peri = peak_mod_drug_per(roi_inds_drug(:,i),:);        
        [ranovatbl,rm] = run_2way_rm_anova(cat(3,peak_mod_cont_peri,...
                                               peak_mod_drug_peri),...
                                               'var_names',...
                                               {'Amp','Drug'});   
        % if mauchly(rm).pValue < 0.05
        %     fprintf('Failed mauchly test for sphericity, apply epsilon correction of p-values\n')
        %     eps_factors = epsilon(rm);
        % 
        % end
        hi = zeros(length(in.plot_amps),1); % test null hypothesis (1 reject) on dc modulation within amplitude by drug i
        p_vali = zeros(length(in.plot_amps),1); % test null hypothesis (1 reject) on dc modulation within amplitude by drug i
        % if i == 2
        %     peak_mod_cont_peri = peak_mod_cont_peri(flipped_rois{i},:);
        %     peak_mod_drug_peri = peak_mod_drug_peri(flipped_rois{i},:);
        % end
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
            % [hi(j),p_vali(j)] = ttest(peak_mod_cont_peri(:,j),peak_mod_drug_peri(:,j),...
            %                   'Alpha',0.05/length(in.plot_amps));
            [p_vali(j),hi(j)] = signrank(peak_mod_cont_peri(:,j),peak_mod_drug_peri(:,j),...
                              'Alpha',0.05/length(in.plot_amps));
            if hi(j)                
                % calculate change in modulation (mean ± sem)
                [delta_mod,var_mod] = calcPerErrWithVariance(mean_peakmodij(2),mean_peakmodij(1),...
                                                            sem_peakmodij(2),sem_peakmodij(1)); 
                fprintf('   %.2f +/- %.2f change in modulation (p = %.3f, signrank)\n',...
                        delta_mod,var_mod,p_vali(j));
            else
                fprintf('  No significant difference in DC modulation by %s (p = %.3f, signrank)\n',...
                    in.amp_labels{j},p_vali(j))
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
        if in.include_title
            title(ax,strrep(in.drug_names{i},'_',' '));
        end
    end
    if length(in.drug_names) > 1
        setAxesUniformLim(fig,'YLim');
    end
    if in.save_figs
        printFig(fig,fig_fold,sprintf('peak_mod_control_vs_%s_wROI_rnb%g_%gdishes_pk%s',...
                                in.drug_names{1},in.remove_nonbi_mod,num_dishes,in.peak_mode)); 
    end
end
%% Plot modulation within ROI in control vs. in drug - CDFs
if any(in.plot_figs == 6)             
    for i = 1:length(in.drug_names)
        fig = figure('Units','inches');
        fig.Position(3:4) = in.cdf_figsize;                
        peak_mod_cont_peri = peak_mod_cont_per(roi_inds_drug(:,i),:);
        peak_mod_drug_peri = peak_mod_drug_per(roi_inds_drug(:,i),:);
        
        hi = zeros(length(in.plot_amps),1); % test null hypothesis (1 reject) on dc modulation within amplitude by drug i
        p_vali = zeros(length(in.plot_amps),1); % test null hypothesis (1 reject) on dc modulation within amplitude by drug i
        for j = 1:length(in.plot_amps)
            if length(in.plot_amps) > 1
                ax = subplot(1,length(in.plot_amps),j);
            else
                ax = gca;
            end
            [Nc,edgesc] = histcounts(peak_mod_cont_peri(:,j),'BinWidth',...
                                        in.cdf_bin_width*100,'Normalization','cdf');
            [Nd,edgesd] = histcounts(peak_mod_drug_peri(:,j),'BinWidth',...
                                    in.cdf_bin_width*100,'Normalization','cdf');
            plot([0 0],[0 1],'--','Color',0.6*[1 1 1]); hold on;
            l1 = plot(edgesc(1:end-1)+diff(edgesc(1:2))/2,Nc,'k','LineWidth',1);            
            l2 = plot(edgesd(1:end-1)+diff(edgesd(1:2))/2,Nd,...
                        'Color',in.drug_cols{i},'LineWidth',1);            
            % stats
            [p_vali(j),hi(j)] = signrank(peak_mod_cont_peri(:,j),...
                                        peak_mod_drug_peri(:,j),...
                                        'Alpha',0.05/length(in.plot_amps));                                    
            box(ax,'off');
            ax.YLim = [0 1];             
            if j == 1
                ylabel(ax,'Proportion')
            end            
            xlabel(ax,'Change in mean peak \Delta F/F_{0} (%)')            
            if in.include_title
                title(sprintf('%g %s',in.plot_amps(j),in.plot_amps_units))
            end
            if hi(j)
                plot(ax,ax.XLim(1) + diff(ax.XLim)*0.5,ax.YLim(2)*0.95,'r','Marker','*');
            end
            if j == length(in.plot_amps)
                legend(ax,[l1,l2],{in.control_name,strrep(in.drug_names{i},'_',' ')},'Location','southeast');
            end            
            if ax.XLim(2) > 500
                ax.XLim(2) = 500; 
            end
        end                
        if in.include_title
            sgtitle(sprintf('%g boutons in %g cells',...
                            num_rois_drug(i),length(dish_inds_drug{i})));        
        end
        % if ax.XLim(2) > 500
        %     setAxesUniformLim(fig,'XLim',[-100 500]);
        % else
        %     setAxesUniformLim(fig,'XLim');
        % end
        if in.save_figs
            printFig(fig,fig_fold,sprintf('peak_mod_control_vs_%s_wROI_%gdishes_rnb%g_CDF_pk%s',...
                                in.drug_names{i},num_dishes,in.remove_nonbi_mod,in.peak_mode));
        end
    end        
end
%% Mean stim-averaged traces before and during DC OVERLAID in control and drug
if any(in.plot_figs == 7)    
    for i = 1:length(in.drug_names)
        fig = figure('Units','inches');
        fig.Position(3:4) = in.trace_figsize;
        % mean/sem before and during - control
        if in.norm_traces == 2 % normalize within ROI by mean before
            peaks_beforei = max(mean_dF_al2_before(spike_wind_inds,:,:),[],1);            
            peaks_before_drugi = max(mean_dF_al2_before_drug(spike_wind_inds,:,:),[],1);            
            mean_dF_al2_duringi = mean_dF_al2_during./peaks_beforei;
            mean_dF_al2_beforei = mean_dF_al2_before./peaks_beforei;
            mean_dF_al2_during_drugi = mean_dF_al2_during_drug./peaks_before_drugi;
            mean_dF_al2_before_drugi = mean_dF_al2_before_drug./peaks_before_drugi;
        else
            mean_dF_al2_duringi = mean_dF_al2_during;
            mean_dF_al2_beforei = mean_dF_al2_before;
            mean_dF_al2_during_drugi = mean_dF_al2_during_drug;
            mean_dF_al2_before_drugi = mean_dF_al2_before_drug;
        end
        for j = 1:length(in.plot_amps)
            if length(in.plot_amps) > 1
                ax = subplot(1,length(in.plot_amps),j);
            else
                ax = gca;
            end            
            mean_dF_before = mean(mean_dF_al2_beforei(:,roi_inds_drug(:,i),j),2);
            sem_dF_before= std(mean_dF_al2_beforei(:,roi_inds_drug(:,i),j),0,2)/sqrt(sum(roi_inds_drug(:,i)));
            mean_dF_during = mean(mean_dF_al2_duringi(:,roi_inds_drug(:,i),j),2);
            sem_dF_during = std(mean_dF_al2_duringi(:,roi_inds_drug(:,i),j),0,2)/sqrt(sum(roi_inds_drug(:,i)));
            % mean/sem before and during - drug i
            mean_dF_before_drug = mean(mean_dF_al2_before_drugi(:,roi_inds_drug(:,i),j),2);
            sem_dF_before_drug = std(mean_dF_al2_before_drugi(:,roi_inds_drug(:,i),j),0,2)/sqrt(sum(roi_inds_drug(:,i)));
            mean_dF_during_drug = mean(mean_dF_al2_during_drugi(:,roi_inds_drug(:,i),j),2);
            sem_dF_during_drug = std(mean_dF_al2_during_drugi(:,roi_inds_drug(:,i),j),0,2)/sqrt(sum(roi_inds_drug(:,i)));
            if in.norm_traces > 0 % if norm_traces = 1, normalizes after averaging across ROIs, otherwise normalizes means of within-ROI normalized traces
               norm_factor = max(mean_dF_before);
               norm_factor_drug = max(mean_dF_before_drug);               
            else
                norm_factor = 1; norm_factor_drug = 1; 
            end
            % Plot
            shadedErrorBar(ta,mean_dF_before/norm_factor,sem_dF_before/norm_factor,'lineProps','k'); 
            hold on; 
            shadedErrorBar(ta,mean_dF_during/norm_factor,sem_dF_during/norm_factor,'lineProps',{'Color',in.amp_cols(j,:)});
            % 
            shadedErrorBar(ta+range(ta)+0.1,mean_dF_before_drug/norm_factor_drug,...
                            sem_dF_before_drug/norm_factor_drug,'lineProps','k'); 
            hold on; 
            shadedErrorBar(ta+range(ta)+0.1,mean_dF_during_drug/norm_factor_drug,...
                           sem_dF_during_drug/norm_factor_drug,...
                           'lineProps',{'Color',in.amp_cols(j,:)});
            axis(ax,'off');            
            if in.include_title
                title(sprintf('%g %s',in.plot_amps(j),in.plot_amps_units))
            end
        end
        setAxesUniformLim(fig,'YLim');  
        % if in.norm_traces
        %     scalebar_ylen = 0.2; % 20% peak before dc
        % else
        %     scalebar_ylen = 0.05; % 5% deltaF/F
        % end
        plot(fig.Children(end),[ta(1),ta(1),ta(1)+in.scalebar_xlen],[ax.YLim(2)-in.scalebar_ylen,ax.YLim(2),ax.YLim(2)],...
            'k','LineWidth',2); % 100 ms, 5% deltaF/F 
        sgtitle(sprintf('%g boutons in %g cells',...
                        num_rois_drug(i),length(dish_inds_drug{i})));   
        if in.save_figs
            printFig(fig,fig_fold,sprintf('dF_traces_control_vs_%s_%gdishes_rnb%g_norm%g',...
                in.drug_names{i},num_dishes,in.remove_nonbi_mod,in.norm_traces));
        end
    end
end
%% Mean stim-averaged traces before and during DC SIDE BY SIDE in control and drug
if any(in.plot_figs == 8)    
    for i = 1:length(in.drug_names)        
        fig = figure('Units','inches');
        fig.Position(3:4) = in.trace_figsize;

        % mean/sem before and during - control
        if in.norm_traces == 2 % normalize within ROI by mean before
            peaks_beforei = max(mean_dF_al2_before(spike_wind_inds,:,:),[],1);
            peaks_before_drugi = max(mean_dF_al2_before_drug(spike_wind_inds,:,:),[],1);
            mean_dF_al2_duringi = mean_dF_al2_during./peaks_beforei;
            mean_dF_al2_beforei = mean_dF_al2_before./peaks_beforei;
            mean_dF_al2_during_drugi = mean_dF_al2_during_drug./peaks_before_drugi;
            mean_dF_al2_before_drugi = mean_dF_al2_before_drug./peaks_before_drugi;
        else
            mean_dF_al2_duringi = mean_dF_al2_during;
            mean_dF_al2_beforei = mean_dF_al2_before;
            mean_dF_al2_during_drugi = mean_dF_al2_during_drug;
            mean_dF_al2_before_drugi = mean_dF_al2_before_drug;
        end
        for j = 1:length(in.plot_amps)
            if length(in.plot_amps) > 1
                ax = subplot(1,length(in.plot_amps),j);
            else
                ax = gca;
            end           
            mean_dF_before = mean(mean_dF_al2_beforei(:,roi_inds_drug(:,i),j),2);
            sem_dF_before= std(mean_dF_al2_beforei(:,roi_inds_drug(:,i),j),0,2)/sqrt(sum(roi_inds_drug(:,i)));
            mean_dF_during = mean(mean_dF_al2_duringi(:,roi_inds_drug(:,i),j),2);
            sem_dF_during = std(mean_dF_al2_duringi(:,roi_inds_drug(:,i),j),0,2)/sqrt(sum(roi_inds_drug(:,i)));
            % mean/sem before and during - drug i
            mean_dF_before_drug = mean(mean_dF_al2_before_drugi(:,roi_inds_drug(:,i),j),2);
            sem_dF_before_drug = std(mean_dF_al2_before_drugi(:,roi_inds_drug(:,i),j),0,2)/sqrt(sum(roi_inds_drug(:,i)));
            mean_dF_during_drug = mean(mean_dF_al2_during_drugi(:,roi_inds_drug(:,i),j),2);
            sem_dF_during_drug = std(mean_dF_al2_during_drugi(:,roi_inds_drug(:,i),j),0,2)/sqrt(sum(roi_inds_drug(:,i)));
            if in.norm_traces > 0 % if norm_traces = 1, normalizes after averaging across ROIs, otherwise normalizes means of within-ROI normalized traces
               norm_factor = max(mean_dF_before);
               norm_factor_drug = max(mean_dF_before_drug);
            else
                norm_factor = 1; norm_factor_drug = 1; 
            end
            % Plot
            shadedErrorBar(ta,mean_dF_before/norm_factor,sem_dF_before/norm_factor,'lineProps','k'); 
            hold on; 
            shadedErrorBar(ta+range(ta)+0.1,mean_dF_during/norm_factor,sem_dF_during/norm_factor,'lineProps',{'Color',in.amp_cols(j,:)});
            % 
            shadedErrorBar(ta+2*(range(ta)+0.1),mean_dF_before_drug/norm_factor_drug,...
                            sem_dF_before_drug/norm_factor_drug,'lineProps','k'); 
            hold on; 
            shadedErrorBar(ta+3*(range(ta)+0.1),mean_dF_during_drug/norm_factor_drug,...
                           sem_dF_during_drug/norm_factor_drug,...
                           'lineProps',{'Color',in.amp_cols(j,:)});
            axis(ax,'off');            
            if in.include_title
                title(sprintf('%g %s',in.plot_amps(j),in.plot_amps_units))
            end
            if in.norm_traces == 2
                plot(ax.XLim,[1 1],'--','Color',0.6*[1 1 1]);
            end
        end
        if isempty(in.trace_ylim)
            setAxesUniformLim(fig,'YLim');  
        else
            setAxesUniformLim(fig,'YLim',in.trace_ylim);  
        end
        % if in.norm_traces
        %     scalebar_ylen = 0.2; % 20% peak before dc
        % else
        %     scalebar_ylen = 0.05; % 5% deltaF/F
        % end
        plot(fig.Children(end),[ta(1),ta(1),ta(1)+in.scalebar_xlen],[ax.YLim(2)-in.scalebar_ylen,ax.YLim(2),ax.YLim(2)],...
            'k','LineWidth',2); % 100 ms, 5% deltaF/F                
        sgtitle(sprintf('%g boutons in %g cells',...
                        num_rois_drug(i),length(dish_inds_drug{i})));           
        if in.save_figs
            printFig(fig,fig_fold,sprintf('dF_traces_control_vs_%s_%gdishes_rnb%g_norm%g_sbs',...
                in.drug_names{i},num_dishes,in.remove_nonbi_mod,in.norm_traces));
        end
    end
end
%% Mean stim-averaged traces before DC SIDE BY SIDE in control and all drug (same fig)
if any(in.plot_figs == 9)    
    fig = figure('Units','inches');
    fig.Position(3:4) = in.trace_figsize;    
    for i = 1:length(in.drug_names)  
        % mean/sem before and during - control
        if in.norm_traces == 1 % normalize within trial for all ROIs            
            peaks_beforei = max(mean_dF_al2_before(spike_wind_inds,:,:),[],1);            
            mean_dF_al2_before_drugi = mean_dF_al2_before_drug./peaks_beforei;
            mean_dF_al2_beforei = mean_dF_al2_before./peaks_beforei;                        
        else
            mean_dF_al2_before_drugi = mean_dF_al2_before_drug;
            mean_dF_al2_beforei = mean_dF_al2_before;
        end
        mean_dF_before_all = mean(mean_dF_al2_beforei(:,roi_inds_drug(:,i),:),3); % mean across plot_amps, within ROI
        mean_dF_before = mean(mean_dF_before_all,2); % mean across all ROIs, plot_amps        
        sem_dF_before= std(mean_dF_before_all,0,2)/sqrt(sum(roi_inds_drug(:,i)));

        % mean/sem before and during - drug i
        mean_dF_before_drug_all = mean(mean_dF_al2_before_drugi(:,roi_inds_drug(:,i),:),3); % mean across plot_amps, within ROI
        mean_dF_before_drug = mean(mean_dF_before_drug_all,2); % mean across all ROIs, plot_amps        
        sem_dF_before_drug = std(mean_dF_before_drug_all,0,2)/sqrt(sum(roi_inds_drug(:,i)));

        if in.norm_traces == 2 % if norm_traces = 2, normalizes after averaging across ROIs, otherwise normalizes means of within-ROI normalized traces
            norm_factor = max(mean_dF_before,[],1);     
            norm_factor_drug = norm_factor;
        else
            norm_factor = 1; norm_factor_drug=1; 
        end
        ax = subplot(1,length(in.drug_names),i);
        % Plot
        shadedErrorBar(ta,mean_dF_before/norm_factor,sem_dF_before/norm_factor,...
                        'lineProps',{'Color','k','LineWidth',1.5}); 
        hold on; 
        shadedErrorBar(ta+range(ta)+0.1,mean_dF_before_drug/norm_factor_drug,...
                        sem_dF_before_drug/norm_factor_drug,...
                        'lineProps',{'Color',in.drug_cols{i},'LineWidth',1.5});
        % axis(ax,'off');                                  
        if isempty(in.trace_ylim)
            setAxesUniformLim(fig,'YLim');  
        else
            setAxesUniformLim(fig,'YLim',in.trace_ylim);  
        end
        % if in.norm_traces
        %     scalebar_ylen = 0.2; % 20% peak before dc
        % else
        %     scalebar_ylen = 0.05; % 5% deltaF/F
        % end
        % scale bar        
        axis off; 
        % ax.XAxis.Visible = 'off';        
        if i == 1
            ylabel('\Delta F/F_{0}');
        end
        if i == length(in.drug_names)
            plot(fig.Children(end),[ta(1),ta(1),ta(1)+in.scalebar_xlen],[ax.YLim(2)-in.scalebar_ylen,ax.YLim(2),ax.YLim(2)],...
                'k','LineWidth',2); % 100 ms, 5% deltaF/F                
        end
        if in.norm_traces == 2
            plot(ax.XLim,[1 1],'--','Color',0.6*[1 1 1]);
        end
        % sgtitle(sprintf('%g boutons in %g cells',...
        %                 num_rois_drug(i),length(dish_inds_drug{i})));           
    end
    if in.save_figs
        printFig(fig,fig_fold,sprintf('dF_traces_before_control_vs_%s_%gdishes_rnb%g_norm%g_sbs',...
            in.drug_names{i},num_dishes,in.remove_nonbi_mod,in.norm_traces));
    end
end
%% Plot peaks across trains
if any(in.plot_figs == 10)
    train_data = cell(1,length(in.drug_names));
    for i = 1:length(in.drug_names)
        if contains(in.train_plot_mode,'cell')
            train_plot_inds = dish_inds_drug{i};            
        else
            train_plot_inds = roi_inds_drug(:,i);
        end
        train_data{i} = cell(1,2); % {cont, drug}
        for k = 1:2
            if k == 1
                outi = out;
                cond_name = in.control_name;
                fig_name = sprintf('peak_vs_APnum_%gdishes_%gROIs_%s_pk%s_%s-%g',...
                    num_dishes,num_rois_total,...
                    in.train_plot_mode,in.peak_mode,cond_name,k);
            else
                outi = out_drug;
                cond_name = in.drug_names{i};
                fig_name = sprintf('peak_vs_APnum_%gdishes_%gROIs_%s_pk%s_%s',...
                    num_dishes,num_rois_total,...
                    in.train_plot_mode,in.peak_mode,cond_name);
            end            
            if in.train_add_regress
                fig_name = [fig_name '_fit'];
                fig_name2 = [fig_name '_slope_bar'];
            else
                fig_name2 = '';
            end
            fig = figure('Units','inches');         
            fig.Position(3:4) = in.train_figsize; 
            [mean_train,var_train] = plotSubthreshModPeakTrains(outi,...
                                        in.train_plot_mode,'fig_name',fig_name,...
                                        'fig_fold',in.fig_fold,'cond_labels',in.amp_labels,...
                                        'save_fig',in.save_figs,'cond_name',cond_name,...
                                        'include_inds',train_plot_inds,'add_regress',...
                                        in.train_add_regress,'fig_name2',fig_name2,...
                                        'peak_mode',in.peak_mode);
            train_data{i}{k} = [mean_train,var_train];
        end
    end
    varargout = {train_data};    
else
    varargout = {}; 
end

end