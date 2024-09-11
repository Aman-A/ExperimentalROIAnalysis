function [out,flipped_amp_rois,flipped_amp_cells,varargout] = ...
            sortSubthreshModResponses(subthresh_mod_responses,plot_vars,...
                                       plot_amps,varargin)
% SORTSUBTHRESHMODRESPONSES Sort peaks (output of extractSubthreshModResponses) by
% direction of modulation
in.sort_by_mode = 1; % 1 - use max abs modulation to sort, 
                     % 2 - use 1st and last condition (i.e., longest duration or highest intensity)
                     % 3 - use input flipped_amp_rois and flipped_amp_cells
in.flipped_amp_rois = [];
in.flipped_amp_cells = []; 
in.remove_nonbi_mod = 0; % 1 to remove non-biphasic modulated (faciltiated or suppressed by both E-field polarities)                     
in = sl.in.processVarargin(in,varargin);
out = subthresh_mod_responses; 
if ~isempty(out.peaks_after)
    include_after = 1; 
else
    include_after = 0; 
end
num_rois_per_dish = out.num_rois; 
num_rois_total = sum(num_rois_per_dish,'omitnan');
%% Remove non bdirectional modulated ROIs
if isscalar(in.remove_nonbi_mod) && in.remove_nonbi_mod == 1 % TODO, MAKE SURE THIS WORKS FOR SORT_BY_MODE = 3 (INPUT ROIS TO FLIP)
    remove_rois = false(num_rois_total,1);
    for i = 1:num_rois_total
        if sign(out.peak_mod_during_per(i,1)) == sign(out.peak_mod_during_per(i,end))
            % fprintf('Removing ROI %g mod at %g mA = %.1f %%, %g mA = %.1f %%\n',...
            %         i,in.plot_amps(1),peak_mod_cont_per(i,1),...
            %         in.plot_amps(end),peak_mod_cont_per(i,end));
            remove_rois(i) = true;            
        end
    end        
    varargout = {remove_rois};
    % Remove data from these ROIs and recalculate cell averages
    if sum(remove_rois) > 0
        fprintf('Removing %g ROIs with non-bidirectional modulation\n',sum(remove_rois));
        out = removeROIsSubthreshModResponses(out,remove_rois,include_after,plot_vars);
        num_rois_per_dish = out.num_rois; 
        num_rois_total = sum(num_rois_per_dish,'omitnan');
    end
elseif isvector(in.remove_nonbi_mod)    
    if sum(in.remove_nonbi_mod) > 0
        fprintf('Removing %g ROIs with non-bidirectional modulation (input)\n',sum(in.remove_nonbi_mod));
        out = removeROIsSubthreshModResponses(out,in.remove_nonbi_mod,include_after,plot_vars);
        num_rois_per_dish = out.num_rois; 
        num_rois_total = sum(num_rois_per_dish,'omitnan');
        varargout = {in.remove_nonbi_mod};
    else
        varargout = {false(num_rois_total,1)};
    end    
else
    varargout = {[]};
end
%% Sort responses so negative polarity suppressing, positive is facilitating
if in.sort_by_mode == 1
    fprintf('Sorting current polarity based on direction of max modulation\n')
elseif in.sort_by_mode == 2
    fprintf('Sorting current polarity based on modulation at 10 sec\n')
elseif in.sort_by_mode == 3
    fprintf('Reusing input sorting\n')
