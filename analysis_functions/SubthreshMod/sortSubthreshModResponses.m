function [out,flipped_amp_rois,flipped_amp_cells] = ...
            sortSubthreshModResponses(subthresh_mod_responses,plot_vars,plot_amps,varargin)
% SORTSUBTHRESHMODRESPONSES Sort peaks (output of extractSubthreshModResponses) by
% direction of modulation
in.sort_by_mode = 1; % 1 - use max abs modulation to sort, 
                     % 2 - use 1st and last condition (i.e., longest duration or highest intensity)
in = sl.in.processVarargin(in,varargin);
out = subthresh_mod_responses; 
num_rois_per_dish = out.num_rois; 
num_rois_total = sum(num_rois_per_dish);
num_dishes = length(unique(out.dish_inds{1}));
if in.sort_by_mode == 1
    fprintf('Sorting current polarity based on max modulation\n')
else
    fprintf('Sorting current polarity based on modulation at 10 sec\n')
end
fprintf('NOTE: amplitudes must be symmetrical, e.g. [-1,-0.5,0.5,1] mA\n')
if ~isempty(out.peaks_after)
    include_after = 1; 
else
    include_after = 0; 
end
num_vars = length(plot_vars);
sort_inds = fliplr(1:num_vars);
dc_inds = [1,length(plot_vars)];
flipped_amp_rois = false(num_rois_total,1);
for i = 1:num_rois_total
    % [b,~,~,~,stats] = regress(peak_mod_during_per(i,:)',[plot_amps',ones(length(plot_amps),1)]);
    % Rsqi = stats(1); pi = stats(3);
    % lm = fitlm(plot_amps',peak_mod_during_per(i,:)')
    if in.sort_by_mode == 1
        [~,max_ind] = max(abs(out.peak_mod_during_per(i,:)));
    else
        [~,max_ind] = max(abs(out.peak_mod_during_per(i,dc_inds)));
        max_ind = dc_inds(max_ind);
    end
    if ( (out.peak_mod_during_per(i,max_ind) > 0 && plot_amps(max_ind) < 0) ... % negative current facilitates
            ||  (out.peak_mod_during_per(i,max_ind) < 0 && plot_amps(max_ind) > 0)) % or positive current suppresses
        out.peak_mod_during_per(i,:) = fliplr(out.peak_mod_during_per(i,:)); % flip polarity
        out.peak_mod_during_diff(i,:) = fliplr(out.peak_mod_during_diff(i,:));        
        out.mean_peaks_before(i,:) = fliplr(out.mean_peaks_before(i,:));
        out.mean_peaks_during(i,:) = fliplr(out.mean_peaks_during(i,:));
        out.peaks_before_mat(i,:,:) = out.peaks_before_mat(i,:,num_vars:-1:1);
        out.peaks_during_mat(i,:,:) = out.peaks_during_mat(i,:,num_vars:-1:1);
        out.success_before_mat(i,:,:) = out.success_before_mat(i,:,num_vars:-1:1);
        out.success_during_mat(i,:,:) = out.success_during_mat(i,:,num_vars:-1:1);
        if include_after
            out.peak_mod_after_per(i,:) = fliplr(out.peak_mod_after_per(i,:));
            out.peak_mod_after_diff(i,:) = fliplr(out.peak_mod_after_diff(i,:));        
            out.mean_peaks_after(i,:) = fliplr(out.mean_peaks_after(i,:));
            out.peaks_after_mat(i,:,:) = out.peaks_after_mat(i,:,num_vars:-1:1);
            out.success_after_mat(i,:,:) = out.success_after_mat(i,:,num_vars:-1:1);
        end
        for j = 1:num_vars
            out.peaks_before{sort_inds(j)}(i,:) = out.peaks_before{j}(i,:);
            out.peaks_during{sort_inds(j)}(i,:) = out.peaks_during{j}(i,:);            
            if include_after
                out.peaks_after{sort_inds(j)}(i,:) = out.peaks_after{j}(i,:);
                out.success_after{sort_inds(j)}(i,:) = out.success_after{j}(i,:);
            end
        end
        flipped_amp_rois(i) = true;
    end
end
flipped_amp_cells = false(num_dishes,1);
for i = 1:num_dishes
    if in.sort_by_mode == 1
        [~,max_ind] = max(abs(out.peak_mod_during_cell_per(i,:)));
    else
        [~,max_ind] = max(abs(out.peak_mod_during_cell_per(i,dc_inds)));
        max_ind = dc_inds(max_ind);
    end
    if ( (out.peak_mod_during_cell_per(i,max_ind) > 0 && plot_amps(max_ind) < 0) ... % negative current facilitates
            ||  (out.peak_mod_during_cell_per(i,max_ind) < 0 && plot_amps(max_ind) > 0)) % or positive current suppresses
        out.peak_mod_during_cell_per(i,:) = fliplr(out.peak_mod_during_cell_per(i,:)); % flip polarity
        out.peak_mod_during_cell_diff(i,:) = fliplr(out.peak_mod_during_cell_diff(i,:)); % flip polarity
        out.mean_peaks_before_cell(i,:) = fliplr(out.mean_peaks_before_cell(i,:));
        out.mean_peaks_during_cell(i,:) = fliplr(out.mean_peaks_during_cell(i,:));
        flipped_amp_cells(i) = true;
        if include_after
            out.peak_mod_after_cell_per(i,:) = fliplr(out.peak_mod_after_cell_per(i,:)); % flip polarity
            out.peak_mod_after_cell_diff(i,:) = fliplr(out.peak_mod_after_cell_diff(i,:)); % flip polarity
            out.mean_peaks_after_cell(i,:) = fliplr(out.mean_peaks_after_cell(i,:));
        end
    end
end
end
