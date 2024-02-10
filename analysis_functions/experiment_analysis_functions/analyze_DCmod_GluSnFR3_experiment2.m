function analyze_DCmod_GluSnFR3_experiment2(data_or_data_params,...
                    cond_inds,cond_names,sort_amp_ind,save_figs,varargin)
%% Analyze responses to train during DC stimulation at different amplitudes
% Assumes experimental paradigm in DC stim is applied during second train
% of APs within trial (off then on)
if nargin == 0
    exp_date = '20220926';
    reporter = 'GluSnFR3_SynmRuby';
    dish = 'dish3';
    roiset_filename = 'RoiSet_auto_control_3';    
    cond_inds = []; 
%     cond_inds = [1:4,8,7,6,5];
    amps = [-2, -1, -0.5, -0.1, 0.1, 0.5, 1, 2];
    cond_names = arrayfun(@(x) sprintf('%g mA',x),amps,'UniformOutput',0);
    % conditions = {'control_30mAB_0mAY','control_30mAB_1mAY','control_30mAB_2mAY',...
    %                 'control_30mAB_3mAY'}; 
    % cond_names = {'0mA','1mA','2mA','3mA'};
    % conditions = {'control_30mAB_0mAY','control_30mAB_-1mAY','control_30mAB_2mAY',...
    %                 'control_30mAB_-3mAY'}; 
    % cond_names = {'0mA','-1mA','-2mA','-3mA'};
    sort_amp_ind = 4; % amplitude to sort ROIs by
    save_figs = 1;
end

in.plot_figs = [1:7]; % Select analysis figures to plot
                      % 1 - Plot mean trace averaged across ROIs
                      % 2 - Plot mean traces averaged within ROIs
                      % 3 - Plot responses within specific ROI in single figure                      
                      % 4 - Plot distribution of peaks within ROI at each 
                      %     DC intensity
                      % 5 - Plot peaks and change in peaks within ROI at
                      %     each intensity 
                      % 6 - Bar plot of fraction of ROIs modulated at each
                      %     intensity
                      % 7 - Plot spatial distribution of percent modulation of 
                      % peak at each intensity
in.plot_roi_ind = 6; % for 3 - index of ROI to plot
in.stim_cols = {'k','r','b'}; % 'Off','On','Off'
in.dc_conds = {'Before','DC on','After'};  
in.norm_to_cont = 1; % normalize responses to control (DC off) within trial/ROI
in.data_file_suffix = 'train';
in.roi_func_mode = 'separate';
in.roi_pol_slopes = []; % polarization (% deltaF/F0) per mA in each ROI
% plot settings
in.cols = []; 
in.fig_size = [0.97 0.88]; % in 'normalized' units
in.data_fold = getDataFold();
in.analysis_fig_fold = '';
in = sl.in.processVarargin(in,varargin);

cols = in.cols; 
%% Load data if necessary
if isfield(data_or_data_params,'img_names')
    out = data_or_data_params; % input experiment data struct directly
    exp_date = out.exp_date;
    reporter = out.reporter;
    dish = out.dish; 
    roiset_filename = out.roiset_filename_no_ext; 
    exp_fold = fullfile(in.data_fold,exp_date,reporter,dish);
else % load using fields of data_or_data_params
    exp_date = data_or_data_params.exp_date;
    reporter = data_or_data_params.reporter;
    dish = data_or_data_params.dish;
    roiset_filename = data_or_data_params.roiset_filename;   
    data_file = sprintf('%s_%s_%s_%s_%s',exp_date,reporter,dish,...
                                        in.roi_func_mode,roiset_filename);
    if ~isempty(in.data_file_suffix)
        data_file = [data_file '_' in.data_file_suffix];
    end
    exp_fold = fullfile(in.data_fold,exp_date,reporter,dish);
    out = load(fullfile(exp_fold,[data_file '.mat']));
    fprintf('Loaded data: %s\n',data_file);
end
if isempty(in.analysis_fig_fold)
    in.analysis_fig_fold = fullfile(exp_fold,['figs_' roiset_filename]);
end
%%

if ~isempty(cond_inds)
    conditions = out.conditions(cond_inds);
else
    conditions = out.conditions; 
    cond_inds = 1:length(conditions);
