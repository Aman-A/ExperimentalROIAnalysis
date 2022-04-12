%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = getDataFold();
exp_date = '20220331';
reporter = 'GluSnFR3';
dish = 'dish4';
div = 16; 
condition = 'control'; % 'control', '5nM_DTX', '50nM_DTX'
roiset_filename = [2 76 2 510];
% roiset_filename = 'RoiSet_pos1';
num_stim = 1; 
del = 3; % sec 
freq = 1/6; % Hz
dur = num_stim/freq; 
stim_vals = defineStimTrain(del,freq,dur); 
stim_wind = 0.5; % window
baseline_wind = 0.15; % frames before stim/s to take baseline
units = 'sec'; % specify units 'frames' or 'sec' 
sampling_rate = 200; % sampling rate (frames/sec)
exp_settings = ExperimentSettings(stim_vals,stim_wind,baseline_wind,...
                                  units,sampling_rate); % automatically converts to frames

% Plot settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.condition = condition;
ps.show_diff_image = [3]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0','deltaF'};
ps.roi_func_mode = 'combine'; % 'combine' or 'separate'
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 1;
if strcmp(ps.roi_func_mode,'combine')
    ps.y_lim = [-0.2 1.5];
else
    ps.y_lim = [];
end
ps.x_lim = [-baseline_wind,stim_wind*2]; 
ps.recenterROIs = 0;
ps.plot_func = 'deltaF_F0'; % 'deltaF_F0'
ps.transform_type = 'displace'; % 'none' or 'displace'
ps.registration_rec = fullfile(data_fold,exp_date,reporter,dish,...
                              'control','control.fits'); 
ps.show_roi_labels = 1;  
ps.close_img_after_save = 1;
% makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),{'test'},exp_settings)
%%
ps.condition = 'test'; % 'control', 'post_5mM'
img_name = 'control'; 
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%% Plot multiple trials, same condition
ps.condition = 'glut'; % 'glut'
img_names = {}; % use all images in condition folder
trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
%% Glutamate normalization
glut_img_name = 'glut_1uM';
ps.condition = 'glut';
ps.roi_func_mode = 'combine';
ps.x_lim = [];
ps.y_lim = [];
ps.show_diff_image = [3]; 
ps.save_fig = 2; 
ps.transform_type = 'displace';
load_existing_settings = 0; 
norm_func = 'deltaF_F0';
if load_existing_settings
    roiset_filename_load = 'RoiSet_pos1';
    roiset_filename_no_ext_load = getROIset_name(roiset_filename_load,ps.transform_type,...
                                            ps.registration_rec);
    data = load(fullfile(data_fold,exp_date,reporter,dish,ps.condition,...
                  sprintf('%s-combine-%s-data.mat',glut_img_name,roiset_filename_no_ext_load)));
    glut_exp_settings = data.settings;
    check_settings = 0;
else
    glut_exp_settings = ExperimentSettings(50,100,40,'frames',2);
    check_settings = 1;
end
mean_wind = []; 
% roiset_filename = [2 76 2 510];

[norm_out,ss_dFF0,glut_exp_settings] = analyzeGlutNormTrial(glut_img_name,...
                                        glut_exp_settings,roiset_filename,...
                                        ps,mean_wind,[],...
                                        'check_settings',check_settings,...
                                        'norm_func',norm_func);
%% Plot all glut trials
ps.condition = 'glut';
ps.analysis_funcs = {'peaks','peak_times'};
img_suffs = {'1uM','5uM','10uM','20uM','50uM','100uM','200uM','500uM','1mM',...
             '5mM','10mM'}; 
exp_settings_all(length(img_suffs)) = ExperimentSettings(10,5,5,'frames',1); 
img_names_all = cell(length(img_suffs),1);
for i = 1:length(img_suffs)
    roiset_filename_load = 'RoiSet_pos1';
    roiset_filename_no_ext_load = getROIset_name(roiset_filename_load,'displace',...
                                            ps.registration_rec);
    img_namei = sprintf('glut_%s',img_suffs{i}); 
    data = load(fullfile(data_fold,exp_date,reporter,dish,ps.condition,...
                  sprintf('%s-%s-%s-data.mat',img_namei,ps.roi_func_mode,roiset_filename_no_ext_load)));
    exp_settings_all(i) = data.settings;
%     exp_settings_all(i).baseline_wind = 50; 
%     exp_settings_all(i).stim_wind = 100; % for aligned traces to be same
    img_names_all{i} = sprintf('glut_%s',img_suffs{i});
