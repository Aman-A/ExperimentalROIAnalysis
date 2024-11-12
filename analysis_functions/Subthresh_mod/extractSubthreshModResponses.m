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
in.print_level = 1;
in = sl.in.processVarargin(in,varargin);
num_vars = length(plot_vars);
num_dishes = length(data); 
% independent variable, e.g., amplitude or duration 
subthresh_lvls = cellfun(@(x) str2num(x),def.(in.plot_var),'UniformOutput',0); %#ok<*ST2NM> 

% Extract amps to analyze
peaks = cell(3,num_vars); % [before;during;after]
dF_al2 = cell(3,num_vars);
success = cell(3,num_vars);
% bslines = cell(3,num_vars);
% F = cell(1,num_vars); % full recordingt
dish_inds = cell(1,num_vars);
num_rois = nan(1,num_dishes);
max_num_peaks = zeros(1,num_vars); % max number of peaks across all dishes
max_num_trials = zeros(1,num_vars);
max_Nt_al2 = zeros(1,num_vars); % max number of time points for deltaF_F0_aligned2 across all dishes
include_after = zeros(1,num_dishes);
plot_data_inds = cell(1,num_dishes);
for i = 1:num_dishes    
    if data{i}.exp_settings(1).num_trains == 3 % size(data{i}.peaks_deltaF_F0_all{1},1)
        include_after(i) = 1;        
    else
        include_after(i) = 0;        
    end 
    for j = 1:num_vars
        if any(subthresh_lvls{i} == plot_vars(j))    
            data_inds = find(subthresh_lvls{i}==plot_vars(j));
            dup_plot_vars = find(plot_vars==plot_vars(j)); % 
            data_ind = data_inds(dup_plot_vars==j);
            plot_data_inds{i} = [plot_data_inds{i};data_ind];
            max_num_peaks(j) = max(max_num_peaks(j),...
                prod(size(data{i}.peaks_deltaF_F0_all{data_ind},[3 4]))); % subthresh_lvls{i}==plot_vars(j)            
            max_Nt_al2(j) = max(max_Nt_al2(j),size(data{i}.deltaF_F0_aligned2_all{data_ind},1));
            max_num_trials(j) = max(max_num_trials(j),max(cellfun(@length,data{1}.img_names,'UniformOutput',1)));                    
        else
            plot_data_inds{i} = [plot_data_inds{i};nan];
        end
    end
end
% max_num_peaks = repmat(max(max_num_peaks),1,num_vars);
max_num_peaks = max(max_num_peaks); % use same number of peaks for all conditions
max_Nt_al2 = max(max_Nt_al2); 
if isempty(in.exclude_rois)
    exclude_rois = cell(1,num_dishes);
else
    exclude_rois = in.exclude_rois;
