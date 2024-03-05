function [Z,var_Z] = calcPerErrWithVariance(X,Y,var_X,var_Y)
%CALCPERERRWITHVARIANCE Calculate percent error and variance using error
%propagation
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
% for Z = 100*(X - Y)/Y = 100*(X/Y - 1) = 100*X/Y - 100
% with variance (e.g. std) var_X, var_Y, 
% var_Z = 100 * (X/Y) * sqrt((var_X/X)^2 + (var_Y/Y)^2)

% AUTHOR    : Aman Aberra 

Z = 100*(X - Y)./Y; 
var_Z = 100*(X./Y).*sqrt((var_X./X).^2 + (var_Y./Y).^2);
% Z = X./Y;
% var_Z = (X./Y).*sqrt((var_X./X).^2 + (var_Y./Y).^2);
end