end
ps.condition = 'glut'; % 'control', '50nM_DTX'
ps.transform_type = 'displace'; % 'displace'
ps.offset_factor = 0;
ps.x_lim = []; 
ps.plot_func = norm_func;
trials_data = plotTrials(img_names_all,exp_settings_all,roiset_filename,ps);
%% Load glut trials
condition = 'glut';
norm_func = 'deltaF_F0';
mov_mean_wind = 5;
% glut_concs = [1,5,10,20,50,100,200]; % uM
% img_suffs = {'1uM','5uM','10uM','20uM','50uM','100uM','200uM'}; 
glut_concs = [1,5,10,20,50,100,200,500,1e3,5e3,10e3]; % uM
img_suffs = {'1uM','5uM','10uM','20uM','50uM','100uM','200uM','500uM','1mM','5mM','10mM'}; 
img_data_fold = fullfile(data_fold,exp_date,reporter,dish,condition);
roi_func_mode = 'combine';
roiset_filename_no_ext = getROIset_name(roiset_filename,ps.transform_type,ps.registration_rec); 
rois = ROIs(roiset_filename);
% rois = ROIs(fullfile(data_fold,exp_date,reporter,dish,roiset_filename));
num_rois = rois.num_rois;
ss_peaks = zeros(num_rois,length(img_suffs)); % peak within mean_wind after moving average (3 frames)
ss_means = zeros(num_rois,length(img_suffs)); % mean of mean_wind
bslines = zeros(num_rois,length(img_suffs)); 
nbefore = 15;
nafter = 120; 
num_timepoints = nbefore + nafter + 1; 
F_traces = nan(num_timepoints,length(img_suffs)); 
% mean_traces = zeros(num_timepoints,length(img_suffs));
for i = 1:length(img_suffs)
    img_namei = sprintf('glut_%s',img_suffs{i}); 
   outi = load(fullfile(img_data_fold,sprintf('%s-%s-%s-data.mat',...
                img_namei,roi_func_mode,roiset_filename_no_ext))); 
    mean_wind = outi.settings.stim_wind_inds(:,1);
    ss_peaks(:,i) = max(movmean(outi.func_output.(norm_func)(mean_wind,:),mov_mean_wind),[],1);
%     ss_dFF0s(:,i) = max(outi.func_output.deltaF_F0(mean_wind,:),[],1);
    ss_means(:,i) = mean(outi.func_output.(norm_func)(mean_wind,:),1);
    bslines(:,i) = outi.func_output.baseline;
    stim_indexi = outi.settings.stim_vals(1);
    if stim_indexi + nafter > size(outi.func_output.(norm_func),1)
        end_ind =  size(outi.func_output.(norm_func),1);
    else
        end_ind = stim_indexi + nafter; 
    end
    n_framesi = length(stim_indexi-nbefore:end_ind);
    F_traces(1:n_framesi,i) = mean(outi.func_output.(norm_func)(stim_indexi-nbefore:end_ind,:),2);
%     mean_traces(:,i) = mean(outi.func_output.(norm_func)(outi.settings.stim_vals(1)-nbefore:outi.settings.stim_vals(1)+nafter,:),2);
end
mean_ss_meanFs = mean(ss_means,1,'omitnan'); 
std_ss_meanFs = std(ss_means,0,1,'omitnan');
sem_ss_meanFs = std_ss_meanFs/num_rois;
mean_ss_peaks = mean(ss_peaks,1,'omitnan'); 
std_ss_peaks = std(ss_peaks,0,1,'omitnan'); 
sem_ss_peaks = std_ss_peaks/num_rois; 
t = outi.settings.getTimeVector(num_timepoints); 
t = t-t(nbefore+1); 
fprintf('Done\n')
%% Fit to Hill equation
% F_i = F_0 + (F_max - F_0)*[Glu]^n/(K_d^n + [Glu]^n)
% x : glut_concs
% y : mean_ss_meanFs
% v857 Kd = 8.2 uM in cultured neurons from Aggarwal 2022, n = 1 +/- 0.2
% v857 Kd = 196 µM for soluble protein in solution 
save_fit = 1;
fit_eqn = 'a + (b - a)*(x.^c)./(d^c + x.^c)';
% deltaF/F
upper_bounds1 = [mean_ss_peaks(1),max(mean_ss_peaks),4,1000];
lower_bounds1 = [mean_ss_peaks(1),max(mean_ss_peaks),0,0.1]; 
start_points1 = [mean_ss_peaks(1),max(mean_ss_peaks),1,10];
% mean F
upper_bounds2 = [mean_ss_meanFs(1),max(mean_ss_meanFs),4,1000];
lower_bounds2 = [mean_ss_meanFs(1),max(mean_ss_meanFs),0,0.1]; 
start_points2 = [mean_ss_meanFs(1),max(mean_ss_meanFs),1,10];
s1 = fitoptions('Method','NonlinearLeastSquares',...
                'Lower',lower_bounds1,'Upper',upper_bounds1,...
                'Startpoint',start_points1);
s2 = fitoptions('Method','NonlinearLeastSquares',...
                'Lower',lower_bounds2,'Upper',upper_bounds2,...
                'Startpoint',start_points2);