end
fprintf('NOTE: amplitudes must be symmetrical, e.g. [-1,-0.5,0.5,1] mA\n')
num_vars = length(plot_vars);
sort_inds = fliplr(1:num_vars);
dc_inds = [1,length(plot_vars)];
flipped_amp_rois = false(num_rois_total,1);
% Sort within ROI
for i = 1:num_rois_total
    % [b,~,~,~,stats] = regress(peak_mod_during_per(i,:)',[plot_amps',ones(length(plot_amps),1)]);
    % Rsqi = stats(1); pi = stats(3);
    % lm = fitlm(plot_amps',peak_mod_during_per(i,:)')
    if in.sort_by_mode == 1
        [~,max_ind] = max(abs(out.peak_mod_during_per(i,:)));
        flip_roi = ( (out.peak_mod_during_per(i,max_ind) > 0 && plot_amps(max_ind) < 0) ... % negative current facilitates
                ||  (out.peak_mod_during_per(i,max_ind) < 0 && plot_amps(max_ind) > 0)); % or positive current suppresses            
    elseif in.sort_by_mode == 2
        [~,max_ind] = max(abs(out.peak_mod_during_per(i,dc_inds)));
        max_ind = dc_inds(max_ind);
        flip_roi = ( (out.peak_mod_during_per(i,max_ind) > 0 && plot_amps(max_ind) < 0) ... % negative current facilitates
                ||  (out.peak_mod_during_per(i,max_ind) < 0 && plot_amps(max_ind) > 0)); % or positive current suppresses            
    elseif in.sort_by_mode == 3        
        flip_roi = in.flipped_amp_rois(i); 
    end
    if flip_roi
        out.peak_mod_during(i,:) = fliplr(out.peak_mod_during(i,:)); % flip polarity
        out.peak_mod_during_per(i,:) = fliplr(out.peak_mod_during_per(i,:)); % flip polarity
        out.peak_mod_during_diff(i,:) = fliplr(out.peak_mod_during_diff(i,:));        
        out.mean_peaks_before(i,:) = fliplr(out.mean_peaks_before(i,:));
        out.mean_peaks_during(i,:) = fliplr(out.mean_peaks_during(i,:));
        out.peaks_before_mat(i,:,:) = out.peaks_before_mat(i,:,num_vars:-1:1);
        out.peaks_during_mat(i,:,:) = out.peaks_during_mat(i,:,num_vars:-1:1);
        out.success_before_mat(i,:,:) = out.success_before_mat(i,:,num_vars:-1:1);
        out.success_during_mat(i,:,:) = out.success_during_mat(i,:,num_vars:-1:1);
        out.mean_peaks_before_mat_tr(i,:,:) = out.mean_peaks_before_mat_tr(i,:,num_vars:-1:1);
        out.mean_peaks_during_mat_tr(i,:,:) = out.mean_peaks_during_mat_tr(i,:,num_vars:-1:1);
        out.mean_peaks_before_mat_tr_norm(i,:,:) = out.mean_peaks_before_mat_tr_norm(i,:,num_vars:-1:1);
        out.mean_peaks_during_mat_tr_norm(i,:,:) = out.mean_peaks_during_mat_tr_norm(i,:,num_vars:-1:1);
        if include_after
            out.peak_mod_after(i,:) = fliplr(out.peak_mod_after(i,:));
            out.peak_mod_after_per(i,:) = fliplr(out.peak_mod_after_per(i,:));
            out.peak_mod_after_diff(i,:) = fliplr(out.peak_mod_after_diff(i,:));        
            out.mean_peaks_after(i,:) = fliplr(out.mean_peaks_after(i,:));
            out.peaks_after_mat(i,:,:) = out.peaks_after_mat(i,:,num_vars:-1:1);
            out.success_after_mat(i,:,:) = out.success_after_mat(i,:,num_vars:-1:1);
            out.mean_peaks_after_mat_tr(i,:,:) = out.mean_peaks_after_mat_tr(i,:,num_vars:-1:1);
            out.mean_peaks_after_mat_tr_norm(i,:,:) = out.mean_peaks_after_mat_tr_norm(i,:,num_vars:-1:1);
        end
        for j = 1:floor(num_vars/2) % flip data from each amp with opposite polarity, skip middle if odd number of amps (non-paired)
            % Peaks before 
            peaks_beforeji = out.peaks_before{j}(i,:);
            out.peaks_before{j}(i,:) = out.peaks_before{sort_inds(j)}(i,:);
            out.peaks_before{sort_inds(j)}(i,:) = peaks_beforeji;
            % Peaks during
            peaks_duringji = out.peaks_during{j}(i,:);
            out.peaks_during{j}(i,:) = out.peaks_during{sort_inds(j)}(i,:);
            out.peaks_during{sort_inds(j)}(i,:) = peaks_duringji;
            % Successful release before
            success_beforeji = out.success_before{j}(i,:);            
            out.success_before{j}(i,:) = out.success_before{sort_inds(j)}(i,:);
            out.success_before{sort_inds(j)}(i,:) = success_beforeji;
            % Successful release during
            success_duringji = out.success_during{j}(i,:);            
            out.success_during{j}(i,:) = out.success_during{sort_inds(j)}(i,:);
            out.success_during{sort_inds(j)}(i,:) = success_duringji;
            % deltaF/F stim-aligned traces before
            dF_al2_beforeji = out.dF_al2_before{j}(:,i,:);
            out.dF_al2_before{j}(:,i,:) = out.dF_al2_before{sort_inds(j)}(:,i,:);
            out.dF_al2_before{sort_inds(j)}(:,i,:) = dF_al2_beforeji;
            % deltaF/F stim-aligned traces during
            dF_al2_duringji = out.dF_al2_during{j}(:,i,:);
            out.dF_al2_during{j}(:,i,:) = out.dF_al2_during{sort_inds(j)}(:,i,:);
            out.dF_al2_during{sort_inds(j)}(:,i,:) = dF_al2_duringji;
            if include_after
                % Peaks after
                peaks_afterji = out.peaks_after{j}(i,:);
                out.peaks_after{j}(i,:) = out.peaks_after{sort_inds(j)}(i,:);
                out.peaks_after{sort_inds(j)}(i,:) = peaks_afterji;                
                % Successful release after
                success_afterji = out.success_after{j}(i,:);            
                out.success_after{j}(i,:) = out.success_after{sort_inds(j)}(i,:);
                out.success_after{sort_inds(j)}(i,:) = success_afterji;
                % deltaF/F stim-aligned traces after
                dF_al2_afterji = out.dF_al2_after{j}(:,i,:);
                out.dF_al2_after{j}(:,i,:) = out.dF_al2_after{sort_inds(j)}(:,i,:);
                out.dF_al2_after{sort_inds(j)}(:,i,:) = dF_al2_afterji;
            end
        end
        flipped_amp_rois(i) = true;
    end
