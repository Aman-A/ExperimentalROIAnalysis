%% Script to plot single trial
% Overlay single trials on same figure by running with different img_name
% 1kHz recording, 2 x 2 binning (half res of number of pixels)
data_fold = getDataFold();
exp_date= '20220526';
reporter = 'Archon_LGI1pHmScarlet';
dish = 'dish7';
div = 15; 
roiset_filename = 'RoiSet_pos8';
lgi1_exp_settings = ExperimentSettings(51,-1,50,'frames',2e3); % dummy frame rate                                 
% Optional settings
ps = plotTrialSettings;
ps.data_fold = data_fold;
ps.exp_date = exp_date;
ps.reporter = reporter;
ps.dish = dish;
ps.div = div; 
ps.show_diff_image = [1]; % can include [1,2,3]
ps.filt_width = 0;
ps.funcs = {'mean','median'};
ps.roi_func_mode = 'combine';
ps.save_processed_data = 1;
ps.load_processed_data = 1;
ps.save_fig = 1;
ps.plot_func = 'none'; % 'deltaF_F0_aligned' 'deltaF_F0'
ps.show_roi_labels = 1;
ps.close_img_after_save = 0; 
%%
ps.condition = 'lgi1_pHmScarlet';
img_name = 'trial_2';
trace_fig = figure;
trace_axis = gca;
lgi1_data = analyzeLGI1pHmScarletTrial(img_name,...
                        lgi1_exp_settings,roiset_filename,[],ps);                        

               