end
cond_names = cond_names(cond_inds);
num_conditions = length(cond_inds);
exp_settings = out.exp_settings(1); 
num_trains = exp_settings.num_trains; 
num_stim = exp_settings.num_stim;
baseline_wind_sec = exp_settings.convert2Time(exp_settings.baseline_wind);
deltaF_F0_all = out.deltaF_F0_all(cond_inds);
% deltaF_F0_aligned_all = out.deltaF_F0_aligned_all(cond_inds);
% get responses aligned within train
deltaF_F0_aligned2 = out.deltaF_F0_aligned2_all(cond_inds); 
rois = out.rois_all{1}{1};
pixel_size = out.plot_settings.pixel_size; % um


num_rois = rois.num_rois;
% Mean traces within ROI, averaged within train across trials
mean_dF_F0_rois = cellfun(@(x) mean(x,[4 5],'omitnan'),deltaF_F0_aligned2,...
            'UniformOutput',0); % average across stim within trains and trials
std_dF_F0_rois = cellfun(@(x) std(x,0,[4 5],'omitnan'),deltaF_F0_aligned2,...
            'UniformOutput',0); % std across stim within trains and trials
sem_dF_F0_rois = cellfun(@(x,y) x/sqrt(prod(size(y,[4,5]))),...
                            std_dF_F0_rois,deltaF_F0_aligned2,...
                            'UniformOutput',0);
mean_dF_F0_rois_norm0 = cellfun(@(x) x./max(x(:,:,1),[],1,'omitnan'),...
                                mean_dF_F0_rois,'UniformOutput',0);
std_dF_F0_rois_norm0 = cellfun(@(x,y) x./max(y(:,:,1),[],1),...
                                std_dF_F0_rois,mean_dF_F0_rois,...
                                'UniformOutput',0);
sem_dF_F0_rois_norm0 = cellfun(@(x,y) x/sqrt(prod(size(y,[4,5]))),...
                                std_dF_F0_rois_norm0,deltaF_F0_aligned2,...
                                'UniformOutput',0);
% mean_dF_F0_rois = cellfun(@(x) squeeze(mean(x(:,:,:,:,1),[4 5])),deltaF_F0_aligned2,'UniformOutput',0); % average across stim within trains
% Average raw dF/F0 traces across ROIs
mean_dF_F0 = cellfun(@(x) squeeze(mean(x,2,'omitnan')),mean_dF_F0_rois,...
                'UniformOutput',0); % average across ROIs
std_dF_F0 = cellfun(@(x) squeeze(std(x,0,2,'omitnan')),mean_dF_F0_rois,...
                'UniformOutput',0); % std across ROIs
sem_dF_F0 = cellfun(@(x) x/sqrt(num_rois),std_dF_F0,'UniformOutput',0);
% Average traces normalized within trial across ROIs
mean_dF_F0_norm0 = cellfun(@(x) squeeze(mean(x,2,'omitnan')),mean_dF_F0_rois_norm0,...
                'UniformOutput',0); % average across ROIs
std_dF_F0_norm0 = cellfun(@(x) squeeze(std(x,0,2,'omitnan')),mean_dF_F0_rois_norm0,...
                'UniformOutput',0); % std across ROIs
sem_dF_F0_norm0 = cellfun(@(x) x/sqrt(num_rois),std_dF_F0_norm0,'UniformOutput',0);
% sem_deltaF_F0_aligned = std_deltaF_F0_aligned;
t = exp_settings.getTimeVector(size(deltaF_F0_all{1},1));
ta = exp_settings.getTimeVector(size(mean_dF_F0{1},1));
ta = ta - ta(exp_settings.baseline_wind+1);
% Peaks
peaks = out.peaks_deltaF_F0_all(cond_inds);
if in.norm_to_cont
    trace_ylabel_str = 'Mean \Delta F/F_{0} (norm.)';
else
    trace_ylabel_str = 'Mean \Delta F/F_{0}';
