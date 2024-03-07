function [out,data_out] = extractSubthreshModResponses(data,def,plot_vars,...
                                        min_num_trials_per_lvl,spike_thresh,...
                                        varargin)
% EXTRACTSUBTHRESHMODRESPONSES
% TODO: 
% Implement quality control filter:
% Baseline stability within trial (DC off)
if nargin < 4
    min_num_trials_per_lvl = 0; 
end
if nargin < 5
    spike_thresh = 3; % peaks <  spike_thresh x STD are failures
end
% Params for spike detection
in.spike_window = 60*1e-3; % sec
in.spike_min_width = [20 80]*1e-3; % sec
in.spike_min_amp = 0.06; % deltaF/F0
in.plot_var = 'subthresh_amps'; % independent variable of experiment
% Quality control criteria
in.qc_settings = {}; % use defaults
in.exclude_rois = {};
in.min_rois_included = 1; % need this many ROIs per cell after quality control
in = sl.in.processVarargin(in,varargin);
num_vars = length(plot_vars);
num_dishes = length(data); 
% independent variable, e.g., amplitude or duration 
subthresh_lvls = cellfun(@(x) str2num(x),def.(in.plot_var),'UniformOutput',0); %#ok<*ST2NM> 

% Extract amps to analyze
peaks_before = cell(1,num_vars);
peaks_during = cell(1,num_vars);
peaks_after = cell(1,num_vars);
dish_inds = cell(1,num_vars);
dF_al2_before = cell(1,num_vars);
dF_al2_during = cell(1,num_vars);
dF_al2_after = cell(1,num_vars);
success_before = cell(1,num_vars);
success_during = cell(1,num_vars);
success_after = cell(1,num_vars);
num_rois = nan(1,num_dishes);
max_num_peaks = zeros(1,length(plot_vars)); % max number of peaks across all dishes
max_Nt_al2 = zeros(1,length(plot_vars)); % max number of time points for deltaF_F0_aligned2 across all dishes
plot_data_inds = cell(1,num_dishes);
for i = 1:num_dishes    
    for j = 1:length(plot_vars)
        if any(subthresh_lvls{i} == plot_vars(j))    
            data_inds = find(subthresh_lvls{i}==plot_vars(j));
            dup_plot_vars = find(plot_vars==plot_vars(j)); % 
            data_ind = data_inds(dup_plot_vars==j);
            plot_data_inds{i} = [plot_data_inds{i};data_ind];
            max_num_peaks(j) = max(max_num_peaks(j),...
                prod(size(data{i}.peaks_deltaF_F0_all{data_ind},[3 4]))); % subthresh_lvls{i}==plot_vars(j)
            max_Nt_al2(j) = max(max_Nt_al2(j),size(data{i}.deltaF_F0_aligned2_all{data_ind},1));
        end
    end
end
max_num_peaks = repmat(max(max_num_peaks),1,num_vars);
exclude_rois = cell(1,num_dishes);
data_out = cell(size(data));
for i = 1:num_dishes
    % Apply quality control to ROIs
    if ~isempty(in.exclude_rois)
        datai = removeROIsExpData(data{i},in.exclude_rois{i});
    else
        [datai,exclude_rois{i}] = qualityControlROIs(data{i},in.qc_settings,plot_data_inds{i});
    end
    data_out{i} = datai; 
    peaksi = datai.peaks_deltaF_F0_all;
    dF_al2i = datai.deltaF_F0_aligned2_all;     
    num_roisi = datai.rois_all{1}{1}.num_rois;    
    if num_roisi < in.min_rois_included
        fprintf('Skipping dish %g, only %g ROIs (< %g)\n',i,num_roisi,in.min_rois_included);
        continue; % skip this dish
    end
    num_rois(i) = num_roisi;
    if size(peaksi{1},1) == 3
        include_after = 1;
    else
        include_after = 0;
    end 
    for jp = 1:length(plot_vars)  % index within output dataset for plotting/analysis      
        if any(plot_vars(jp) == subthresh_lvls{i})                        
            jd = plot_data_inds{i}(jp);                                                         
            peaksij = peaksi{jd}; % 3 x num_rois x 20 x num_trials
            dF_al2ij = dF_al2i{jd}; 

            num_trials  = size(peaksij,4);                   
            num_peaksij = prod(size(peaksij,[3 4]));
            dish_inds{jp} = [dish_inds{jp};i*ones(num_roisi,1)];
