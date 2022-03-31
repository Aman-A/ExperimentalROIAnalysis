function traces_mat = trialsCell2Mat(traces_cell_array)
%TRIALSCELL2MAT combines traces in cell array into single 2 or 3D
%matrix
num_rows = cellfun(@(x) size(x,1),traces_cell_array);
num_cols = cellfun(@(x) size(x,2),traces_cell_array); 
num_trials = length(traces_cell_array);
if all(num_rows == num_rows(1)) % all same number of frames    
    if all(num_cols == 1) % all single ROI
        traces_mat = cell2mat(traces_cell_array); % [nrows x ncols] 2D matrix
    elseif all(num_cols == num_cols(1))% all same number of ROIs       
        % [num_frames x num_stim x num_trials] 3D matrix
        % or [num_frames x num_rois x num_stim x num_trials] 4D matrix
        traces_mat = cell2mat(reshape(traces_cell_array,1,1,1,num_trials)); 
    else
        error('Number of columns (ROIs) not consistent between trials'); 
    end
else % different number of frames, pad with nans
    max_rows = max(num_rows); 
    if all(num_cols == 1) % all single ROI
        traces_mat = nan(max_rows,num_trials); 
        for i = 1:num_trials
           traces_mat(1:num_rows(i),i) = traces_cell_array{i}; 
        end
    elseif all(num_cols == num_cols(1))
        traces_mat = nan(max_rows,num_cols,num_trials); 
        for i = 1:num_trials
           traces_mat(1:num_rows(i),:,i) = traces_cell_array{i}; 
        end
    else
        error('Number of columns (ROIs) not consistent between trials'); 
    end
end
end