end
% Sort within cell (average across ROIs within cell)
num_dishes = length(out.num_rois);
flipped_amp_cells = false(num_dishes,1);
for i = 1:num_dishes    
    if isnan(out.num_rois(i)); continue; end 
    if in.sort_by_mode == 1
        [~,max_ind] = max(abs(out.peak_mod_during_cell_per(i,:)));
        flip_cell = ( (out.peak_mod_during_cell_per(i,max_ind) > 0 && plot_amps(max_ind) < 0) ... % negative current facilitates
            ||  (out.peak_mod_during_cell_per(i,max_ind) < 0 && plot_amps(max_ind) > 0)); % or positive current suppresses            
    elseif in.sort_by_mode == 2
        [~,max_ind] = max(abs(out.peak_mod_during_cell_per(i,dc_inds)));
        max_ind = dc_inds(max_ind);
        flip_cell = ( (out.peak_mod_during_cell_per(i,max_ind) > 0 && plot_amps(max_ind) < 0) ... % negative current facilitates
            ||  (out.peak_mod_during_cell_per(i,max_ind) < 0 && plot_amps(max_ind) > 0)); % or positive current suppresses            
    elseif in.sort_by_mode == 3
        flip_cell = in.flipped_amp_cells(i); 
    end
    if flip_cell
        out.peak_mod_during_cell(i,:) = fliplr(out.peak_mod_during_cell(i,:)); % flip polarity
        out.peak_mod_during_cell_per(i,:) = fliplr(out.peak_mod_during_cell_per(i,:)); % flip polarity
        out.peak_mod_during_cell_diff(i,:) = fliplr(out.peak_mod_during_cell_diff(i,:)); % flip polarity
        out.mean_peaks_before_cell(i,:) = fliplr(out.mean_peaks_before_cell(i,:));
        out.mean_peaks_during_cell(i,:) = fliplr(out.mean_peaks_during_cell(i,:));
        out.mean_peaks_before_cell_tr(i,:,:) = out.mean_peaks_before_cell_tr(i,:,num_vars:-1:1);
        out.mean_peaks_during_cell_tr(i,:,:) = out.mean_peaks_during_cell_tr(i,:,num_vars:-1:1);
        out.mean_peaks_before_cell_tr_norm(i,:,:) = out.mean_peaks_before_cell_tr_norm(i,:,num_vars:-1:1);
        out.mean_peaks_during_cell_tr_norm(i,:,:) = out.mean_peaks_during_cell_tr_norm(i,:,num_vars:-1:1);
        flipped_amp_cells(i) = true;
        if include_after
            out.peak_mod_after_cell(i,:) = fliplr(out.peak_mod_after_cell(i,:)); % flip polarity
            out.peak_mod_after_cell_per(i,:) = fliplr(out.peak_mod_after_cell_per(i,:)); % flip polarity
            out.peak_mod_after_cell_diff(i,:) = fliplr(out.peak_mod_after_cell_diff(i,:)); % flip polarity
            out.mean_peaks_after_cell(i,:) = fliplr(out.mean_peaks_after_cell(i,:));
            out.mean_peaks_after_cell_tr(i,:,:) = out.mean_peaks_after_cell_tr(i,:,num_vars:-1:1);
            out.mean_peaks_after_cell_tr_norm(i,:,:) = out.mean_peaks_after_cell_tr_norm(i,:,num_vars:-1:1);
        end
    end
