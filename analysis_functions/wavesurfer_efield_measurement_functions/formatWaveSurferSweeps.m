function [data,t,timestamps] = formatWaveSurferSweeps(s)
    f = fieldnames(s);
    f = f(~strcmp(f,'header'));
    data = cell(1,length(f));
    timestamps = zeros(length(f),1);
    for i = 1:length(f)
        data{i} = s.(f{i}).analogScans;
        timestamps(i) = s.(f{i}).timestamp;
    end
    if ~isequal(size(data{end}),size(data{1}))
        fprintf('Last sweep ended early, removing...\n')
        data(end) = []; 
    end
    % if multi-trial and multichannel: ntime points x nchan x nsweeps
    % otherwise: ntime points x nchan or ntime points x nsweeps
    data = squeeze(cell2mat(reshape(data,1,1,length(data))));  
    fs = s.header.AcquisitionSampleRate;
    dt = 1/fs; 
    t = 0:dt:(size(data,1)-1)*dt;

end