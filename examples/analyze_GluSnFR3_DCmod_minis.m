dataset_def_filename = 'GluSnFR3_DC_modulation_minis.xlsx'; % dataset definition spreadsheet
reporter = 'GluSnFR3_SynmRuby';
roi_func_mode = 'separate';
mode_str = 'default';
load_compiled_dataset = 1; 
plot_amps = [-50,50];
plot_amps_labels = numericVec2chars(plot_amps,'%g V/m');
min_num_trials_per_amp = 3; % require number of trials at each amplitude
sort_amps = 1; % set negative currents to be suppressing, positive facilitating
alpha = 0.05; % sig level
thresholds = 10; 
% Plot settings
save_figs = 1;
exclude_dishes = []; 
% Load
analysis_fold = fileparts(which('analyze_GluSnFR3_DCmod_minis'));
fig_fold = fullfile(analysis_fold,'GluSnFR3_DCmod_minis');
dataset_def_filename = fullfile(analysis_fold,'..','dataset_files',dataset_def_filename);
opts = struct();
opts.dataset_fold = fullfile(analysis_fold,'datasets');
opts.load_compiled_dataset = load_compiled_dataset;
[data_raw,def_raw] = loadDataset(dataset_def_filename,reporter,roi_func_mode,mode_str,...
                        opts);
data = data_raw; 
def = def_raw; 
if ~isempty(exclude_dishes)   
    data(exclude_dishes) = [];
    def(exclude_dishes,:) = []; 
    fprintf('Removing %g dishes\n',length(exclude_dishes)); 
