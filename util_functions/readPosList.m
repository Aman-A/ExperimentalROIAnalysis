function [x,y,z,labels] = readPosList(poslist_file)
%READPOSLIST Read stage position list output by micromanager, outputs x, y,
%z coords of each position
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 

poslist_data = jsondecode(fileread(poslist_file));
StagePositions = poslist_data.map.StagePositions.array; % struct
num_pos = length(StagePositions);
x = zeros(num_pos,1); y = zeros(num_pos,1); z = zeros(num_pos,1);
labels = cell(num_pos,1);
for i = 1:num_pos
    % get index of XYstage and Zstage
    devices = [StagePositions(i).DevicePositions.array(:)];
    device_names = cell(length(devices),1);
    for j = 1:length(devices)
        device_names{j} = devices(j).Device.scalar;
    end
    XYStage_ind = strcmp(device_names,'XYStage');
    ZStage_ind = strcmp(device_names,'ZStage');
    x(i) = StagePositions(i).DevicePositions.array(XYStage_ind).Position_um.array(1);
    y(i) = StagePositions(i).DevicePositions.array(XYStage_ind).Position_um.array(2);
    if ZStage_ind > 0
        z(i) = StagePositions(i).DevicePositions.array(ZStage_ind).Position_um.array(1);
    end
    labels{i} = StagePositions(i).Label.scalar; 
end
end