end
fprintf('Extracted traces and peaks\n')
%% Plot mean stim averaged response across ROIs and trials
if any(in.plot_figs == 1)
    if num_conditions == 8
        Nrows = 2; Ncols = 4; 
    elseif num_conditions == 10
        Nrows = 2; Ncols = 5; 
    else
        [Nrows,Ncols] = getSubplotDimensions(num_conditions);
    end
    fig = figure('Units','normalized');
    fig.Position = [0.047 0.05 in.fig_size]; 
    for i = 1:num_conditions
        ax = subplot(Nrows,Ncols,i);        
        if in.norm_to_cont
            tracesi = mean_dF_F0_norm0{i};
    %         stdi = std_dF_F0_norm0{i}; 
            semi = sem_dF_F0_norm0{i}; 
        else
            tracesi = mean_dF_F0{i};
    %         stdi = std_dF_F0{i};        
            semi = sem_dF_F0{i}; 
        end
        for condj = 1:size(mean_dF_F0{i},2)
    %        shadedErrorBar(ta,mean_dF_F0{i}(:,j),std_dF_F0{i}(:,j),'lineProps',stim_cols(j));
           shadedErrorBar(ta,tracesi(:,condj),semi(:,condj),'lineProps',in.stim_cols(condj));
        end
    %     plot(ta,mean_dF_F0{i}); 
        box off; grid on;       
        if i > 4
            xlabel('time (sec)');
        end
        if i == 1 || i == 5
            ylabel(trace_ylabel_str)
        end
        title(strrep(conditions{i},'_',' '));
        xlim([-baseline_wind_sec,ta(end)]);
%         ax.YLim(1) = -0.05; 
        if i == num_conditions
            legend(in.dc_conds,'Box','off');
        end
    end
    setAxesUniformLim(fig,'YLim');    
    sgtitle('Mean response across ROIs with and without DC stimulus (+/- SEM)')
    if save_figs
        fig_name = sprintf('meanF_all_DCamp_norm%g',in.norm_to_cont);
        printFig(fig,in.analysis_fig_fold,fig_name);
    end
end
%% Plot mean stim averaged response across trials within each ROI
if any(in.plot_figs == 2)
    Nax = num_rois; 
    [Nrows,Ncols] = getSubplotDimensions(Nax); 
    for condj = 1:num_conditions % loop over conditions (stim amps)
        fig = figure('Units','normalized');
        fig.Position = [0.001 0.03 in.fig_size];        
        for roi_i = 1:Nax % loop over ROIs for each subplot
            ax = subplot(Nrows,Ncols,roi_i);        
            % get traces
            if in.norm_to_cont
                tracesij = squeeze(mean_dF_F0_rois_norm0{condj}(:,roi_i,:));
    %             stdij = squeeze(std_dF_F0_rois_norm0{condj}(:,roi_i,:));
                stdij = squeeze(sem_dF_F0_rois_norm0{condj}(:,roi_i,:));
            else
                tracesij = squeeze(mean_dF_F0_rois{condj}(:,roi_i,:));
    %             stdij = squeeze(std_dF_F0_rois{condj}(:,roi_i,:));
                stdij = squeeze(sem_dF_F0_rois{condj}(:,roi_i,:));
            end
    %         p = plot(ta,tracesi); box off; grid on;
            for k = 1:size(tracesij,2)
                shadedErrorBar(ta,tracesij(:,k),stdij(:,k),'lineProps',in.stim_cols(k));
            end
    %         set(p,{'color'},stim_cols);
            title(sprintf('%g',roi_i));
            if floor(roi_i/Nrows) == Nrows
                xlabel('time (sec)');
            end
            if mod(roi_i,Ncols) == 1 && mod(roi_i,Nrows) == round(Nrows/2)
                ylabel(trace_ylabel_str)
            end
             xlim([-baseline_wind_sec,ta(end)]);
%              ax.YLim(1) = -0.5;            
        end
        sgtitle(strrep(conditions{condj},'_',' '));
        drawnow; 
        if save_figs
            fig_name = sprintf('meanF_ROIs_%s_DCamp_norm%g',cond_names{condj},in.norm_to_cont);
            printFig(fig,in.analysis_fig_fold,fig_name);
        end
    end
end
%% Plot traces of specific ROI in all conditions
if any(in.plot_figs == 3)    
    if in.norm_to_cont