f1 = fittype(fit_eqn,'options',s1);
f2 = fittype(fit_eqn,'options',s2);
[fitobj1,gof1,~] = fit(glut_concs',mean_ss_peaks',f1);
[fitobj2,gof2,~] = fit(glut_concs',mean_ss_meanFs',f2);
glut_concs_int = logspace(log10(glut_concs(1)),log10(glut_concs(end)),100); 
fprintf('Done with fits\n')
if save_fit
    fit_filename = sprintf('glut_fit_%s_%s_%s_%s',norm_func,exp_date,dish,roiset_filename_no_ext);
    fit_data = struct(); 
    fit_data.fitobj1 = fitobj1; % uses deltaF/F
    fit_data.gof1 = gof1; 
    fit_data.fitobj2 = fitobj2; % uses meanF
    fit_data.gof2 = gof2; 
    fit_data.glut_concs = glut_concs;
    fit_data.glut_concs_int = glut_concs_int; 
    fit_data.mean_ss_peaks = mean_ss_peaks;
    fit_data.std_ss_dFF0s = std_ss_peaks;
    fit_data.sem_ss_dFF0s = sem_ss_peaks;
    fit_data.mean_ss_meanFs = mean_ss_meanFs;
    fit_data.std_ss_meanFs = std_ss_meanFs;
    fit_data.sem_ss_meanFs = sem_ss_meanFs;       
    fit_data.ss_peaks = ss_peaks; 
    fit_data.ss_meanFs = ss_means;
    fit_data.bslines = bslines;
    fit_data.rois = rois;
    fit_data.F_traces = F_traces;
%     fit_data.mean_traces = mean_traces;    
    fit_data.t = t;      
    save([fit_filename '.mat'],'-STRUCT','fit_data');
    fprintf('Saved fit data to %s\n',fit_filename)
end
%% Plot
fit_mode = 1; % 1 - peak, 2 - mean
if fit_mode == 1
    fitobj = fitobj1; gof = gof1; 
    ylabel_str1 = 'Peak';
else    
    fitobj = fitobj2; gof = gof2; 
    ylabel_str1 = 'Steady State';
end
if strcmp(norm_func,'deltaF_F0')
    ylabel_str2 = '\Delta F/F_{0}'; 
elseif strcmp(norm_func,'deltaF')
    ylabel_str2 = '\Delta F (a.u.)'; 
end
ylabel_str = [ylabel_str1 '_' ylabel_str2];
disp(fitobj)
cols = jet(length(img_suffs)); 
fig = figure('Units','centimeters');
fig.Position(3:4) = [34.5 10];
ax = subplot(1,2,1);
if fit_mode == 1
    errorbar(ax,glut_concs,mean_ss_peaks,std_ss_peaks,'-ko');     
else
    errorbar(ax,glut_concs,mean_ss_meanFs,std_ss_meanFs,'-ko'); 
end
box(ax,'off'); hold(ax,'on');
ylabel(ax,ylabel_str); 
xlabel(ax,'Glutamate concentration (\mu M)'); 
hold on;
ax.XScale = 'log';
y_lim = ax.YLim;
ax.YLim = y_lim;
plot(ax,glut_concs_int,fitobj(glut_concs_int),'-r');
fitobj3 = fitobj; 
fitobj3.c = 1;
fitobj3.d = 8.2; % 196 soluble protein, 8.2 cultured neurons
plot(ax,glut_concs_int,fitobj3(glut_concs_int),'Color',[0.9290,0.6940,0.1250]);
% plot(glut_concs,mean_ss_dFF0s(1)*glut_concs/glut_concs(1),'--k');
% plot(glut_concs,mean_ss_meanFs(1)*glut_concs/glut_concs(1),'--k');
grid on;
title_str = sprintf('n = %.2f, K_{d} = %.3f \\mu M, R^{2} = %.3f',...
                    fitobj.c,fitobj.d,gof.rsquare);
title(ax,title_str)                
ax2 = subplot(1,2,2);
if fit_mode == 1
    l = plot(ax2,t,F_traces); box(ax2,'off'); hold(ax2,'on');
    l2 = plot(ax2,[t(1),t(end)],repmat(mean_ss_peaks,2,1),'--');
else
    l = plot(ax2,t,F_traces); box(ax2,'off'); hold(ax2,'on');
    l2 = plot(ax2,[t(1),t(end)],repmat(mean_ss_meanFs,2,1),'--');
