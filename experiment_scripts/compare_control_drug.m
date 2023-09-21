data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '230908';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish5';

drug_name = '4.5mM_KCl';

roi_func_mode = 'separate';
transform_type = 'displace'; % 'none' or 'displace'         
registration_rec = fullfile(data_fold,exp_date,reporter,dish,'control_4mABi_1mAG',...
                               'control_4mABi_1mAG.fits'); 
registration_rec_drug = fullfile(data_fold,exp_date,reporter,dish,'control_4mABi_1mAG',...
                               'control_4mABi_1mAG.fits'); 
roiset_filename = 'RoiSet_pc_pos2.zip';
roiset_filename_drug = 'RoiSet_pc_pos2.zip';
amps = [-1 1];
save_figs = 1;
%% Load data
roiset_filename_no_ext = getROIset_name(roiset_filename,...
                                         transform_type,...
                                            registration_rec);  
roiset_filename_no_ext_drug = getROIset_name(roiset_filename_drug,...
                                         transform_type,...
                                            registration_rec_drug);  
control_summary_datafile = sprintf('%s_%s_%s_%s_%s_train',exp_date,reporter,dish,roi_func_mode,...
                                    roiset_filename_no_ext);
drug_summary_datafile = sprintf('%s_%s_%s_%s_%s_%s_train',exp_date,reporter,dish,roi_func_mode,...
                                    roiset_filename_no_ext_drug,drug_name);
out_cont = load(fullfile(data_fold,exp_date,reporter,dish,control_summary_datafile));
out_drug = load(fullfile(data_fold,exp_date,reporter,dish,drug_summary_datafile));
fprintf('Loaded data\n')
fig_fold = ['figs_' roiset_filename_no_ext];
%%  
num_rois = out_cont.rois_all{1}{1}.num_rois;
num_conditions = min(length(out_cont.conditions),length(out_drug.conditions)); 
dF_aligned2_cont = out_cont.deltaF_F0_aligned2_all;
dF_aligned2_drug = out_drug.deltaF_F0_aligned2_all;
mean_dF_aligned2_cont = cellfun(@(x) mean(x,[4 5]),dF_aligned2_cont,'UniformOutput',0);
mean_dF_aligned2_drug = cellfun(@(x) mean(x,[4 5]),dF_aligned2_drug,'UniformOutput',0);
ta = out_cont.exp_settings(1).getTimeVector(size(mean_dF_aligned2_cont{1},1));
ta = ta - ta(out_cont.exp_settings(1).baseline_wind+1);
peaks_cont = out_cont.peaks_deltaF_F0_all;
peaks_drug = out_drug.peaks_deltaF_F0_all;

mean_peaks_cont = cellfun(@(x) mean(x,[3 4]),out_cont.peaks_deltaF_F0_all,'UniformOutput',0);
mean_peaks_drug = cellfun(@(x) mean(x,[3 4]),out_drug.peaks_deltaF_F0_all,'UniformOutput',0);