%         yax_lims = [-0.1 4];
%         yax_lims = [-1 4]; 
        yax_lims = []; 
    else
        % yax_lims = [-0.1 0.2];                 
        yax_lims = []; 
    end
    if num_conditions == 8
        Nrows = 2; Ncols = 4;
    elseif num_conditions == 10
        Nrows = 2; Ncols = 5;
    else
        [Nrows,Ncols] = getSubplotDimensions(num_conditions);
    end
    stim_cols2 = {[0 0 0 0.2];[1 0 0 0.1]};    
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 in.fig_size];
    for i = 1:length(cond_inds)         
        % plot mean trace
        mean_tracesi = squeeze(mean_dF_F0_rois{i}(:,in.plot_roi_ind,:)); % [ off, on, off]
        % all responses 
        tracesi = cell(1,2); 
        for j = 1:2
            trij = squeeze(deltaF_F0_aligned2{i}(:,in.plot_roi_ind,j,:,:));
            tracesi{j} = reshape(trij,size(trij,1),prod(size(trij,[2 3])));        
        end
        if in.norm_to_cont
            norm_factor = max(mean_tracesi(:,1),[],1);
            mean_tracesi = mean_tracesi/norm_factor;
            tracesi = cellfun(@(x) x/norm_factor,tracesi,'UniformOutput',0); 
        end        
        ax = subplot(Nrows,Ncols,i);
        for j = 1:2
            p = plot(ta,tracesi{j},'LineWidth',0.25,'Color',stim_cols2{j});
            hold on;
        end
        p2 = plot(ta,mean_tracesi(:,1:2),'LineWidth',2);
        set(p2,{'color'},in.stim_cols(1:2)');
        box off; grid on;
        title(strrep(conditions{i},'_',' '));
        if i > 4
            xlabel('time (sec)');
        end
        if i == 1 || i == 5
            ylabel(trace_ylabel_str)
        end
        if i == num_conditions
            legend(p2,in.dc_conds,'Box','off');
        end
        if ~isempty(yax_lims)
            ax.YLim = yax_lims;
        end
        ax.XLim = [ta(1),ta(end)];
    end
    setAxesUniformLim(fig,'YLim');    
    sgtitle(sprintf('Mean and individual responses (%g APs) in ROI %g',...
            length(exp_settings(1).stim_vals(:)),in.plot_roi_ind))
    if save_figs
        fig_name = sprintf('meanF_all_DCamp_norm%g_roi%g',in.norm_to_cont,...
                in.plot_roi_ind);
        printFig(fig,in.analysis_fig_fold,fig_name);
    end
end
%% Plot distribution of peaks within ROI
% plot_violin = 0; 
if any(in.plot_figs == 4)
    cond_xvec_all = -num_conditions:2:num_conditions;
    cond_xvec = cond_xvec_all; cond_xvec(round(length(cond_xvec)/2)) = []; % remove 0
%     xoffset = [-0.5 0.5]; 
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 in.fig_size];
    for i =  1:num_conditions
        xi = cond_xvec(i); 
        yi = squeeze(peaks{i}(:,in.plot_roi_ind,:,:));
        if in.norm_to_cont
            % normalize individual peaks with mean of control peaks
            yij = yi(2,:,:)/mean(yi(1,:,:),'all','omitnan');
            yij = yij(:);
%             if plot_violin
                violin_func(yij,'x',xi,'edgecolor',0*[1 1 1],'facecolor',0.5*[1 1 1],...
                    'medc','r','mc',[]);
%             else
%                 boxplot(yij,'Positions',xi);
%             end
            hold on;
        else
            for j = 1:2
                yij = yi(j,:,:); yij = yij(:);