end
ylabel(ax2,ylabel_str2); 
% l2 = plot([
for i = 1:length(l)
    l(i).Color = cols(i,:);
    l2(i).Color = cols(i,:);
end
legend(ax2,strrep(img_suffs,'_',' '),'Box','off','Location','bestoutside');
xlabel(ax2,'time (sec)');  
xlim(ax2,[t(1),t(end)]);
fig_name = sprintf('glut_curve%g_%s_%s_%s',fit_mode,exp_date,dish,roiset_filename_no_ext);
printFig(fig,'.',fig_name)
%%
norm_ss_dFF0s = (ss_peaks')./ss_peaks(:,1)';
fig = figure('U bnits','centimeters');
fig.Position(3:4) = [32 10];
plot(glut_concs,abs(norm_ss_dFF0s),'-o');
% hold on;
% plot(glut_concs,glut_concs/glut_concs(1),'--k'); 
ax = gca; grid on; box off; 
ax.XScale = 'log';
% ax.YScale = 'log';
xlabel('Glutamate concentration (\mu M)'); 
ylabel({'Steady state \Delta F/F_{0}','(norm. to 10 \mu M)'}); 
%% Plot multiple trials, multiple conditions    
% conditions = {'control','1mM_TEA','50nM_DTX','1mM_TEA_50nM_DTX'}; 
conditions = {'control','post_1mM','post_10mM','post_50mM'}; 
ps.save_fig = 1;
ps.plot_func = 'deltaF_F0';
ps.show_diff_image = [];      
ps.roi_func_mode = 'separate'; % 'combine' or 'separate'
if strcmp(ps.roi_func_mode,'combine')
    ps.y_lim = [-0.2 3];
else
    ps.y_lim = [];
end
if regexp(ps.plot_func,'aligned')
    ps.x_lim = [-baseline_wind, stim_wind];
else
    ps.x_lim = [-0.2 0.5];
end
% set(0,'DefaultFigureVisible','off') % to avoid window taking screen focus
out = plotTrials_multipleConditions(conditions,ps,exp_settings,...
                                    roiset_filename); 
% set(0,'DefaultFigureVisible','on')
%% Re-plot traces overlaid
summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
            ['figs_',out.roiset_filename_no_ext,'_' out.plot_settings.roi_func_mode]);       
ps.plot_func = 'deltaF_F0';
ps.x_lim = [-0.2 0.5]; 
ps.y_lim = [];
cond_inds = [1,2,3];
plotExperimentTracesOverlaidGrid(out,ps.plot_func,...
                                'fig_dir',summary_fig_dir,...                                
                                'save_fig',1,...
                                'y_lim',ps.y_lim,...
                                'x_lim',ps.x_lim,'cond_inds',cond_inds,...
                                'norm_peak_ind',0);
%% Glutamate normalization of evoked responses
glut_img_name = 'glut_5mM';
ps.condition = 'glut';
ps.x_lim = [];
ps.y_lim = [-0.1 30];
ps.show_diff_image = [3]; 
ps.save_fig = 2; 
glut_exp_settings = ExperimentSettings(126,97,109,'frames',2);
mean_wind = [127:224]; 
% roiset_filename = [2 76 2 510];
ps.transform_type = 'displace';
[norm_out,ss_dFF0,glut_exp_settings] = analyzeGlutNormTrial(glut_img_name,...
                                        glut_exp_settings,roiset_filename,...
                                        ps,mean_wind,out,...
                                        'check_settings',0);                            
%% Plot summary data
plot_inds = [1,2,3,4,5];
plotExpDefaultSummaryStats(out,out.plot_settings,'plot_inds',plot_inds,...
                         'roi_set_filename',roiset_filename,'save_fig',1) 
%% Generate diff image stack
stack_mode = 'diff'; % or 'bsline'
img_stack_name = sprintf('%s_%s_%s_%s_img_stack',exp_date,reporter,dish,...
                         stack_mode); 
makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),...
                      conditions,exp_settings,'img_stack_name',img_stack_name,...
                      'img_mode',stack_mode);  

%% Plot glutamate normalized summary figures
plot_inds = [1,2];
glut_summary_fig_dir = fullfile(data_fold,exp_date,reporter,dish,...
                           ['norm_figs_',roiset_filename '_' norm_out.plot_settings.roi_func_mode]);             
plotExpDefaultSummaryStats(norm_out,norm_out.plot_settings,'plot_inds',plot_inds,...
                         'summary_fig_dir',glut_summary_fig_dir,...
                         'roi_set_filename',roiset_filename,'save_fig',1) 
%% Plot glutamate normalized traces
ps.plot_func = 'deltaF_F0';
ps.x_lim = [-baseline_wind, stim_wind];
% ps.y_lim = [-0.02 0.332];
ps.y_lim = [-0.02 0.2]; 
cond_inds = [];
plotExperimentTracesOverlaidGrid(norm_out,ps.plot_func,...
                                'fig_dir',glut_summary_fig_dir,...                                
                                'save_fig',1,...
                                'y_lim',ps.y_lim,...
                                'x_lim',ps.x_lim,'cond_inds',cond_inds);