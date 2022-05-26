function analyzeLGI1pHmScarletTrial(varargin)

psi_lgi1 = psi;
psi_lgi1.condition = in.lgi1_condition;
if ~isempty(psi_main.show_diff_image)
    psi_lgi1.show_diff_image = 1; % always show baseline
else
    psi_lgi1.show_diff_image = [];
end
psi_lgi1.plot_func = 'none'; % default skip plotting
lgi1_rois = plotTrial(def.lgi1_trial_name{i},in.lgi1_exp_settings,...
                    roiset_filenamei,[],psi_lgi1);
dish_foldi = fullfile(psi.data_fold,psi.exp_date,psi.reporter,...
                    psi.dish);
background_roiset = [roiset_filenamei '_background'];        
background_rois_filepath = fullfile(dish_foldi,background_roiset);
if exist([background_rois_filepath '.zip'],'file')
    lgi1_bg =  plotTrial(def.lgi1_trial_name{i},in.lgi1_exp_settings,...
                        background_roiset,[],psi_lgi1);
else
    lgi1_bg = []; 
    fprintf('WARNING: No background ROI for LGI1 normalization for %s/%s\n',...
            psi.exp_date,psi.dish)
end
% Save
lgi1_data = struct('data',lgi1_rois,'background',lgi1_bg);
roiset_filename_no_exti = getROIset_name(roiset_filenamei,...
                                             psi.transform_type,...
                                             psi.registration_rec);  
lgi1_datafile = sprintf('%s_%s_%s_%s_%s_%s_%s',psi.exp_date,...
                            psi.reporter,psi.dish,...
                            psi.roi_func_mode,...
                            roiset_filename_no_exti,...
                            in.lgi1_condition,def.lgi1_trial_name{i});       
lgi1_datafilepath = fullfile(dish_foldi,lgi1_datafile);            
save(lgi1_datafilepath,'-STRUCT','lgi1_data');
fprintf('Saved LGI1 data to %s\n',lgi1_datafile);
end