% collapse before peaks from all conditions
mean_peaks_cont_before = mean(cell2mat(cellfun(@(x) x(1,:),mean_peaks_cont,'UniformOutput',0)'),1);
mean_peaks_drug_before = mean(cell2mat(cellfun(@(x) x(1,:),mean_peaks_drug,'UniformOutput',0)'),1);

mean_peaks_cont_during = cell2mat(cellfun(@(x) x(2,:),mean_peaks_cont,'UniformOutput',0)');
mean_peaks_drug_during = cell2mat(cellfun(@(x) x(2,:),mean_peaks_drug,'UniformOutput',0)');
%%
% bin_width = 0.02; 
% [mean_peaks_cont_bins,edges_cont] = histcounts(mean_peaks_cont_before,...
%                     'BinWidth',bin_width,'Normalization','probability');
% [mean_peaks_drug_bins,edges_drug] = histcounts(mean_peaks_drug_before,...
%                 'BinWidth',bin_width,'Normalization','probability');
% bin_cents_cont = edges_cont(1:end-1) + bin_width/2; 
% bin_cents_drug = edges_drug(1:end-1) + bin_width/2; 
fig = figure; 
% b = bar([mean(mean_peaks_cont_before);mean(mean_peaks_drug_before)],...
%         'FaceColor',0.6*[1 1 1]);
% hold on;
e = errorbar([1,2],[mean(mean_peaks_cont_before);mean(mean_peaks_drug_before)],...
             [std(mean_peaks_cont_before,0);std(mean_peaks_drug_before,0)]/sqrt(num_rois),...
             'k-','LineWidth',2,'MarkerSize',10);
hold on;
for i = 1:num_rois
    plot([1,2],[mean_peaks_cont_before(i),mean_peaks_drug_before(i)],...
            'Color',0.8*[1 1 1],'LineWidth',0.25)
end
ax = gca; ax.XTick = 1:2;
ax.XTickLabel = {'Control',drug_name};
ax.TickLabelInterpreter = 'none';
ylabel('Mean peak \Delta F/F_{0}')
% legend('Control',drug_name,'Interpreter','none','Box','off')
box off; 
xlim([0.9 2.1])
[h,p] = ttest(mean_peaks_cont_before,mean_peaks_drug_before);
if h
    plot(1.5,ax.YLim(2)*0.95,'r','Marker','*');
end
if save_figs
    printFig(fig,fig_fold,sprintf('mean_peaks_before_control_vs_%s',drug_name));
end
peak_diffs = mean_peaks_drug_before - mean_peaks_cont_before;
peak_diffsp = 100*peak_diffs./mean_peaks_cont_before; 

fprintf('Change in %s (mean +/- SEM): %.3f +/- %.3f %%\n',...
        drug_name,mean(peak_diffsp),std(peak_diffsp,0)/sqrt(length(peak_diffsp)))
%% Separate out into increasing and decreasing 
inc_rois = find(mean_peaks_drug_before > mean_peaks_cont_before);
dec_rois = find(mean_peaks_drug_before < mean_peaks_cont_before);
num_inc = length(inc_rois);
num_dec = length(dec_rois);
fig = figure; 
% b = bar([mean(mean_peaks_cont_before);mean(mean_peaks_drug_before)],...
%         'FaceColor',0.6*[1 1 1]);
% hold on;
% inc
e = errorbar([1,2],[mean(mean_peaks_cont_before(inc_rois));mean(mean_peaks_drug_before(inc_rois))],...
             [std(mean_peaks_cont_before(inc_rois),0);std(mean_peaks_drug_before(inc_rois),0)]/sqrt(num_inc),...
             'k-','LineWidth',2,'MarkerSize',10);
hold on;
for i = 1:num_inc
    plot([1,2],[mean_peaks_cont_before(inc_rois(i)),mean_peaks_drug_before(inc_rois(i))],...
            'Color',0.8*[1 1 1],'LineWidth',0.25)
end
% dec
e = errorbar([3,4],[mean(mean_peaks_cont_before(dec_rois));mean(mean_peaks_drug_before(dec_rois))],...
             [std(mean_peaks_cont_before(dec_rois),0);std(mean_peaks_drug_before(dec_rois),0)]/sqrt(num_dec),...
             'r-','LineWidth',2,'MarkerSize',10);
hold on;
for i = 1:num_dec
    plot([3,4],[mean_peaks_cont_before(dec_rois(i)),mean_peaks_drug_before(dec_rois(i))],...
            'Color',[1 0 0,0.2],'LineWidth',0.25)
end
ax = gca; ax.XTick = 1:4;
ax.XTickLabel = {'Control',drug_name,'Control',drug_name};
ax.TickLabelInterpreter = 'none';
ylabel('Mean peak \Delta F/F_{0}')
% legend('Control',drug_name,'Interpreter','none','Box','off')
box off; 
xlim([0.9 4.1])
if ~isempty(inc_rois)
    [hinc,pinc] = ttest(mean_peaks_cont_before(inc_rois),mean_peaks_drug_before(inc_rois));
    if hinc
        plot(1.5,ax.YLim(2)*0.95,'r','Marker','*');
    end    
end
if ~isempty(dec_rois)
    [hdec,pdec] = ttest(mean_peaks_cont_before(dec_rois),mean_peaks_drug_before(dec_rois));
    if hdec
        plot(3.5,ax.YLim(2)*0.95,'r','Marker','*');
    end
end
title(sprintf('%g ROIs increased, %g ROIs decreased',num_inc,num_dec))
%%
fig_size = [0.97 0.88]; % in 'normalized' units
[Nrows,Ncols] = getSubplotDimensions(num_rois); 
for i = 1:num_conditions
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 fig_size];      
    for roi_i = 1:num_rois
        ax = subplot(Nrows,Ncols,roi_i);
        plot(ax,ta,mean_dF_aligned2_cont{i}(:,roi_i,1),'k'); hold on;
        plot(ax,ta,mean_dF_aligned2_cont{i}(:,roi_i,2),'r'); 
        plot(ax,ta,mean_dF_aligned2_drug{i}(:,roi_i,1),'k--'); 
        plot(ax,ta,mean_dF_aligned2_drug{i}(:,roi_i,2),'r--');
        box off; 
        if mod(roi_i,Ncols) == 1 && mod(roi_i,Nrows) == round(Nrows/2)
            ylabel('\Delta F/F_{0}')
        end
        if floor(roi_i/Nrows) == Nrows
            xlabel('time (sec)');
        end
        xlim([min(ta),max(ta)])
        title(roi_i)
    end
    legend('Control: Before','Control: DC on',sprintf('%s: Before',drug_name),...
            sprintf('%s: DC on',drug_name),'Box','off','Interpreter','none',...
            'Location','east')
    sgtitle(strrep(out_cont.conditions{i},'_',' '));
    if save_figs
        printFig(fig,fig_fold,sprintf('mean_deltaF_F0_all_%s_%gmA',drug_name,amps(i)));
    end
end
%% Quantify modulation in control and in drug
control_peak_mod = 100*(mean_peaks_cont_during-mean_peaks_cont_before)./mean_peaks_cont_before;
drug_peak_mod = 100*(mean_peaks_drug_during-mean_peaks_drug_before)./mean_peaks_drug_before;
fig = figure; 
y_lim = [inf,-inf];
for i = 1:size(control_peak_mod,1)
    ax = subplot(1,size(control_peak_mod,1),i);
    e = errorbar([1,2],[mean(control_peak_mod(i,:));mean(drug_peak_mod(i,:))],...
                 [std(control_peak_mod(i,:),0);std(drug_peak_mod(i,:),0)]/sqrt(num_rois),...
                 'k-','LineWidth',2,'MarkerSize',10);
    hold on;
    for j = 1:num_rois
        plot([1,2],[control_peak_mod(i,j),drug_peak_mod(i,j)],...
                'Color',0.8*[1 1 1],'LineWidth',0.25)
    end
    title(ax,sprintf('%g mA',amps(i)));
    ax = gca; ax.XTick = 1:2;
    ax.XTickLabel = {'Control',drug_name}; 
    ax.TickLabelInterpreter = 'none';
    if i == 1
        ylabel('Change in peak \Delta F/F_{0} (%)')
    end
    box(ax,'off');
    ax.XLim = [0.9 2.1];
    [h,p] = ttest(control_peak_mod(i,:),drug_peak_mod(i,:));
    if h
        plot(1.5,ax.YLim(2)*0.95,'r','Marker','*');
    end
    y_lim(1) = min(ax.YLim(1),y_lim(1));
    y_lim(2) = max(ax.YLim(2),y_lim(2));
end
for i = 1:length(fig.Children)
    fig.Children(i).YLim = y_lim; 
end
% legend('Control',drug_name,'Interpreter','none','Box','off')
% xlim([0.9 2.1])

if save_figs
    printFig(fig,fig_fold,sprintf('peak_mod_control_vs_%s',drug_name));
end

%% Look at ROIs with change in direction of modulation 

%% Look at peaks over time
stim_x = reshape(1:numel(out_cont.exp_settings(1).stim_vals),[],...
            size(out_cont.exp_settings(1).stim_vals,1))'; % each row for each stim epoch
condi = 1; 
roi_i = 8; 
trial_num = 1; 
cols = {'k','r','b'};
fig = figure; 
fig.Units = 'inches';
fig.Position = [10.4062   11.1042   14.2292    2.8229]; 
ax1 = subplot(1,2,1);
for j = 1:size(out_cont.exp_settings(1).stim_vals,1)
    plot(stim_x(j,:),squeeze(peaks_cont{condi}(j,roi_i,:,trial_num)),cols{j});
    hold on;
    plot([stim_x(j,1),stim_x(j,end)],mean(peaks_cont{condi}(j,roi_i,:,trial_num))*[1 1],...
        '--','Color',cols{j})
end
box off; 
ylabel('\Delta F/F_{0}')
title('Control')
xlabel('Stimulus number')
ax2 = subplot(1,2,2);
for j = 1:size(out_cont.exp_settings(1).stim_vals,1)
    plot(stim_x(j,:),squeeze(peaks_drug{condi}(j,roi_i,:,trial_num)),cols{j}); 
    hold on;
    plot([stim_x(j,1),stim_x(j,end)],mean(peaks_drug{condi}(j,roi_i,:,trial_num))*[1 1],...
        '--','Color',cols{j})
end
box off; 
title(strrep(drug_name,'_',' '))
sgtitle(sprintf('ROI %g: %g mA',roi_i,amps(condi)))
xlabel('Stimulus number')
y_lims = [min([ax1.YLim,ax2.YLim]),max([ax1.YLim,ax2.YLim])];
ax1.YLim = y_lims; 
ax2.YLim = y_lims;
% add stat tests
[hc,pc] = ttest(peaks_cont{condi}(1,roi_i,:),peaks_cont{condi}(2,roi_i,:));
if hc
    plot(ax1,mean(stim_x(2,:)),ax1.YLim(2)*0.95,'r','Marker','*');
end
[hd,pd] = ttest(peaks_drug{condi}(1,roi_i,:),peaks_drug{condi}(2,roi_i,:));
if hd
    plot(ax2,mean(stim_x(2,:)),ax2.YLim(2)*0.95,'r','Marker','*');
end