%                 violin_func(yij,'x',xi+xoffset(j),'edgecolor',stim_cols{j},'facecolor',stim_cols3{j},...
%                     'medc',stim_cols{j},'mc',[]);
                hold on;
            end
        end
    end    
    if in.norm_to_cont
        peaks_before_roi = cell2mat(cellfun(@(x) ...
                            squeeze(x(1,in.plot_roi_ind,:))'/mean(x(1,in.plot_roi_ind,:),'all'),...
                            peaks,'UniformOutput',0))';
    else
        peaks_before_roi = cell2mat(cellfun(@(x) squeeze(x(1,in.plot_roi_ind,:))',peaks,'UniformOutput',0))';        
    end
%     boxplot(peaks_before_roi,'Positions',0);
    violin_func(peaks_before_roi,'x',0,'edgecolor',0*[1 1 1],'facecolor',0.5*[1 1 1],...
                    'medc','r','mc',[]);
    ax = gca;
    plot([cond_xvec_all;cond_xvec_all]+1,ax.YLim,'k');
    ax.XTick = [cond_xvec(1:floor(num_conditions/2)),0,cond_xvec(floor(num_conditions/2)+1:end)];
    ax.XTickLabel = [cond_names(1:floor(num_conditions/2)),'0 mA',cond_names(floor(num_conditions/2)+1:end)];;
%     ax.XTick = cond_xvec;
%     ax.XTickLabel = cond_names;
    ax.YGrid = 'on';
    ax.TickLength = [0.005 0];
    box off;
    if in.norm_to_cont
        ylabel('Peak \Delta F/F_{0} (norm. to mean at 0 mA within trial)')
        plot(ax.XLim,[1 1],'--k');
    else
        ylabel('Peak \Delta F/F_{0}');
    end
    xlabel('DC current intensity')
    title(sprintf('Distribution of peak responses in ROI %g',in.plot_roi_ind))
%     if ~in.norm_to_cont
%         legend(ax.Children(9:10),'DC off','DC on','Box','off');
%     end
    if save_figs
        fig_name = sprintf('peakF_dists_all_DCamp_norm%g_roi%g',in.norm_to_cont,in.plot_roi_ind);
        printFig(fig,in.analysis_fig_fold,fig_name);
    end
end
%% Peaks analysis
% mean across stim/trials within ROI
mean_peaks_rois = cellfun(@(x) squeeze(mean(x,[3 4]))',peaks,...
                            'UniformOutput',0); % [ num_rois x num_trains ] 

mean_peaks_rois = trialsCell2Mat(mean_peaks_rois); % [num_rois x num_trains x num_conditions]
% std across stim/trials within ROI
std_peaks_rois = cellfun(@(x) squeeze(std(x,0,[3 4]))',peaks,...
                            'UniformOutput',0);
sem_peaks_rois = cellfun(@(x,y) x/sqrt(prod(size(y,3:4))),std_peaks_rois,peaks,...
                    'UniformOutput',0); % n = num_stim * num_trials
std_peaks_rois = trialsCell2Mat(std_peaks_rois); % [num_rois x num_trains x num_conditions]
sem_peaks_rois = trialsCell2Mat(sem_peaks_rois);

num_trials = cellfun(@(x) size(x,4),peaks,'UniformOutput', 1);
if all(num_trials == num_trials(1)); num_trials = num_trials(1); end
% modulation
[peaks_per_change_rois,peaks_per_change_std_rois] = calcPerErrWithVariance(mean_peaks_rois(:,2,:),...
                                                               mean_peaks_rois(:,1,:),...
                                                               std_peaks_rois(:,2,:),...
                                                               std_peaks_rois(:,1,:));
peaks_per_change_rois = squeeze(peaks_per_change_rois);
peaks_per_change_std_rois = squeeze(peaks_per_change_std_rois);    
peaks_per_change_sem_rois = peaks_per_change_std_rois./sqrt(num_stim*num_trials);
% normalized
mean_peaks_rois_norm = mean_peaks_rois./mean_peaks_rois(:,1,:);
sem_peaks_rois_norm = sem_peaks_rois./mean_peaks_rois(:,1,:);
% sort arrays by ROIs with highest percent modulation 
roi_inds = 1:num_rois;
if sort_amp_ind ~= 0
    [~,sort_rois] = sort(abs(peaks_per_change_rois(:,sort_amp_ind)),'descend');
else
    sort_rois = roi_inds; 
end
roi_inds1 = roi_inds(sort_rois);
mean_peaks_rois = mean_peaks_rois(sort_rois,:,:);
std_peaks_rois = std_peaks_rois(sort_rois,:,:);
sem_peaks_rois = sem_peaks_rois(sort_rois,:,:);
% per change of mean peak between stim and control within trial
peaks_per_change_rois = peaks_per_change_rois(sort_rois,:);
peaks_per_change_std_rois = peaks_per_change_std_rois(sort_rois,:);
peaks_per_change_sem_rois = peaks_per_change_sem_rois(sort_rois,:);
% normalized peaks to mean control
mean_peaks_rois_norm = mean_peaks_rois_norm(sort_rois,:,:);
sem_peaks_rois_norm = sem_peaks_rois_norm(sort_rois,:,:);
if ~isempty(in.roi_pol_slopes)
    in.roi_pol_slopes = in.roi_pol_slopes(sort_rois);
end
%% Analyze ROI specific modulation
% peaks : [num_trains x num_rois x num_stim x num_trials]
if isempty(cols)
    if num_conditions == 6
        cols = flipud([ 0.6445         0    0.1484 % for 6
            0.8398    0.1875    0.1523
            0.9531    0.4258    0.2617            
            0.4531    0.6758    0.8164
            0.2695    0.4570    0.7031
            0.1914    0.2109    0.5820]);
    elseif num_conditions == 8
        cols = flipud([ 0.6445         0    0.1484 % for 8
            0.8398    0.1875    0.1523
            0.9531    0.4258    0.2617
            0.9883    0.6797    0.3789
            0.6680    0.8477    0.9102
            0.4531    0.6758    0.8164
            0.2695    0.4570    0.7031
            0.1914    0.2109    0.5820]);
    elseif num_conditions == 10
        cols = flipud([0.4023         0    0.1211 % for 10
            0.6953    0.0938    0.1680
            0.8359    0.3750    0.3008
            0.9531    0.6445    0.5078
            0.9883    0.8555    0.7773
            0.8164    0.8945    0.9375
            0.5703    0.7695    0.8672
            0.2617    0.5742    0.7617
            0.1289    0.3984    0.6719
            0.0195    0.1875    0.3789]);
    else
        cols = lines(num_conditions);
    end
end
if any(in.plot_figs == 5)            
    % Plot peaks
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 in.fig_size];
    for i = 1:num_rois
        xi = [i-0.3,i+0.3];
        for j = 1:num_conditions
            errorbar(xi,squeeze(mean_peaks_rois(i,1:2,j)),...
                    squeeze(sem_peaks_rois(i,1:2,j)),'-','Color',cols(j,:));
            hold on;
        end        
    end    
    ax = gca;    
    xlabel('ROI index');
    ylabel('Mean peak \Delta F/F_{0} ')
    box off; grid on;
    legend(ax.Children(end:-1:end-(num_conditions-1)),cond_names,'Box','off','Interpreter','none')
    if sort_amp_ind > 0
        title(sprintf('Mean +/- SEM (%g stimuli per ROI, sorted by %% change at %s)',...
                mode(num_stim*num_trials),cond_names{sort_amp_ind}));    
    else
         title(sprintf('Mean +/- SEM (%g stimuli per ROI)',...
                mode(num_stim*num_trials)));    
    end
    ax.XLim = [0 num_rois + 1];
    ax.XTick = 1:num_rois;
    ax.XTickLabel = roi_inds1;
    if save_figs
        printFig(fig,in.analysis_fig_fold,sprintf('mean_peaks_rois_sort%g',sort_amp_ind));
    end
    % Plot norm peaks
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 in.fig_size];           
    for j = 1:num_conditions
        errorbar(squeeze(mean_peaks_rois_norm(:,2,j)),...
                squeeze(sem_peaks_rois_norm(:,2,j)),'o','Color',cols(j,:),...
                'MarkerFaceColor',cols(j,:));
        hold on;
    end        
    ax = gca;    
    xlabel('ROI index');
    ylabel('Mean peak \Delta F/F_{0} (norm. to 0 mA)')
    box off; grid on;
    legend(ax.Children(end:-1:end-(num_conditions-1)),cond_names,'Box','off','Interpreter','none')  
    if sort_amp_ind > 0
        title(sprintf('Mean +/- SEM (%g stimuli per ROI, sorted by %% change at %s)',...
            mode(num_stim*num_trials),cond_names{sort_amp_ind}));
    else
        title(sprintf('Mean +/- SEM (%g stimuli per ROI)',...
            mode(num_stim*num_trials)));
    end
    ax.XLim = [0 num_rois + 1];
    ax.XTick = 1:num_rois;
    ax.XTickLabel = roi_inds1;