end
data_out = cell(size(data));
for i = 1:num_dishes
    % Apply quality control to ROIs
    if strcmp(in.qc_settings,'off')
        if length(in.exclude_rois) == num_dishes
            datai = removeROIsExpData(data{i},in.exclude_rois{i},...
                                        'print_level',in.print_level);
        else
            datai = data{i}; 
        end
    else
        if in.print_level > 0
            fprintf('***dish %g***\n',i);
        end
        [datai,exclude_rois{i}] = qualityControlROIs(data{i},in.qc_settings,...
                                                     plot_data_inds{i},...
                                                     'exclude_rois',exclude_rois{i},...
                                                     'print_level',in.print_level);
    end
    data_out{i} = datai; 
    peaksi = datai.peaks_deltaF_F0_all;
    dF_al2i = datai.deltaF_F0_aligned2_all;     
    % meansi = datai.means_all; 
    % baselines_alli = datai.baselines_all; 
    num_roisi = datai.rois_all{1}{1}.num_rois;    
    if num_roisi < in.min_rois_included
        fprintf('Skipping dish %g, only %g ROIs (< %g)\n',i,num_roisi,in.min_rois_included);
        continue; % skip this dish
    end
    num_rois(i) = num_roisi;    
    for jp = 1:num_vars  % index within output dataset for plotting/analysis      
        dish_inds{jp} = [dish_inds{jp};i*ones(num_roisi,1)];
        if any(plot_vars(jp) == subthresh_lvls{i})  
            jd = plot_data_inds{i}(jp);
            peaksij = peaksi{jd}; % 3 x num_rois x 20 x num_trials
            dF_al2ij = dF_al2i{jd}; 
            % meansij = meansi{jd};
            % bslinesij = baselines_alli{jd};
            num_trials  = size(peaksij,4);                   
            num_peaksij = prod(size(peaksij,[3 4]));
            % dish_inds{jp} = [dish_inds{jp};i*ones(num_roisi,1)];
            if num_trials >= min_num_trials_per_lvl                            
                % add peaks from this experiment, fill with nans if fewer than
                % max number of trials 
                % for spike detection
                exp_settingsij = datai.exp_settings(jd);
                detectSpikesArgs = {exp_settingsij,spike_thresh,...
                                    'spike_window',in.spike_window,...
                                    'min_width',in.spike_min_width,...
                                    'min_amp',in.spike_min_amp};                
                for k = 1:(2 + include_after(i))% loop over before, during, after stim period
                    % peaks extracted from raw traces
                    peaks{k,jp} = [[peaks{k,jp},nan(size(peaks{1,jp},1),...
                                        max_num_peaks-size(peaks{1,jp},2))];...
                                     [squeeze(peaksij(k,:,:)),...
                                        nan(size(peaksij,2),max_num_peaks-num_peaksij)]];
                    % bslines{k,jp} = [[bslines{k,jp},nan(size(bslines{k,jp},1),...
                                          % max_num_peaks-size(bslines_before{jp},2))];...
                                       % [squeeze(bslinesij(k,:,:)),...
                %                          nan(size(bslinesij,2),max_num_peaks-num_peaksij)]];
                    
                    % get deltaF_F0_aligned2 (individual stim-aligned traces within
                    % ROI), assumes baseline_wind and stim_wind same for all
                    % experiments (Todo: make compatible with different windows)          
                    % First pad experiments with fewer trials with nans
                    if ~isempty(dF_al2{k,jp}) && max_num_peaks > size(dF_al2{k,jp},3) 
                        dF_al2{k,jp} = cat(3,dF_al2{k,jp},...
                                                nan([size(dF_al2{k,jp},[1 2]),...
                                                    max_num_peaks-size(dF_al2{k,jp},3)]));
                    end
                    % Extract traces 
                    dF_al2ijk = reshape(dF_al2ij(:,:,k,:),...
                                    [size(dF_al2ij,[1,2]),num_peaksij]);
                    dF_al2{k,jp} = [dF_al2{k,jp},...
                                     cat(3,dF_al2ijk,nan([size(dF_al2ijk,[1,2]),...
                                                        max_num_peaks-size(dF_al2ijk,3)]))];
                    % peak success/failure
                    success_ijk = detectSpikesAlignedTraces(dF_al2ijk,...
                                                             detectSpikesArgs{:}); %
                    success{k,jp} = [[success{k,jp},nan(size(success{k,jp},1),...
                                            max_num_peaks-size(success{k,jp},2))];...
                                         [success_ijk,...
                                            nan(size(success_ijk,1),max_num_peaks-num_peaksij)]];
                end   
                if ~include_after(i)
                    % pad peaks
                    peaks{3,jp} = [[peaks{3,jp},nan(size(peaks{3,jp},1),...
                                                max_num_peaks-size(peaks{3,jp},2))];...
                                     [nan(size(peaksij,2),num_peaksij),...
                                                nan(size(peaksij,2),max_num_peaks-num_peaksij)]];                        
                    % pad aligned dF traces
                    dF_al2ijk = nan([size(dF_al2ij,[1,2]),num_peaksij]);   
                    dF_al2{3,jp} = [dF_al2{3,jp},...
                                                cat(3,dF_al2ijk,...
                                                    nan([size(dF_al2ijk,...
                                                    [1,2]),max_num_peaks-size(dF_al2ijk,3)]))];                
                    % pad peak success/failure
                    success{3,jp} = [[success{3,jp},nan(size(success{3,jp},1),...
                                                       max_num_peaks-size(success{3,jp},2))];...
                                        [nan(size(peaksij,2),num_peaksij),...
                                                 nan(size(peaksij,2),max_num_peaks-num_peaksij)]];      
                end                  
                % raw F traces
                % F{jp} = [F{jp},cat(3,meansij,nan([size(meansij,[1 2]),max_num_trials(jp)-num_trials]))];
                % dish_inds{peak_indj} = [dish_inds{peak_indj};i*ones(num_roisi,1)];                                
            else                
                for k = 1:3 % pad after
                    peaks{k,jp} = [peaks{k,jp};nan(num_roisi,max_num_peaks)];
                    dF_al2{k,jp} = [dF_al2{k,jp},nan(max_Nt_al2,...
                                    num_roisi,max_num_peaks)];
                    % bslines{k,jp} = [bslines{k,jp};nan(num_roisi,max_num_peaks)];
                    success{k,jp} = [success{k,jp};nan(num_roisi,max_num_peaks)];
                end
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
                for k = 1:(2 + any(include_after))% loop over before, during, after stim period
                    peaks{k,jp} = [peaks{k,jp};nan(num_roisi,max_num_peaks)];                
                    % bslines{k,jp} = [bslines{k,jp};nan(num_roisi,max_num_peaks)];                
                    dF_al2{k,jp} = [dF_al2{k,jp},nan(max_Nt_al2,num_roisi,...
                                                    max_num_peaks)];
                    success{k,jp} = [success{k,jp};nan(num_roisi,max_num_peaks)];                    
                end
                fprintf('No recordings for dish %g, %s = %g, padding with nans\n',i,in.plot_var,plot_vars(jp))
            end
        end
    end
