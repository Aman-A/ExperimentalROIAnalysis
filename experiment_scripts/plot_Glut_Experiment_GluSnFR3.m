%% Script to plot single trial
% Overlay single trails on same figure by running with different img_name
data_fold = getDataFold();
exp_date = '20220314';
reporter = 'GluSnFR3';
dish = 'dish10';
div = 20; 
% condition = 'control'; % 'control', '5nM_DTX', '50nM_DTX'
roiset_filename = 'RoiSet_pos3';
% roiset_filename = 'RoiSet_pos3b';
% roiset_filename = [1 78 1 512]; % full FOV
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
ps.show_diff_image = 3; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.roi_func_mode = 'separate'; % 'combine' or 'separate'
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
% makeExpDiffImageStack(fullfile(data_fold,exp_date,reporter,dish),{'control'},exp_settings);
%%
ps.condition = 'post_10mM'; % 'control', 'post_5mM'
img_name = 'post_10mM'; 
trace_fig = figure; 
trace_axis = gca;
datai = plotTrial(img_name,exp_settings,roiset_filename,...
                   trace_axis,ps);
%% Plot multiple trials, same condition
ps.condition = 'control'; % 'control', '50nM_DTX'
img_names = {}; % use all images in condition folder
trials_data = plotTrials(img_names,exp_settings,roiset_filename,ps);
%% Glutamate normalization
glut_img_name = 'glut_10uM';
ps.condition = 'glut';
ps.x_lim = [];
ps.y_lim = [-0.1 25];
ps.show_diff_image = [3]; 
ps.save_fig = 2; 
ps.transform_type = 'displace';
load_existing_settings = 1; 
if load_existing_settings
    roiset_filename_load = 'RoiSet_pos3';
    roiset_filename_no_ext_load = getROIset_name(roiset_filename_load,ps.transform_type,...
                                            ps.registration_rec);
    data = load(fullfile(data_fold,exp_date,reporter,dish,ps.condition,...
                  sprintf('%s-separate-%s-data.mat',glut_img_name,roiset_filename_no_ext_load)));
    glut_exp_settings = data.settings;
else
    glut_exp_settings = ExperimentSettings(50,100,40,'frames',2);
end
mean_wind = []; 
% roiset_filename = [2 76 2 510];

[norm_out,ss_dFF0,glut_exp_settings] = analyzeGlutNormTrial(glut_img_name,...
                                        glut_exp_settings,roiset_filename,...
                                        ps,mean_wind,[],...
                                        'check_settings',0);
%% Plot all glut trials
ps.condition = 'glut';
img_suffs = {'1uM','10uM','50uM','100uM','200uM','500uM','1mM','5mM','10mM','50mM'}; 
exp_settings_all(length(img_suffs)) = ExperimentSettings(10,5,5,'frames',1); 
img_names_all = cell(length(img_suffs),1);
for i = 1:length(img_suffs)
    roiset_filename_load = 'RoiSet_pos3';
    roiset_filename_no_ext_load = getROIset_name(roiset_filename_load,'displace',...
                                            ps.registration_rec);
    img_namei = sprintf('glut_%s',img_suffs{i}); 
    data = load(fullfile(data_fold,exp_date,reporter,dish,ps.condition,...
                  sprintf('%s-separate-%s-data.mat',img_namei,roiset_filename_no_ext_load)));
    exp_settings_all(i) = data.settings;
%     exp_settings_all(i).baseline_wind = 50; 
%     exp_settings_all(i).stim_wind = 100; % for aligned traces to be same
    img_names_all{i} = sprintf('glut_%s',img_suffs{i});