%     ax.YLim
    if save_figs
        printFig(fig,in.analysis_fig_fold,sprintf('mean_peaks_rois_norm_sort%g',sort_amp_ind));
    end
    % Plot norm peaks vs intensity within ROI on same axis
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 in.fig_size];       
    for j = 1:num_rois
        xj = linspace(j-0.4,j+0.4,num_conditions)';
        if ~isempty(in.roi_pol_slopes)
            if ~isnan(in.roi_pol_slopes(j)) && in.roi_pol_slopes(j) < 0
                xj = flipud(xj); % assign positive current to depolarizing direction for this ROI
            elseif isnan(in.roi_pol_slopes(j))
                continue; 
            end
        end
        mean_peaksj = squeeze(100*(mean_peaks_rois_norm(j,2,:)-1)); % percent change
        sem_peaksj = squeeze(100*sem_peaks_rois_norm(j,2,:));
%         mean_peaksj = squeeze(peaks_per_change_rois(j,:))';
%         sem_peaksj = squeeze(peaks_per_change_sem_rois(j,:))';
        [b,~,~,~,stats] = regress(mean_peaksj,[ones(size(xj)) xj-j]); % center x at 0
%         [b,~,~,~,stats] = regress(mean_peaksj,xj-j); % center x at 0
        Rsq = stats(1); 
        p = stats(3); 
        if p < 0.05
            colj = [1 0 0];
            lw = 1;
        else
            colj = 0.6*[1 1 1];
            lw = 0.5; 
        end
        errorbar(xj,mean_peaksj,sem_peaksj,...
                'o','MarkerFaceColor',colj,'Color',colj); hold on;
        plot(xj,b(1) + b(2)*(xj-j),'-','Color',colj,'LineWidth',lw);