%             max_num_peaks = max(num_peaksij,size(peaks_before{peak_indj},2));
            if num_trials >= min_num_trials_per_lvl                            
                % add peaks from this experiment, fill with nans if fewer than
                % max number of trials                
                peaks_before{jp} = [[peaks_before{jp},nan(size(peaks_before{jp},1),...
                                                                        max_num_peaks(jp)-size(peaks_before{jp},2))];...
                                             [squeeze(peaksij(1,:,:)),...
                                             nan(size(peaksij,2),max_num_peaks(jp)-num_peaksij)]];
                peaks_during{jp} = [[peaks_during{jp},nan(size(peaks_during{jp},1),...
                                                                        max_num_peaks(jp)-size(peaks_during{jp},2))];...
                                             [squeeze(peaksij(2,:,:)),...
                                             nan(size(peaksij,2),max_num_peaks(jp)-num_peaksij)]];
                if include_after
                    peaks_after{jp} = [[peaks_after{jp},nan(size(peaks_after{jp},1),...
                                                                            max_num_peaks(jp)-size(peaks_after{jp},2))];...
                                                 [squeeze(peaksij(3,:,:)),...
                                                 nan(size(peaksij,2),max_num_peaks(jp)-num_peaksij)]];      
                else
                    peaks_after{jp} = [[peaks_after{jp},nan(size(peaks_after{jp},1),...
                                                                            max_num_peaks(jp)-size(peaks_after{jp},2))];...
                                                 [nan(size(peaksij,2),num_peaksij),...
                                                 nan(size(peaksij,2),max_num_peaks(jp)-num_peaksij)]];      
                end
                % get deltaF_F0_aligned2 (individual stim-aligned traces within
                % ROI), assumes baseline_wind and stim_wind same for all
                % experiments (Todo: make compatible with different windows)            
                if ~isempty(dF_al2_before{jp}) && max_num_peaks(jp) > size(dF_al2_before{jp},3) % pad experiments with fewer trials with nans
                    dF_al2_before{jp} = cat(3,dF_al2_before{jp},...
                        nan([size(dF_al2_before{jp},[1 2]),max_num_peaks(jp)-size(dF_al2_before{jp},3)]));
                    dF_al2_during{jp} = cat(3,dF_al2_during{jp},...
                        nan([size(dF_al2_during{jp},[1 2]),max_num_peaks(jp)-size(dF_al2_during{jp},3)]));
                    dF_al2_after{jp} = cat(3,dF_al2_after{jp},...
                            nan([size(dF_al2_after{jp},[1 2]),max_num_peaks(jp)-size(dF_al2_after{jp},3)]));
                end
                dF_al2_beforeij = reshape(dF_al2ij(:,:,1,:),...
                                    [size(dF_al2ij,[1,2]),num_peaksij]);
                dF_al2_before{jp} = [dF_al2_before{jp},...
                                            cat(3,dF_al2_beforeij,...
                                                nan([size(dF_al2_beforeij,...
                                                    [1,2]),max_num_peaks(jp)-size(dF_al2_beforeij,3)]))];
                dF_al2_duringij = reshape(dF_al2ij(:,:,2,:),...
                                    [size(dF_al2ij,[1,2]),num_peaksij]);            
                dF_al2_during{jp} = [dF_al2_during{jp},...
                                            cat(3,dF_al2_duringij,...
                                                nan([size(dF_al2_duringij,...
                                                [1,2]),max_num_peaks(jp)-size(dF_al2_duringij,3)]))];
                if include_after
                    dF_al2_afterij = reshape(dF_al2ij(:,:,3,:),...
                                        [size(dF_al2ij,[1,2]),num_peaksij]);                                
                else
                    dF_al2_afterij = nan([size(dF_al2ij,[1,2]),num_peaksij]);   
                end
                dF_al2_after{jp} = [dF_al2_after{jp},...
                                                cat(3,dF_al2_afterij,...
                                                    nan([size(dF_al2_afterij,...
                                                    [1,2]),max_num_peaks(jp)-size(dF_al2_afterij,3)]))];                
                % dish_inds{peak_indj} = [dish_inds{peak_indj};i*ones(num_roisi,1)];
                exp_settingsij = datai.exp_settings(jd);
                detectSpikesArgs = {exp_settingsij,spike_thresh,...
                                    'spike_window',in.spike_window,...
                                    'min_width',in.spike_min_width,...
                                    'min_amp',in.spike_min_amp};                
                success_beforeij = detectSpikesAlignedTraces(dF_al2_beforeij,...
                                                             detectSpikesArgs{:}); %
                success_before{jp} = [[success_before{jp},nan(size(success_before{jp},1),...
                                                                        max_num_peaks(jp)-size(success_before{jp},2))];...
                                             [success_beforeij,...
                                             nan(size(success_beforeij,1),max_num_peaks(jp)-num_peaksij)]];
                success_duringij = detectSpikesAlignedTraces(dF_al2_duringij,...
                                                             detectSpikesArgs{:}); %
                success_during{jp} = [[success_during{jp},nan(size(success_during{jp},1),...
                                                                        max_num_peaks(jp)-size(success_during{jp},2))];...
                                             [success_duringij,...
                                             nan(size(success_duringij,1),max_num_peaks(jp)-num_peaksij)]];
                if include_after
                    success_afterij = detectSpikesAlignedTraces(dF_al2_afterij,...
                                                             detectSpikesArgs{:}); %
                    success_after{jp} = [[success_after{jp},nan(size(success_after{jp},1),...
                                                                            max_num_peaks(jp)-size(success_after{jp},2))];...
                                                 [success_afterij,...
                                                 nan(size(success_afterij,1),max_num_peaks(jp)-num_peaksij)]];      
                else
                    success_after{jp} = [[success_after{jp},nan(size(success_after{jp},1),...
                                                                            max_num_peaks(jp)-size(success_after{jp},2))];...
                                                 [nan(size(peaksij,2),num_peaksij),...
                                                 nan(size(peaksij,2),max_num_peaks(jp)-num_peaksij)]];      
                end
            else                                
                peaks_before{jp} = [peaks_before{jp};nan(num_roisi,max_num_peaks(jp))];
                peaks_during{jp} = [peaks_during{jp};nan(num_roisi,max_num_peaks(jp))];                
                dF_al2_before{jp} = [dF_al2_before{jp},...
                                            nan(max_Nt_al2(jp),...
                                                    num_roisi,max_num_peaks(jp))];
                dF_al2_during{jp} = [dF_al2_during{jp},...
                                            nan(max_Nt_al2(jp),...
                                            num_roisi,max_num_peaks(jp))];
                peaks_after{jp} = [peaks_after{jp};nan(num_roisi,max_num_peaks(jp))];
                dF_al2_after{jp} = [dF_al2_after{jp},...
                                        nan(max_Nt_al2(jp),...
                                        num_roisi,max_num_peaks(jp))];
                success_before{jp} = [success_before{jp};nan(num_roisi,max_num_peaks(jp))];
                success_during{jp} = [success_during{jp};nan(num_roisi,max_num_peaks(jp))];
                success_after{jp} = [success_after{jp};nan(num_roisi,max_num_peaks(jp))];
                fprintf('Only %g trials at %g mA in dish %g, exclude\n',...
                        num_trials,subthresh_lvls{i}(jd),i)
            end
        else
            % fill with nans for these ROIs at this intensity to maintain
            % correct indices 
            [included_ampsi,~,~] = intersect(subthresh_lvls{i},plot_vars,'stable');                
            if isempty(included_ampsi)
                fprintf('No recordings at included amps in dish %g, excluding completely\n',i)
                num_rois(i) = nan; 
            else
                peaks_before{jp} = [peaks_before{jp};nan(num_roisi,max_num_peaks(jp))];
                peaks_during{jp} = [peaks_during{jp};nan(num_roisi,max_num_peaks(jp))];
                
                dF_al2_before{jp} = [dF_al2_before{jp},...
                                            nan(max_Nt_al2(jp),...
                                                    num_roisi,max_num_peaks(jp))];
                dF_al2_during{jp} = [dF_al2_during{jp},...
                                            nan(max_Nt_al2(jp),...
                                                    num_roisi,max_num_peaks(jp))];
                success_before{jp} = [success_before{jp};nan(num_roisi,max_num_peaks(jp))];
                success_during{jp} = [success_during{jp};nan(num_roisi,max_num_peaks(jp))];
                if include_after
                    peaks_after{jp} = [peaks_after{jp};nan(num_roisi,max_num_peaks(jp))];
                    dF_al2_after{jp} = [dF_al2_after{jp},...
                                            nan(max_Nt_al2(jp),...
                                                    num_roisi,max_num_peaks(jp))]; 
                    success_after{jp} = [success_after{jp};nan(num_roisi,max_num_peaks(jp))];
                end                
                fprintf('No recordings for dish %g, %s = %g, padding with nans\n',i,in.plot_var,plot_vars(jp))
            end
        end
    end