end
ps.condition = 'glut'; % 'control', '50nM_DTX'
ps.transform_type = 'none'; % 'displace'
ps.offset_factor = 0;
ps.x_lim = []; 
trials_data = plotTrials(img_names_all,exp_settings_all,roiset_filename,ps);
%% Load glut trials
condition = 'glut';
glut_concs = [1,10,50,100,200,500,1e3,5e3,10e3]; % uM
img_suffs = {'1uM','10uM','50uM','100uM','200uM','500uM','1mM','5mM','10mM'}; 
% glut_concs = [1,10,50,100,200,500,1e3,5e3,10e3,50e3]; % uM
% img_suffs = {'1uM','10uM','50uM','100uM','200uM','500uM','1mM','5mM','10mM','50mM'}; 
img_data_fold = fullfile(data_fold,exp_date,reporter,dish,condition);
roi_func_mode = 'separate';
roiset_filename_no_ext = getROIset_name(roiset_filename,ps.transform_type,ps.registration_rec); 
rois = ROIs(roiset_filename);
num_rois = rois.num_rois;
ss_dFF0s = zeros(num_rois,length(img_suffs)); 
ss_meanFs = zeros(num_rois,length(img_suffs)); 
bslines = zeros(num_rois,length(img_suffs)); 
nbefore = 20;
nafter = 120; 
num_timepoints = nbefore + nafter + 1; 
dFF0_traces = zeros(num_timepoints,length(img_suffs)); 
mean_traces = zeros(num_timepoints,length(img_suffs));
for i = 1:length(img_suffs)
    img_namei = sprintf('glut_%s',img_suffs{i}); 
   outi = load(fullfile(img_data_fold,sprintf('%s-%s-%s-data.mat',...
                img_namei,roi_func_mode,roiset_filename_no_ext))); 
    mean_wind = outi.settings.stim_wind_inds(:,1);
    ss_dFF0s(:,i) = mean(outi.func_output.deltaF_F0(mean_wind,:),1);
    ss_meanFs(:,i) = mean(outi.func_output.mean(mean_wind,:),1);
    bslines(:,i) = outi.func_output.baseline;
    dFF0_traces(:,i) = mean(outi.func_output.deltaF_F0(outi.settings.stim_vals(1)-nbefore:outi.settings.stim_vals(1)+nafter,:),2);
    mean_traces(:,i) = mean(outi.func_output.mean(outi.settings.stim_vals(1)-nbefore:outi.settings.stim_vals(1)+nafter,:),2);
end
mean_ss_meanFs = mean(ss_meanFs,1); 
std_ss_meanFs = std(ss_meanFs,0,1);
sem_ss_meanFs = std_ss_meanFs/num_rois;
mean_ss_dFF0s = mean(ss_dFF0s,1); 
std_ss_dFF0s = std(ss_dFF0s,0,1); 
sem_ss_dFF0s = std_ss_dFF0s/num_rois; 
t = outi.settings.getTimeVector(num_timepoints); 
t = t-t(nbefore+1); 
fprintf('Done\n')
%% Fit to Hill equation
% F_i = F_0 + (F_max - F_0)*[Glu]^n/(K_d^n + [Glu]^n)
% x : glut_concs
% y : mean_ss_meanFs
% v857 Kd = 8.2 uM from Aggarwal 2022, n = 1 +/- 0.2
save_fit = 1;
fit_eqn = 'a + (b - a)*(x.^c)./(d^c + x.^c)';
fit_mode = 1; % 1 - deltaF/F, 2 - mean F
if fit_mode == 1
    upper_bounds = [mean_ss_dFF0s(1),max(mean_ss_dFF0s),4,1000];
    lower_bounds = [mean_ss_dFF0s(1),max(mean_ss_dFF0s),0,0.1]; 
    start_points = [mean_ss_dFF0s(1),max(mean_ss_dFF0s),1,10];
    fprintf('Fitting deltaF/F\n')
else    
    upper_bounds = [mean_ss_meanFs(1),max(mean_ss_meanFs),4,1000];
    lower_bounds = [mean_ss_meanFs(1),max(mean_ss_meanFs),0,0.1]; 
    start_points = [mean_ss_meanFs(1),max(mean_ss_meanFs),1,10];
    fprintf('Fitting mean F\n')
end
s = fitoptions('Method','NonlinearLeastSquares',...
                'Lower',lower_bounds,'Upper',upper_bounds,...
                'Startpoint',start_points);
f = fittype(fit_eqn,'options',s);
[fitobj1,gof1,~] = fit(glut_concs',mean_ss_dFF0s',f);
[fitobj2,gof2,~] = fit(glut_concs',mean_ss_meanFs',f);
if fit_mode == 1
    fitobj = fitobj1; gof = gof1; 