%         plot(xj,b(1)*(xj-j),'-','Color',colj,'LineWidth',lw);
    end
    ax = gca;
    xlabel('ROI index');
%     ylabel('Mean peak \Delta F/F_{0} (norm. to 0 mA)')
    ylabel('Change in mean peak \Delta F/F_{0} (%)')
    box off; grid on;
%     legend(ax.Children(end:-1:end-(num_conditions-1)),cond_names,'Box','off')
    if sort_amp_ind > 0
        title(sprintf('Mean +/- SEM (%g stimuli per ROI, sorted by %% change at %s)',...
            mode(num_stim*num_trials),cond_names{sort_amp_ind}));
    else
        title(sprintf('Mean +/- SEM (%g stimuli per ROI)',...
            mode(num_stim*num_trials)));
    end
    ax.XLim = [0 num_rois + 1];
    ax.XTick = 1:num_rois;
    ax.XTickLabel = roi_inds1;    
    if save_figs
        printFig(fig,in.analysis_fig_fold,sprintf('mean_peaks_rois_per_change_vs_amp_sort%g',sort_amp_ind));
    end
    % Plot percent modulation    
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 in.fig_size];           
    for j = 1:num_conditions
        xpos = (1:num_rois) + rand(1,num_rois)*0.4;
        errorbar(xpos,squeeze(peaks_per_change_rois(:,j)),...
                squeeze(peaks_per_change_sem_rois(:,j)),'o','Color',cols(j,:),...
                'MarkerFaceColor',cols(j,:));
        hold on;
    end        
    ax = gca;    
    xlabel('ROI index');
    ylabel('Change in mean peak \Delta F/F_{0} (%)')
    box off; grid on;
    legend(ax.Children(end:-1:end-(num_conditions-1)),cond_names,'Box','off','Interpreter','none')
    if sort_amp_ind > 0
        title(sprintf('Mean +/- SEM (%g stimuli per ROI, sorted by %% change at %s)',...
            mode(num_stim*num_trials),cond_names{sort_amp_ind}));
    else
        title(sprintf('Mean +/- SEM (%g stimuli per ROI)',...
            mode(num_stim*num_trials)));
    end
    ax.XLim = [0 num_rois + 1];
    ax.XTick = 1:num_rois;
    ax.XTickLabel = roi_inds1;