end
roi_in_dish_index = []; % numbering of ROIs after removing ROIs not passing QC
roi_in_dish_index_id = []; % original index of ROIs within their respective dish
for i = 1:num_dishes
    if ~isnan(num_rois(i))
        roi_in_dish_index = [roi_in_dish_index;(1:(sum(dish_inds{1}==i)))'];
        num_rois0 = sum(dish_inds{1}==i)+ sum(exclude_rois{i});% original number of ROIs
        roi_ids0 = 1:num_rois0;     
        roi_in_dish_index_id = [roi_in_dish_index_id;roi_ids0(~exclude_rois{i})'];
    end
end 
fprintf('Extracted peaks and stim-aligned traces in %g dishes, %g ROIs total\n',num_dishes,sum(num_rois))

%% Output data
out.peaks_before = peaks_before;
out.peaks_during = peaks_during;
out.dish_inds = dish_inds;
out.dF_al2_before = dF_al2_before;
out.dF_al2_during = dF_al2_during;
out.dF_al2_after = dF_al2_after;
out.num_rois = num_rois; 
out.roi_in_dish_index_id = roi_in_dish_index_id;
out.roi_in_dish_index = roi_in_dish_index;
% [num_rois x num_stim x num_amps]
out.peaks_before_mat = cell2mat(reshape(peaks_before,1,1,length(peaks_before)));
out.peaks_during_mat = cell2mat(reshape(peaks_during,1,1,length(peaks_during)));
out.mean_peaks_before = squeeze(mean(out.peaks_before_mat,2,'omitnan'));
out.mean_peaks_during = squeeze(mean(out.peaks_during_mat,2,'omitnan'));
out.peak_mod_during = out.mean_peaks_during./out.mean_peaks_before; 
out.peak_mod_during_per = 100*(out.peak_mod_during - 1); % percent change
out.peak_mod_during_diff = out.mean_peaks_during - out.mean_peaks_before; % difference


% average within cell
mean_peaks_before_cell = zeros(num_dishes,length(plot_vars));
mean_peaks_during_cell = zeros(num_dishes,length(plot_vars));
for i = 1:num_dishes
    mean_peaks_before_cell(i,:) = squeeze(mean(out.peaks_before_mat(dish_inds{1}==i,:,:),[1 2],'omitnan'));
    mean_peaks_during_cell(i,:) = squeeze(mean(out.peaks_during_mat(dish_inds{1}==i,:,:),[1 2],'omitnan'));       
end
out.mean_peaks_before_cell = mean_peaks_before_cell;
out.mean_peaks_during_cell = mean_peaks_during_cell;
out.peak_mod_during_cell = out.mean_peaks_during_cell./out.mean_peaks_before_cell; 
out.peak_mod_during_cell_diff = out.mean_peaks_during_cell - out.mean_peaks_before_cell; 
out.peak_mod_during_cell_per = 100*(out.peak_mod_during_cell - 1); % percent change

out.success_before = success_before;
out.success_during = success_during;
out.success_before_mat = cell2mat(reshape(success_before,1,1,length(peaks_before)));
out.success_during_mat = cell2mat(reshape(success_during,1,1,length(peaks_during)));

out.exclude_rois = exclude_rois; 
if include_after
    out.peaks_after = peaks_after;
    out.peaks_after_mat = cell2mat(reshape(peaks_after,1,1,length(peaks_after)));
    out.mean_peaks_after = squeeze(mean(out.peaks_after_mat,2,'omitnan'));
    out.peak_mod_after = out.mean_peaks_after./out.mean_peaks_before; 
    out.peak_mod_after_per = 100*(out.peak_mod_after - 1); % percent change
    out.peak_mod_after_diff = out.mean_peaks_after - out.mean_peaks_before; % difference    
    out.success_after = success_after;
    out.success_after_mat = cell2mat(reshape(success_after,1,1,length(peaks_after)));
    mean_peaks_after_cell = zeros(num_dishes,length(plot_vars));
    for i = 1:num_dishes
        mean_peaks_after_cell(i,:) = squeeze(mean(out.peaks_after_mat(dish_inds{1}==i,:,:),[1 2],'omitnan'));    
    end
    out.mean_peaks_after_cell = mean_peaks_after_cell;
    out.peak_mod_after_cell = out.mean_peaks_after_cell./out.mean_peaks_after_cell; 
    out.peak_mod_after_cell_diff = out.mean_peaks_after_cell - out.mean_peaks_after_cell; 
    out.peak_mod_after_cell_per = 100*(out.peak_mod_after_cell - 1); % percent change
else
    out.peaks_after = []; 
    out.peaks_after_mat = []; 
    out.success_after = []; 
    out.success_after_mat = []; 
    out.mean_peaks_after_cell = []; 
end
end
