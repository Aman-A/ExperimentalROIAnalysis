function [Nrows,Ncols] = getSubplotDimensions(N,tall_switch)
%GETSUBPLOTDIMENSIONS Calculates dimensions of subplot grid for number of
% axes
%  
%   Inputs 
%   ------ 
%   N : integer
%       Number of axes
%   tall_switch : 1 or 0
%                 If 1, favor tall dimensions (Nrows > Ncols), if 0,
%                 outputs short (Nrows < Ncols)
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if nargin < 2
    tall_switch = 0;
end
floor = uint16(sqrt(N));
if floor^2 == N % square number, just make grid
    Nrows = floor; 
    Ncols = floor; 
else
    Nrows = floor; 
    Ncols = floor;
    while Nrows*Ncols < N
        Ncols = Ncols + 1; % ends as soon as dimensions accommodates number of axes
    end
    if tall_switch        
        Nrows = Ncols; 
        Ncols = floor; % make Nrows > Ncols      
    end
end
Nrows = double(Nrows);
Ncols = double(Ncols);