%     ax.YLim = [-50 50];
    if save_figs
        printFig(fig,in.analysis_fig_fold,sprintf('mean_peaks_rois_per_change_sort%g',sort_amp_ind));
    end  
end
%% Bar plot of frac. modulation
peak_inc_rois = mean_peaks_rois_norm(:,2,:) - sem_peaks_rois_norm(:,2,:) > 1 + sem_peaks_rois_norm(:,1,:);
peak_dec_rois = mean_peaks_rois_norm(:,2,:) + sem_peaks_rois_norm(:,2,:) < 1 - sem_peaks_rois_norm(:,1,:);
per_inc_rois = squeeze(100*sum(peak_inc_rois)/num_rois);
per_dec_rois = squeeze(100*sum(peak_dec_rois)/num_rois);
per_nochange_rois = 100 - per_inc_rois - per_dec_rois;
% 0 - no change, 1 decrease, 2 increase
peak_change_class = squeeze(zeros(size(peak_inc_rois)) + peak_dec_rois*1 + ...
                            peak_inc_rois*2); 
bar_cols = [0.6,0.6,0.6;0.4023    0.6602    0.8086;0.9336    0.5391    0.3828];
if any(in.plot_figs == 6)
    % peak_inc_rois = mean_peaks_rois_norm(:,2:end) > 1 + sem_peaks_rois_norm(:,1);
    % peak_dec_rois = mean_peaks_rois_norm(:,2:end) < 1 - sem_peaks_rois_norm(:,1);
    bar_mode = 2;    
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 in.fig_size];        
    if bar_mode == 1 % stacked bars
        b = bar([per_nochange_rois,per_dec_rois,per_inc_rois],'stacked');
    else
        b = bar([per_nochange_rois,per_dec_rois,per_inc_rois]);
    end
    for i = 1:size(bar_cols,1)
        b(i).FaceColor = bar_cols(i,:);
    end
    ax = gca;
    ax.XTick = 1:length(cond_names);
    ax.XTickLabel = cond_names;
    ax.TickLabelInterpreter = 'none';
    legend({'No change','Decrease','Increase'},'Box','off','Location','bestoutside');    
    ylabel('% ROIs');
    box off;
    title(sprintf('Proportion of %g ROIs modulated by DC',num_rois))
    if save_figs
        printFig(fig,in.analysis_fig_fold,['per_change_rois_bar' num2str(bar_mode)]);
    end

end
%% Plot spatial distribution of percent modulation of peak at each intensity
if any(in.plot_figs == 7)
    rois_xy = [rois.x,rois.y]*pixel_size; % convert to um
    rois_xy = rois_xy(sort_rois,:);
    center2center_dists = sqrt((rois_xy(:,1) - rois_xy(:,1)').^2 + ...
        (rois_xy(:,2)-rois_xy(:,2)').^2);    
    diag_inds = 1:size(center2center_dists,1) + 1:numel(center2center_dists); % indices of diagonal elements
    center2center_dists(diag_inds) = nan;
    fig = figure('Units','normalized');
    fig.Position = [0.001 0.03 in.fig_size];        
    if num_conditions == 8
        Nrows = 2; 
        Ncols = 4; 
    else
        [Nrows,Ncols] = getSubplotDimensions(num_conditions);
    end
    for i = 1:num_conditions
        ax = subplot_tight(Nrows,Ncols,i);
%         scatter(rois_xy(:,1),rois_xy(:,2),50,peaks_per_change_rois(:,i),'filled'); 
        scatter(ax,rois_xy(:,1),rois_xy(:,2),50,peak_change_class(:,i),'filled'); 
        axis(ax,'equal','tight');        
        caxis(ax,[0 2])
        colormap(ax,bar_cols); % no change, decrase, increase
%         colormap(lines(3)) % no change, decrase, increase        
        title(ax,cond_names{i},'Interpreter','none')
        if i == num_conditions
            cb = colorbar(ax);
            cb.Ticks = [0.25 1 1.75];
            cb.TickLabels = {'No change','Decrease','Increase'};
        end
    end
    if save_figs
        printFig(fig,in.analysis_fig_fold,'map_per_change_rois');
    end
end
end