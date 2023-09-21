function out = extractSubthreshModResponses(data,def,plot_amps,min_num_trials_per_amp)
if nargin < 4
    min_num_trials_per_amp = 0; 
end

num_amps = length(plot_amps);
num_dishes = length(data); 
subthresh_amps = cellfun(@(x) str2num(x),def.subthresh_amps,'UniformOutput',0); %#ok<*ST2NM> 

% Extract amps to analyze
peaks_before = cell(1,num_amps);
peaks_during = cell(1,num_amps);
peaks_after = cell(1,num_amps);
dish_inds = cell(1,num_amps);
dF_al2_before = cell(1,num_amps);
dF_al2_during = cell(1,num_amps);
dF_al2_after = cell(1,num_amps);
num_rois = zeros(1,num_dishes);
max_num_peaks = zeros(1,length(plot_amps)); % max number of peaks across all dishes
max_Nt_al2 = zeros(1,length(plot_amps)); % max number of time points for deltaF_F0_aligned2 across all dishes
for i = 1:num_dishes    
    for j = 1:length(plot_amps)
        if any(subthresh_amps{i} == plot_amps(j))
            max_num_peaks(j) = max(max_num_peaks(j),...
                prod(size(data{i}.peaks_deltaF_F0_all{subthresh_amps{i}==plot_amps(j)},[3 4])));
            max_Nt_al2(j) = max(max_Nt_al2(j),size(data{i}.deltaF_F0_aligned2_all{subthresh_amps{i}==plot_amps(j)},1));
        end
    end
end
if size(data{i}.peaks_deltaF_F0_all{1},1) == 3
    include_after = 1; 
else
    include_after = 0; 
end
for i = 1:num_dishes
    peaksi = data{i}.peaks_deltaF_F0_all;
    dF_al2i = data{i}.deltaF_F0_aligned2_all; 
    [included_ampsi,amp_indsi,plot_amp_indsi] = intersect(subthresh_amps{i},plot_amps,'stable');            
    num_roisi = data{i}.rois_all{1}{1}.num_rois;
    num_rois(i) = num_roisi;
    for jp = 1:length(plot_amps)  %length(amp_indsi)          
        if any(plot_amps(jp) == subthresh_amps{i})
            j = find(included_ampsi == plot_amps(jp));        
            peaksij = peaksi{amp_indsi(j)}; % 3 x num_rois x 20 x num_trials
            dF_al2ij = dF_al2i{amp_indsi(j)}; 
            num_trials  = size(peaksij,4);       
            peak_indj = plot_amp_indsi(j); % index in final peaks array                 
            num_peaksij = prod(size(peaksij,[3 4]));
            dish_inds{peak_indj} = [dish_inds{peak_indj};i*ones(num_roisi,1)];