end
end
%%
function out = removeROIsSubthreshModResponses(out,remove_rois,include_after,plot_vars)
    % dish_inds    
    for i = 1:length(out.dish_inds)
        out.dish_inds{i} = out.dish_inds{i}(~remove_rois);     
    end
    out.roi_in_dish_index(remove_rois) = [];     
    num_dishes = length(unique(out.dish_inds{1}));
    % num_rois per dish
    out.num_rois = nan(1,num_dishes);
    for i = 1:num_dishes
        out.num_rois(i) = sum(out.dish_inds{1}==i);
    end    

    out.peaks_before = cellfun(@(x) x(~remove_rois,:),out.peaks_before,'UniformOutput',0);
    out.peaks_during = cellfun(@(x) x(~remove_rois,:),out.peaks_during,'UniformOutput',0);
    out.dF_al2_before = cellfun(@(x) x(:,~remove_rois,:),out.dF_al2_before,'UniformOutput',0);
    out.dF_al2_during = cellfun(@(x) x(:,~remove_rois,:),out.dF_al2_during,'UniformOutput',0);
    out.peaks_before_mat = out.peaks_before_mat(~remove_rois,:,:); 
    out.peaks_during_mat = out.peaks_during_mat(~remove_rois,:,:);     
    out.success_before = cellfun(@(x) x(~remove_rois,:),out.success_before,'UniformOutput',0);
    out.success_during = cellfun(@(x) x(~remove_rois,:),out.success_during,'UniformOutput',0);
    out.success_before_mat = out.success_before_mat(~remove_rois,:,:);
    out.success_during_mat = out.success_during_mat(~remove_rois,:,:);    
    % recalculate averages and differences
    out.mean_peaks_before = squeeze(mean(out.peaks_before_mat,2,'omitnan'));
    out.mean_peaks_during = squeeze(mean(out.peaks_during_mat,2,'omitnan'));
    out.peak_mod_during = out.mean_peaks_during./out.mean_peaks_before; 
    out.peak_mod_during_per = 100*(out.peak_mod_during - 1); % percent change
    out.peak_mod_during_diff = out.mean_peaks_during - out.mean_peaks_before; % difference
    
    % average within cell
    mean_peaks_before_cell = zeros(num_dishes,length(plot_vars));
    mean_peaks_during_cell = zeros(num_dishes,length(plot_vars));
    for i = 1:num_dishes
        mean_peaks_before_cell(i,:) = squeeze(mean(out.peaks_before_mat(out.dish_inds{1}==i,:,:),[1 2],'omitnan'));
        mean_peaks_during_cell(i,:) = squeeze(mean(out.peaks_during_mat(out.dish_inds{1}==i,:,:),[1 2],'omitnan'));
    end
    out.mean_peaks_before_cell = mean_peaks_before_cell;
    out.mean_peaks_during_cell = mean_peaks_during_cell;
    out.peak_mod_during_cell = out.mean_peaks_during_cell./out.mean_peaks_before_cell;
    out.peak_mod_during_cell_diff = out.mean_peaks_during_cell - out.mean_peaks_before_cell;
    out.peak_mod_during_cell_per = 100*(out.peak_mod_during_cell - 1); % percent change
    if include_after
        out.peaks_after = cellfun(@(x) x(~remove_rois,:),out.peaks_after,...
                                'UniformOutput',0);
        out.dF_al2_after = cellfun(@(x) x(:,~remove_rois,:),out.dF_al2_after,...
                                'UniformOutput',0);
        out.peaks_after_mat = out.peaks_after_mat(~remove_rois,:,:);             
        out.mean_peaks_after = squeeze(mean(out.peaks_after_mat,2,'omitnan'));
        out.peak_mod_after = out.mean_peaks_after./out.mean_peaks_before;
        out.peak_mod_after_per = 100*(out.peak_mod_after - 1); % percent change
        out.peak_mod_after_diff = out.mean_peaks_after - out.mean_peaks_before; % difference
        out.success_after = cellfun(@(x) x(~remove_rois,:),out.success_after,'UniformOutput',0);
        out.success_after_mat = out.success_after_mat(~remove_rois,:,:);    
        % Average within cell
        mean_peaks_after_cell = zeros(num_dishes,length(plot_vars));
        for i = 1:num_dishes
            mean_peaks_after_cell(i,:) = squeeze(mean(out.peaks_after_mat(out.dish_inds{1}==i,:,:),[1 2],'omitnan'));
        end
        out.mean_peaks_after_cell = mean_peaks_after_cell;
        out.peak_mod_after_cell = out.mean_peaks_after_cell./out.mean_peaks_after_cell;
        out.peak_mod_after_cell_diff = out.mean_peaks_after_cell - out.mean_peaks_after_cell;
        out.peak_mod_after_cell_per = 100*(out.peak_mod_after_cell - 1); % percent change
    end    
end
