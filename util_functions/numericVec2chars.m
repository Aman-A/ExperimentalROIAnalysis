function char_cell_array = numericVec2chars(vec,str_pattern)
%NUMERICVEC2STRINGS Convert vector of numbers to cell array of char vectors
% using str_pattern
% Reproduces behavior of arrayfun(@(x)
% sprintf(str_pattern,x),vec,'UniformOutput',0)
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
if nargin < 2
    str_pattern = '%g'; % default just output number
end
% assert(isvector(vec),'vec must be a 1D vector')

char_cell_array = cell(size(vec));
for i = 1:numel(vec)
    char_cell_array{i} = sprintf(str_pattern,vec(i));
end

end
