%% Separate multi-trial recordings into separate files
% Assume trials interleaved in repeating order, all repeated same number of
% times within single recording, ex for 2 conditions of 50 trials each:
% frames 1-50: trial 1 (condition 1)
% frames 51-100: trial 2 (condition 2)
% frames 101:150: trial 3 (condition 1)
% frames 151:200: trial 4 (condition 2)
% (loaded from 200 frame recording)
data_fold = fullfile(getDataFold('aman_thor'),'DC_mod_experiments'); 
exp_date = '241114';
reporter = 'GluSnFR3_SynmRuby';
dish = 'dish5';

cond_suffs = {'0VpmG','50VpmG'}; % repeating order of trials and suffixes

trial_len = 800; % length of individual trial 
cond_fold = '2mABi_PPF';
% rec_names = {'3mABi_PPF.fits'};
% rec_names = [[cond_fold,'.fits'],numericVec2chars([1:3,5:10],sprintf('%s_%%g.fits',cond_fold))];
rec_names = arrayfun(@(x) [reindexFileNameForAndor(cond_fold,x) '.fits'],...
                            1:10,'UniformOutput',0);
% rec_names = numericVec2chars(1:9,'3mABi_PPF_%g.fits');
start_cond_trial_ind = 1; % trial number for first sweep within condition
%%
exp_fold = fullfile(data_fold,exp_date,reporter,dish);
num_conditions = length(cond_suffs);
output_folds = cellfun(@(x) sprintf('%s_%s',cond_fold,x),cond_suffs,'UniformOutput',0);
start_rec_trial_ind = 0; % trial index counter across recordings
for i = 1:length(rec_names)
    reci = Recording(fullfile(exp_fold,cond_fold,rec_names{i}));
    reci.load(); 
    num_trials_total = reci.imsize(3)/trial_len;    
    % break into individual trials within recording
    for j = 1:num_trials_total
       cond_ind = mod(j-1,num_conditions)+1; % condition index
       if ~exist(fullfile(exp_fold,output_folds{cond_ind}),'dir')
           mkdir(fullfile(exp_fold,output_folds{cond_ind}));
       end
       framesj = (trial_len*(j-1)+1):(j*trial_len);  % frame indices for this trial
       incond_trial_ind = start_cond_trial_ind + ...
                         floor(j/(num_conditions+0.1)) + ...
                          num_trials_total*floor(i/(length(rec_names)+0.1)) + ...
                          start_rec_trial_ind; % trial number within condition
%        rec_ij_vals = flipud(reci.vals(:,:,framesj));
       rec_ij_vals = reci.vals(:,:,framesj);
       recij_img_name = sprintf('%s_%s_%g',reci.img_name,cond_suffs{cond_ind},...
                                           incond_trial_ind);       
       recij_filepath = fullfile(exp_fold,output_folds{cond_ind},...
                            [recij_img_name,reci.format]);
       fitswrite(rec_ij_vals,recij_filepath);
       fprintf('%g: Saved frames %g to %g to trial %g, %s to %s\n',j,framesj(1),framesj(end),...
                    incond_trial_ind,cond_suffs{cond_ind},recij_img_name);
    end  
    start_rec_trial_ind = start_rec_trial_ind + num_trials_total/num_conditions; 
end
fprintf('Done\n')