end
%% 
num_amps = length(plot_amps);
num_dishes = length(data); 
subthresh_amps = cellfun(@(x) str2num(x),def.subthresh_amps,'UniformOutput',0); %#ok<*ST2NM> 
subthresh_amps_mA = cellfun(@(x) str2num(x),def.subthresh_amps_mA,'UniformOutput',0); %#ok<*ST2NM> 
batch = str2double(def.batch);
%% Mini detection
% detect mini settings
dms = detectMinisPresets('thor_50Hz',data{1}.exp_settings(1).sampling_rate);
% modify settings here
% detection settings
dms.threshold = 3; 
dms.snr_thresh = 3.5;
dms.mini_amp_range = [0.065 inf];
dms.mini_width_range = [0.03 inf];
dms.mini_width_frac_amp = 0.5; 
% filter settings
dms.apply_filter = 1; 
dms.filt_order = 1; 
dms.filt_type = 'butter';
dms.fc = 0.5; % high pass  
dms.deconv = 0; 
dms.deconv_tau = 0.035; 
dms.refilter_deconv = 1; 
dms.smooth_filt_width = 0;
dms.use_asls_baseline = 0; 
% Plot settings
dms.plot_figs = 0; % 1 - 
dms.save_figs = 0;
dms.plot_filt_output_roi_index = 8; 
dms.offset_factor = 100; 
% Initialize variables
mean_n_minis_before = []; 
mean_n_minis_during = []; 
roi_in_dish_index = []; % numbering of ROIs after removing ROIs not passing QC
dish_inds = []; 
mini_deltaF_F0_traces = cell(1,num_dishes);
for i = 1:num_dishes % Loop over dishes   
    dms.save_figs_dir = fullfile(fig_fold,sprintf('%s_%s_%s',def.exp_date{i},...
                                            def.dish{i},...
                                            strrep(def.roiset_filename{i},'.zip','')));    
    num_roisi = data{i}.rois_all{1}{1}.num_rois;    
    mean_n_minis_beforei = zeros(num_roisi,num_amps);
    mean_n_minis_duringi = zeros(num_roisi,num_amps);
    mini_deltaF_F0_traces{i} = cell(1,num_roisi);
    for j = 1:num_amps % Loop over stimulation amplitudes
        [~,~,jj] = intersect(plot_amps(j),subthresh_amps{i}); 
        meansij = data{i}.means_all{jj};
        num_trialsij = size(meansij,3);
        exp_settingsij = data{i}.exp_settings(j);
        stim_frame = exp_settingsij.stim_vals2;
        n_minis_beforeij = zeros(num_roisi,num_trialsij);
        n_minis_duringij = zeros(num_roisi,num_trialsij);
        for k = 1:num_trialsij % Loop over trials
            dms.trial_name = data{i}.img_names{j}{j};
            meansijk = meansij(:,:,k); 
            mini_out = detectMinis(meansijk,exp_settingsij.sampling_rate,dms);
            mini_frames = mini_out.mini_frames;
            n_minis_beforeij(:,k) = cellfun(@(x) sum(x<stim_frame),mini_frames,...
                                        'UniformOutput',1);
            n_minis_duringij(:,k) = cellfun(@(x) sum(x>stim_frame),mini_frames,...
                                        'UniformOutput',1);
            for n = 1:num_roisi
                mini_deltaF_F0_traces{i}{n} = [mini_deltaF_F0_traces{i}{n},mini_out.mini_deltaF_F_traces_roi{n}];
            end
            if dms.save_figs 
                close all; 
            end
        end 
        mean_n_minis_beforei(:,j) = mean(n_minis_beforeij,2);
        mean_n_minis_duringi(:,j) = mean(n_minis_duringij,2);
    end
    mean_n_minis_before = [mean_n_minis_before;mean_n_minis_beforei];
    mean_n_minis_during = [mean_n_minis_during;mean_n_minis_duringi];
    roi_in_dish_index = [roi_in_dish_index;(1:num_roisi)']; % roi index within dish
    dish_inds = [dish_inds;i*ones(num_roisi,1)]; % dish index for each roi
end
ta = mini_out.ta;
mini_deltaF_F0_traces = [mini_deltaF_F0_traces{:}]; 
% mean of all minis in each roi (num_timepoints x num_rois] 
mean_mini_deltaF_F0_traces = cell2mat(cellfun(@(x) mean(x,2,'omitnan'),mini_deltaF_F0_traces,'UniformOutput',0));
% mean of normalized minis across rois
mean_mini_norm_trace = mean(mean_mini_deltaF_F0_traces./max(mean_mini_deltaF_F0_traces,[],1),2);

%% Fit decay to single exp on mean trace
[peakF,ind] = max(mean_mini_norm_trace);
F_fit = mean_mini_norm_trace(ind:end);
t_fit = ta(ind:end); t_fit = t_fit-t_fit(1); 
decay_fit = fitExpDecay(t_fit,F_fit,1);
taud = decay_fit.taud1*1e3; % decay time constant in ms 

fig = figure; 
plot(ta,mean_mini_norm_trace,'k');
hold on; box off;
plot(t_fit,decay_fit.fitobjs{1}(t_fit),'--r');
xlabel('time (sec)'); ylabel('\Delta F/F_{0} (norm.)');
legend('Data',sprintf('Fit: \\tau_{d} = %.1f ms',taud))
%% Plot distribution of minis before and during - within dish
bin_width = 0.5;
convert_to_mHz = 0; 
dur = stim_frame/data{1}.exp_settings(1).sampling_rate; % sec
for n = 1:num_dishes
    fig = figure; 
    hd = zeros(1,num_amps);
    pd = zeros(1,num_amps);
    median_n_minis_before = median(mean_n_minis_before,1);
    median_n_minis_during = median(mean_n_minis_during,1);
    for i = 1:num_amps
        ax = subplot(1,num_amps,i);
        [Nb,edgesb] = histcounts(mean_n_minis_before(dish_inds==n,i),'BinWidth',bin_width,...
                                'Normalization','cdf');
        [Nd,edgesd] = histcounts(mean_n_minis_during(dish_inds==n,i),'BinWidth',bin_width,...
                                'Normalization','cdf');
        xb = edgesb(1:end-1) + bin_width/2;
        xd = edgesd(1:end-1) + bin_width/2;
        if convert_to_mHz
            plot(ax,xb,1e3*Nb/dur,'k'); hold on;
            plot(ax,xd,1e3*Nd/dur,'r');
            xlabel(ax,'Mean mini rate (mHz)');
        else
            plot(ax,xb,Nb,'k'); hold on;
            plot(ax,xd,Nd,'r');
            xlabel('N minis');
            % xlabel(ax,sprintf('Mean number of minis in %g sec',dur));
        end
        box(ax,'off');
        if i == 1
            ylabel(ax,'Proportion');
        end    
        title(ax,plot_amps_labels(i));
        sgtitle(sprintf('Dish %g',n));
        [hd(i),pd(i)] = kstest2(Nb,Nd,alpha);  
        if hd(i)
            plot(ax.XLim(1) + 0.5*diff(ax.XLim),ax.YLim(1) + 0.95*diff(ax.YLim),'r*',...
                'MarkerSize',12);
        end
        if i == num_amps
            legend(ax,'Before','During','Box','off','Location','best');
        end
    end
    if save_figs
        printFig(fig,fig_fold,sprintf('CDFs_within_%gcells',num_dishes));
    end
end
%% Plot distribution of minis before and during - all dishes 
bin_width = 0.5;
convert_to_mHz = 0; 
dur = stim_frame/data{1}.exp_settings(1).sampling_rate; % sec

fig = figure; 
hd = zeros(1,num_amps);
pd = zeros(1,num_amps);
median_n_minis_before = median(mean_n_minis_before,1);
median_n_minis_during = median(mean_n_minis_during,1);
for i = 1:num_amps
    ax = subplot(1,num_amps,i);
    [Nb,edgesb] = histcounts(mean_n_minis_before(:,i),'BinWidth',bin_width,...
                            'Normalization','cdf');
    [Nd,edgesd] = histcounts(mean_n_minis_during(:,i),'BinWidth',bin_width,...
                            'Normalization','cdf');
    xb = edgesb(1:end-1) + bin_width/2;
    xd = edgesd(1:end-1) + bin_width/2;
    if convert_to_mHz
        plot(ax,xb,1e3*Nb/dur,'k'); hold on;
        plot(ax,xd,1e3*Nd/dur,'r');
        xlabel(ax,'Mean mini rate (mHz)');
    else
        plot(ax,xb,Nb,'k'); hold on;
        plot(ax,xd,Nd,'r');
        xlabel('N minis');
        % xlabel(ax,sprintf('Mean number of minis in %g sec',dur));
    end
    box(ax,'off');
    if i == 1
        ylabel(ax,'Proportion');
    end    
    title(ax,plot_amps_labels(i));
    [hd(i),pd(i)] = kstest2(Nb,Nd,alpha);  
    if hd(i)
        plot(ax.XLim(1) + 0.5*diff(ax.XLim),ax.YLim(1) + 0.95*diff(ax.YLim),'r*',...
            'MarkerSize',12);
    end
    if i == num_amps
        legend(ax,'Before','During','Box','off','Location','best');
    end
end