end
assert(isequal(dish_inds{:}),'Number of ROIs differs between intensities')
dish_inds = dish_inds{1}; 
roi_in_dish_index = []; % numbering of ROIs after removing ROIs not passing QC
roi_in_dish_index_id = []; % original index of ROIs within their respective dish
for i = 1:num_dishes
    if ~isnan(num_rois(i))
        roi_in_dish_index = [roi_in_dish_index;(1:(sum(dish_inds==i)))'];
        num_rois0 = sum(dish_inds==i)+ sum(exclude_rois{i});% original number of ROIs
        roi_ids0 = 1:num_rois0;     
        roi_in_dish_index_id = [roi_in_dish_index_id;roi_ids0(~exclude_rois{i})'];
    end
end 
fprintf('Extracted peaks and stim-aligned traces in %g dishes, %g ROIs total\n',num_dishes,sum(num_rois,'omitnan'))
%% Output data
out = struct(); 
out.dish_inds = dish_inds;
out.num_rois = num_rois; 
out.roi_in_dish_index_id = roi_in_dish_index_id;
out.roi_in_dish_index = roi_in_dish_index;
out.exclude_rois = exclude_rois; 
% generate before, during, and after fields
all_data = {peaks,dF_al2,success};
prefixes = {'peaks','dF_al2','success'};
suffixes = {'before','during','after'};
for i = 1:length(all_data)
    datai = all_data{i}; 
    prefixi = prefixes{i}; 
    for k = 1:(2 + any(include_after))    
        field_dk = [prefixi '_' suffixes{k}];
        out.(field_dk) = datai(k,:);        
    end
end
% Make data matrices
% [num_rois x num_stim x num_amps]
% mat_prefixes = {'peaks','bslines'};
% mat_data = {peaks,bslines}; 
mat_data = {peaks,success}; 
mat_prefixes = {'peaks','success'};
for i = 1:length(mat_prefixes)
    datai = mat_data{i};
    prefixi = mat_prefixes{i}; 
    for k = 1:(2 + any(include_after))    
        mat_fieldname = [prefixi '_' suffixes{k} '_mat'];
        mean_mat_fieldname = ['mean_' prefixi '_' suffixes{k}];
        out.(mat_fieldname) = cell2mat(reshape(datai(k,:),1,1,num_vars));
        out.(mean_mat_fieldname) = squeeze(mean(out.(mat_fieldname),2,'omitnan')); % average within epoch
        if k >= 2            
            % ratio (during/before)
            out.([mat_prefixes{i} '_mod_' suffixes{k}]) = ...
                out.(mean_mat_fieldname)./out.(['mean_' prefixi '_before']);
            % difference (during - before)
            out.([mat_prefixes{i} '_mod_' suffixes{k} '_diff']) = ...
                out.(mean_mat_fieldname) - out.(['mean_' prefixi '_before']);
            % percent change 100*(during-before)/before
            out.([mat_prefixes{i} '_mod_' suffixes{k} '_per']) = ...
                100*out.([mat_prefixes{i} '_mod_' suffixes{k} '_diff'])./out.(['mean_' prefixi '_before']);
        end
    end
end
%% average raw peaks and deltaF traces within train separately
num_rois_all = sum(num_rois);
num_stim = data{1}.exp_settings(1).num_stim;
stim_ind = data{1}.exp_settings(1).baseline_wind + 1;
spike_wind_end = stim_ind + data{1}.exp_settings(1).convert2Frames(in.spike_window);
for k = 1:(2 + any(include_after)) 
    % num_rois x num_stim (20) x num_trials x num_vars, retains ordering
    peaks_mat_tr_k = reshape(out.(['peaks_' suffixes{k} '_mat']),num_rois_all,...
                              num_stim,max_num_peaks/num_stim,num_vars);
    out.(['mean_peaks_' suffixes{k} '_mat_tr']) = squeeze(mean(peaks_mat_tr_k,3,'omitnan')); % average across trials
    % normalize to mean before (within ROI)
    out.(['mean_peaks_' suffixes{k} '_mat_tr_norm']) = ...
        out.(['mean_peaks_' suffixes{k} '_mat_tr'])./mean(out.mean_peaks_before_mat_tr,2,'omitnan');
    
    % Get mean deltaF traces across trials
    % num_timepoints x num_rois x (num_stim*num_trials) x num_vars
    dF_al2_mat_k = cell2mat(reshape(dF_al2(k,:),1,1,1,num_vars)); 
    % num_timepoints x num_rois x num_stim x num_trials x num_vars
    dF_al2_tr_k = reshape(dF_al2_mat_k,max_Nt_al2,num_rois_all,num_stim,max_num_peaks/num_stim,num_vars);
    % mean across trials (num_timepoints x num_rois x num_stim x num_vars)
    out.(['mean_dF_al2_' suffixes{k} '_tr']) = squeeze(mean(dF_al2_tr_k,4,'omitnan'));
    % peak at each stim within train extracted from trial-averaged trace
    % (instead of raw trace)
    out.(['mean_peaks_' suffixes{k} '_tr_dF']) = ...
        squeeze(max(out.(['mean_dF_al2_' suffixes{k} '_tr'])(stim_ind:spike_wind_end,:,:,:),[],1));
    % normalize to mean of trial-averaged peaks in before DC train (within ROI)

    out.(['mean_peaks_' suffixes{k} '_tr_dF_norm']) = ...        
        out.(['mean_peaks_' suffixes{k} '_tr_dF'])./mean(out.mean_peaks_before_tr_dF,2,'omitnan');
        
    % mean across trials and train (num_timepoints x num_rois x num_vars)
    out.(['mean_dF_al2_' suffixes{k}]) = squeeze(mean(dF_al2_tr_k,[3 4],'omitnan'));
    % mean peaks within ROI extracted from dF trace averaged across trial 
    % and within train
    out.(['mean_peaks_' suffixes{k} '_dF']) = ...
        squeeze(max(out.(['mean_dF_al2_' suffixes{k}])(stim_ind:spike_wind_end,:,:,:),[],1));
    
    % alternative: normalize using peak of mean before DC trace, rather than mean of
    % trial-averaged peaksin before train
    % out.(['mean_peaks_' suffixes{k} '_tr_dF_norm']) = ...        
    %     out.(['mean_peaks_' suffixes{k} '_tr_dF'])./permute(max(out.mean_dF_al2_before(stim_ind:spike_wind_end,:,:),[],1),[2 1 3]);


    if k >= 2
        % ratio (during/before)
        out.(['peaks_mod_' suffixes{k} '_dF']) = ...
            out.(['mean_peaks_' suffixes{k} '_dF'])./out.mean_peaks_before_dF;
        % difference (during - before)
        out.(['peaks_mod_' suffixes{k} '_dF_diff']) = ...
            out.(['mean_peaks_' suffixes{k} '_dF']) - out.mean_peaks_before_dF;
        % percent change 100*(during-before)/before
        out.(['peaks_mod_' suffixes{k} '_dF_per']) = ...
            100*out.(['peaks_mod_' suffixes{k} '_dF_diff'])./out.mean_peaks_before_dF;
    end
end

%% average within cell

for k = 1:(2 + any(include_after)) 
    % peaks from raw trace
    % mean across ROIs, trials, and stim of train within cell
    out.(['mean_peaks_' suffixes{k} '_cell']) = zeros(num_dishes,num_vars);
    % mean across ROIs/trials at each stim of train within cell
    out.(['mean_peaks_' suffixes{k} '_cell_tr']) = zeros(num_dishes,num_stim,num_vars);
    % mean across ROIs/trials at each stim of train within cell after normalizing within ROI to mean before
    out.(['mean_peaks_' suffixes{k} '_cell_tr_norm']) = zeros(num_dishes,num_stim,num_vars);
    % peaks from averaged trace (_dF)
    % mean across ROIs, trials, and stim of train within cell
    out.(['mean_peaks_' suffixes{k} '_cell_dF']) = zeros(num_dishes,num_vars);
    % mean across ROIs/trials at each stim of train within cell
    out.(['mean_peaks_' suffixes{k} '_cell_tr_dF']) = zeros(num_dishes,num_stim,num_vars);
    % mean across ROIs/trials at each stim of train within cell after normalizing within ROI to mean before
    out.(['mean_peaks_' suffixes{k} '_cell_tr_norm_dF']) = zeros(num_dishes,num_stim,num_vars);
    if k >= 2
        % peaks from raw trace
        % peak modulation calculated WITHIN ROI, then averaged within cell 
        out.(['peaks_mod_' suffixes{k} '_cell_wroi']) = zeros(num_dishes,num_vars); % ratio
        out.(['peaks_mod_' suffixes{k} '_cell_wroi_diff']) = zeros(num_dishes,num_vars); % difference
        out.(['peaks_mod_' suffixes{k} '_cell_wroi_per']) = zeros(num_dishes,num_vars); % percent change
        % peaks from averaged trace (_dF)
        % peak modulation calculated WITHIN ROI, then averaged within cell 
        out.(['peaks_mod_' suffixes{k} '_cell_wroi_dF']) = zeros(num_dishes,num_vars); % ratio
        out.(['peaks_mod_' suffixes{k} '_cell_wroi_dF_diff']) = zeros(num_dishes,num_vars); % difference
        out.(['peaks_mod_' suffixes{k} '_cell_wroi_dF_per']) = zeros(num_dishes,num_vars); % percent change
    end
    for i = 1:num_dishes
        % peaks from raw trace
        out.(['mean_peaks_' suffixes{k} '_cell'])(i,:) = mean(out.(['mean_peaks_' suffixes{k}])(dish_inds==i,:),1,'omitnan');
        out.(['mean_peaks_' suffixes{k} '_cell_tr'])(i,:,:) = squeeze(mean(out.(['mean_peaks_' suffixes{k} '_mat_tr'])(dish_inds==i,:,:),1,'omitnan'));
        out.(['mean_peaks_' suffixes{k} '_cell_tr_norm'])(i,:,:) = squeeze(mean(out.(['mean_peaks_' suffixes{k} '_mat_tr_norm'])(dish_inds==i,:,:),1,'omitnan'));
        % peaks from averaged trace (_dF)
        out.(['mean_peaks_' suffixes{k} '_cell_dF'])(i,:) = mean(out.(['mean_peaks_' suffixes{k} '_dF'])(dish_inds==i,:),1,'omitnan');
        out.(['mean_peaks_' suffixes{k} '_cell_tr_dF'])(i,:,:) = squeeze(mean(out.(['mean_peaks_' suffixes{k} '_tr_dF'])(dish_inds==i,:,:),1,'omitnan'));
        out.(['mean_peaks_' suffixes{k} '_cell_tr_norm_dF'])(i,:,:) = squeeze(mean(out.(['mean_peaks_' suffixes{k} '_tr_dF_norm'])(dish_inds==i,:,:),1,'omitnan'));
        if k >= 2
            % peak mod from raw trace
            out.(['peaks_mod_' suffixes{k} '_cell_wroi'])(i,:) = mean(out.(['peaks_mod_' suffixes{k}])(dish_inds==i,:),1,'omitnan');
            out.(['peaks_mod_' suffixes{k} '_cell_wroi_diff'])(i,:) = mean(out.(['peaks_mod_' suffixes{k} '_diff'])(dish_inds==i,:),1,'omitnan');
            out.(['peaks_mod_' suffixes{k} '_cell_wroi_per'])(i,:) = mean(out.(['peaks_mod_' suffixes{k} '_per'])(dish_inds==i,:),1,'omitnan');
            % peak mod from averaged trace (_dF)
            out.(['peaks_mod_' suffixes{k} '_cell_wroi_dF'])(i,:) = mean(out.(['peaks_mod_' suffixes{k} '_dF'])(dish_inds==i,:),1,'omitnan');
            out.(['peaks_mod_' suffixes{k} '_cell_wroi_dF_diff'])(i,:) = mean(out.(['peaks_mod_' suffixes{k} '_dF_diff'])(dish_inds==i,:),1,'omitnan');
            out.(['peaks_mod_' suffixes{k} '_cell_wroi_dF_per'])(i,:) = mean(out.(['peaks_mod_' suffixes{k} '_dF_per'])(dish_inds==i,:),1,'omitnan');
        end
    end
    if k >= 2
        % peak modulation calculated on peaks averaged within cell (NOT
        % normalized within ROI) using peaks from raw traces
        out.(['peaks_mod_' suffixes{k} '_cell']) = out.(['mean_peaks_' suffixes{k} '_cell'])./out.mean_peaks_before_cell; % ratio (during/before)
        out.(['peaks_mod_' suffixes{k} '_cell_diff']) = out.(['mean_peaks_' suffixes{k} '_cell']) - out.mean_peaks_before_cell; % difference (during - before)
        out.(['peaks_mod_' suffixes{k} '_cell_per']) = 100*out.(['peaks_mod_' suffixes{k} '_cell_diff']) ./out.mean_peaks_before_cell; % percent change 100*(during-before)/before
        % peak modulation calculated on peaks averaged within cell (NOT
        % normalized within ROI) using peaks from stim/trial averaged
        % traces
        out.(['peaks_mod_' suffixes{k} '_cell_dF']) = out.(['mean_peaks_' suffixes{k} '_cell_dF'])./out.mean_peaks_before_cell_dF; % ratio (during/before)
        out.(['peaks_mod_' suffixes{k} '_cell_dF_diff']) = out.(['mean_peaks_' suffixes{k} '_cell_dF']) - out.mean_peaks_before_cell_dF; % difference (during - before)
        out.(['peaks_mod_' suffixes{k} '_cell_dF_per']) = 100*out.(['peaks_mod_' suffixes{k} '_cell_dF_diff']) ./out.mean_peaks_before_cell_dF; % percent change 100*(during-before)/before
    end
end

end