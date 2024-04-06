function [data,t,timestamps] = formatWaveSurferSweeps(s)
    f = fieldnames(s);
    f = f(~strcmp(f,'header'));
    data = cell(1,length(f));
    timestamps = zeros(length(f),1);
    for i = 1:length(f)
        data{i} = s.(f{i}).analogScans;
        timestamps(i) = s.(f{i}).timestamp;
    end
    data = cell2mat(data); 
    fs = s.header.AcquisitionSampleRate;
    dt = 1/fs; 
    t = 0:dt:(size(data,1)-1)*dt;

end