%% Separate multi-trial recordings into separate files
% Assume trials interleaved in repeating order, all repeated same number of
% times within single recording, ex for 2 conditions of 50 trials each:
% frames 1-50: trial 1 (condition 1)
% frames 51-100: trial 2 (condition 2)
% frames 101:150: trial 3 (condition 1)
% frames 151:200: trial 4 (condition 2)
% (loaded from 200 frame recording)
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '240522';
reporter = 'vGlut-pHluorin';
dish = 'dish1';
div = 15;

cond_suffs = {'0mA','1mA','-1mA'}; % repeating order of trials and suffixes
                                   % to add to names
trial_len = 50; % length of individual trial 
cond_fold = '1mA_100ms';
rec_names = {'trial_7.fits'};
%%
exp_fold = fullfile(data_fold,exp_date,reporter,dish);
num_conditions = length(cond_suffs);
output_folds = cellfun(@(x) sprintf('%s_%s',cond_fold,x),cond_suffs,'UniformOutput',0);
for i = 1:length(output_folds)
    mkdir(fullfile(exp_fold,output_folds{i}));
end
for i = 1:length(rec_names)
    reci = Recording(fullfile(exp_fold,cond_fold,rec_names{i}));
    reci.load(); 
    num_trials_total = reci.imsize(3)/trial_len;
    % break into individual trials within recording
    for j = 1:num_trials_total
       cond_ind = mod(j-1,num_conditions)+1; % condition index
       framesj = (trial_len*(j-1)+1):(j*trial_len);  % frame indices for this trial
       incond_trial_ind = floor(j/(num_conditions+0.1))+1; % trial number within condition
       rec_ij_vals = reci.vals(:,:,framesj);       
       recij_img_name = sprintf('%s_%s_%g',reci.img_name,cond_suffs{cond_ind},...
                                           incond_trial_ind);       
       recij_filepath = fullfile(exp_fold,output_folds{cond_ind},...
                            [recij_img_name,reci.format]);
       fitswrite(flipud(rec_ij_vals),recij_filepath);
       fprintf('%g: Saved trial %g, %s to %s\n',j,incond_trial_ind,...
                    cond_suffs{cond_ind},recij_img_name);
    end    
end