%             max_num_peaks = max(num_peaksij,size(peaks_before{peak_indj},2));
            if num_trials >= min_num_trials_per_amp                            
                % add peaks from this experiment, fill with nans if fewer than
                % max number of trials
                peaks_before{peak_indj} = [[peaks_before{peak_indj},nan(size(peaks_before{peak_indj},1),...
                                                                        max_num_peaks(jp)-size(peaks_before{peak_indj},2))];...
                                             [squeeze(peaksij(1,:,:)),...
                                             nan(size(peaksij,2),max_num_peaks(jp)-num_peaksij)]];
                peaks_during{peak_indj} = [[peaks_during{peak_indj},nan(size(peaks_during{peak_indj},1),...
                                                                        max_num_peaks(jp)-size(peaks_during{peak_indj},2))];...
                                             [squeeze(peaksij(2,:,:)),...
                                             nan(size(peaksij,2),max_num_peaks(jp)-num_peaksij)]];
                if include_after
                    peaks_after{peak_indj} = [[peaks_after{peak_indj},nan(size(peaks_after{peak_indj},1),...
                                                                            max_num_peaks(jp)-size(peaks_after{peak_indj},2))];...
                                                 [squeeze(peaksij(3,:,:)),...
                                                 nan(size(peaksij,2),max_num_peaks(jp)-num_peaksij)]];      
                end
                % get deltaF_F0_aligned2 (individual stim-aligned traces within
                % ROI), assumes baseline_wind and stim_wind same for all
                % experiments (Todo: make compatible with different windows)            
                if ~isempty(dF_al2_before{peak_indj}) && max_num_peaks(jp) > size(dF_al2_before{peak_indj},3) % pad experiments with fewer trials with nans
                    dF_al2_before{peak_indj} = cat(3,dF_al2_before{peak_indj},...
                        nan([size(dF_al2_before{peak_indj},[1 2]),max_num_peaks(jp)-size(dF_al2_before{peak_indj},3)]));
                    dF_al2_during{peak_indj} = cat(3,dF_al2_during{peak_indj},...
                        nan([size(dF_al2_during{peak_indj},[1 2]),max_num_peaks(jp)-size(dF_al2_during{peak_indj},3)]));
                    if include_after
                        dF_al2_after{peak_indj} = cat(3,dF_al2_after{peak_indj},...
                            nan([size(dF_al2_after{peak_indj},[1 2]),max_num_peaks(jp)-size(dF_al2_after{peak_indj},3)]));
                    end
                end
                dF_al2_beforeij = reshape(dF_al2ij(:,:,1,:),...
                                    [size(dF_al2ij,[1,2]),num_peaksij]);
                dF_al2_before{peak_indj} = [dF_al2_before{peak_indj},...
                                            cat(3,dF_al2_beforeij,...
                                                nan([size(dF_al2_beforeij,...
                                                    [1,2]),max_num_peaks(jp)-size(dF_al2_beforeij,3)]))];
                dF_al2_duringij = reshape(dF_al2ij(:,:,2,:),...
                                    [size(dF_al2ij,[1,2]),num_peaksij]);            
                dF_al2_during{peak_indj} = [dF_al2_during{peak_indj},...
                                            cat(3,dF_al2_duringij,...
                                                nan([size(dF_al2_duringij,...
                                                [1,2]),max_num_peaks(jp)-size(dF_al2_duringij,3)]))];
                if include_after
                    dF_al2_afterij = reshape(dF_al2ij(:,:,3,:),...
                                        [size(dF_al2ij,[1,2]),num_peaksij]);            
                    dF_al2_after{peak_indj} = [dF_al2_after{peak_indj},...
                                                cat(3,dF_al2_afterij,...
                                                    nan([size(dF_al2_afterij,...
                                                    [1,2]),max_num_peaks(jp)-size(dF_al2_afterij,3)]))];                
                end
                % dish_inds{peak_indj} = [dish_inds{peak_indj};i*ones(num_roisi,1)];
                
            else                                
                peaks_before{peak_indj} = [peaks_before{jp};nan(num_roisi,max_num_peaks(jp))];
                peaks_during{peak_indj} = [peaks_during{jp};nan(num_roisi,max_num_peaks(jp))];                
                dF_al2_before{peak_indj} = [dF_al2_before{peak_indj},...
                                            nan(max_Nt_al2(jp),...
                                                    num_roisi,max_num_peaks(jp))];
                dF_al2_during{peak_indj} = [dF_al2_during{peak_indj},...
                                            nan(max_Nt_al2(jp),...
                                                    num_roisi,max_num_peaks(jp))];
                if include_after
                    peaks_after{peak_indj} = [peaks_after{jp};nan(num_roisi,max_num_peaks(jp))];
                    dF_al2_after{peak_indj} = [dF_al2_after{peak_indj},...
                                            nan(max_Nt_al2(jp),...
                                                    num_roisi,max_num_peaks(jp))];                
                end
                fprintf('Only %g trials at %g mA in dish %g, exclude\n',...
                        num_trials,subthresh_amps{i}(amp_indsi(j)),i)
            end
        else
            % fill with nans for these ROIs at this intensity to maintain
            % correct indices 
            if isempty(included_ampsi)
                fprintf('No recordings at included amps in dish %g, excluding\n',i)
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
                if include_after
                    peaks_after{jp} = [peaks_after{jp};nan(num_roisi,max_num_peaks(jp))];
                    dF_al2_after{jp} = [dF_al2_after{jp},...
                                            nan(max_Nt_al2(jp),...
                                                    num_roisi,max_num_peaks(jp))]; 
                end                
                fprintf('No recordings for dish %g, amp = %g, padding with nans\n',i,plot_amps(jp))
            end
        end
    end
end
roi_in_dish_index = [];
for i = 1:num_dishes
    roi_in_dish_index = [roi_in_dish_index;(1:(sum(dish_inds{1}==i)))'];
end 
out.peaks_before = peaks_before;
out.peaks_during = peaks_during;
out.peaks_after = peaks_after;
out.dish_inds = dish_inds;
out.dF_al2_before = dF_al2_before;
out.dF_al2_during = dF_al2_during;
out.dF_al2_after = dF_al2_after;
out.num_rois = num_rois; 
out.roi_in_dish_index = roi_in_dish_index;
fprintf('Extracted peaks and stim-aligned traces in %g dishes, %g ROIs total\n',num_dishes,sum(num_rois))
end