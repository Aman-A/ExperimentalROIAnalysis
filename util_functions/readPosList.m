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
if isfield(poslist_data,'map')
    StagePositions = poslist_data.map.StagePositions.array; % struct
    mode = 1;
else
    StagePositions = poslist_data.POSITIONS; % struct    
    mode = 2; 
end
num_pos = length(StagePositions);
x = zeros(num_pos,1); y = zeros(num_pos,1); z = zeros(num_pos,1);
labels = cell(num_pos,1);
switch mode
    case 1 % Thor uManager
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
        z(i) = StagePositions(i).DevicePositions.array(ZStage_ind).Position_um.array(1);
        labels{i} = StagePositions(i).Label.scalar; 
    end
    case 2 % Odin uManager
        for i = 1:num_pos
            % get index of XYstage and Zstage
            devices = StagePositions(1).DEVICES;
            device_names = cell(length(devices),1);
            for j = 1:length(devices)
                device_names{j} = devices(j).DEVICE;
            end
            XYStage_ind = strcmp(device_names,'XYStage');
            ZStage_ind = strcmp(device_names,'ZStage');
            x(i) = StagePositions(i).DEVICES(XYStage_ind).X;
            y(i) = StagePositions(i).DEVICES(XYStage_ind).Y;
            z(i) = StagePositions(i).DEVICES(ZStage_ind).X;
            labels{i} = StagePositions(i).LABEL;
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