else    
    fitobj = fitobj2; gof = gof2; 
end
glut_concs_int = logspace(log10(glut_concs(1)),log10(glut_concs(end)),100); 
disp(fitobj)
if save_fit
    fit_filename = sprintf('glut_fit_data_%s_%s_%s',exp_date,dish,roiset_filename_no_ext);
    fit_data = struct(); 
    fit_data.fitobj1 = fitobj1; % uses deltaF/F
    fit_data.gof1 = gof1; 
    fit_data.fitobj2 = fitobj2; % uses meanF
    fit_data.gof2 = gof2; 
    fit_data.glut_concs = glut_concs;
    fit_data.glut_concs_int = glut_concs_int; 
    fit_data.mean_ss_dFF0s = mean_ss_dFF0s;
    fit_data.std_ss_meanFs = std_ss_meanFs;
    fit_data.sem_ss_meanFs = sem_ss_meanFs;
    fit_data.mean_ss_meanFs = mean_ss_meanFs;
    fit_data.std_ss_dFF0s = std_ss_dFF0s;
    fit_data.sem_ss_dFF0s = sem_ss_dFF0s;
    fit_data.ss_dFF0s = ss_dFF0s; 
    fit_data.ss_meanFs = ss_meanFs;
    fit_data.bslines = bslines;
    fit_data.rois = rois;
    fit_data.dFF0_traces = dFF0_traces;
    fit_data.mean_traces = mean_traces;    
    fit_data.t = t;      
    save([fit_filename '.mat'],'-STRUCT','fit_data');
    fprintf('Saved fit data to %s\n',fit_filename)
end
%% Plot
cols = jet(length(img_suffs)); 
fig = figure('Units','centimeters');
fig.Position(3:4) = [34.5 10];
ax = subplot(1,2,1);
if fit_mode == 1
    errorbar(glut_concs,mean_ss_dFF0s,std_ss_dFF0s,'-ko');  
    ylabel('Steady state \Delta F/F_{0}'); 
    hold on;    
else
    errorbar(glut_concs,mean_ss_meanFs,std_ss_meanFs,'-ko'); 
    ylabel('Steady state F (a.u.)'); 
end
box off;
xlabel('Glutamate concentration (\mu M)'); 
hold on;
ax.XScale = 'log';
y_lim = ax.YLim;
ax.YLim = y_lim;
plot(ax,glut_concs_int,fitobj(glut_concs_int),'-r');
% plot(glut_concs,mean_ss_dFF0s(1)*glut_concs/glut_concs(1),'--k');
% plot(glut_concs,mean_ss_meanFs(1)*glut_concs/glut_concs(1),'--k');
grid on;
title_str = sprintf('n = %.2f, K_{d} = %.3f \\mu M, R^{2} = %.3f',...
                    fitobj.c,fitobj.d,gof.rsquare);
title(ax,title_str)                
subplot(1,2,2)
if fit_mode == 1
    l = plot(t,dFF0_traces); hold on;
    l2 = plot([t(1),t(end)],repmat(mean_ss_dFF0s,2,1),'--');
    ylabel('\Delta F / F_{0}');
else
    l = plot(t,mean_traces); hold on;
    l2 = plot([t(1),t(end)],repmat(mean_ss_meanFs,2,1),'--');
    ylabel('F (a.u.)');
end
box off;
% l2 = plot([
for i = 1:length(l)
    l(i).Color = cols(i,:);
    l2(i).Color = cols(i,:);
end
legend(strrep(img_suffs,'_',' '),'Box','off','Location','bestoutside');
xlabel('time (sec)');  
xlim([t(1),t(end)]);
fig_name = sprintf('glut_curve%g_%s_%s_%s',fit_mode,exp_date,dish,roiset_filename_no_ext);
printFig(fig,'.',fig_name)
%%
norm_ss_dFF0s = (ss_dFF0s')./ss_dFF0s(:,1)';
fig = figure('Units','centimeters');
fig.Position(3:4) = [32 10];
plot(glut_concs,norm_ss_dFF0s,'-o');
hold on;
plot(glut_concs,glut_concs/glut_concs(1),'--k'); 
ax = gca; grid on;
ax.XScale = 'log';
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