function pixel_size = pixelSize(scope,obj_mag)
%PIXELSIZE(scope,obj_mag) Outputs pixel size in microns
%  Specify scope as either 'thor', 'odin', or 'loki'
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if nargin < 1
    scope = 'thor';
end
if nargin < 2
    obj_mag = 40; % 40x objective
end
if strcmp(scope,'thor') || strcmp(scope,'odin')
    pixel_size = 16/obj_mag;
elseif strcmp(scope,'loki')
    pixel_size = 6.5/obj_mag; 
end
end