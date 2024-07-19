function separateMultiTrialRecordingsFunc(exp_fold,rec_fold,output_folds,rec_names,sweep_len)

num_conditions = length(output_folds);
% Make output folders
for i = 1:length(output_folds)
    out_foldi = fullfile(exp_fold,output_folds{i}); 
    if ~exist(out_foldi,'dir')
        mkdir(out_foldi);
    end
end
% Load and save separate sweeps
for i = 1:length(rec_names)
    reci = Recording(fullfile(exp_fold,rec_fold,rec_names{i}));
    reci.load(); 
    num_sweeps_total = reci.imsize(3)/sweep_len;
    % break into individual trials within recording
    img_namei = reci.img_name; 
    formati = reci.format; 
    valsi = reci.vals; 
    for j = 1:num_sweeps_total
        cond_ind = mod(j-1,num_conditions)+1; % condition index
        framesj = (sweep_len*(j-1)+1):(j*sweep_len);  % frame indices for this trial
        if num_conditions > 1
            incond_sweep_ind = floor(j/(num_conditions+0.1))+1; % trial number within condition
        else
            incond_sweep_ind = j;
        end
        %        rec_ij_vals = reci.vals(:,:,framesj);
        rec_ij_vals = valsi(:,:,framesj);
        recij_img_name = sprintf('%s_sweep%g',img_namei,incond_sweep_ind);
        recij_filepath = fullfile(exp_fold,output_folds{cond_ind},...
            [recij_img_name,formati]);
        fitswrite(rec_ij_vals,recij_filepath);
        fprintf('%g: Saved trial %g, %s to %s\n',j,incond_sweep_ind,...
                    output_folds{cond_ind},recij_img_name);
    end  
end