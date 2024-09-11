function andor_name = reindexFileNameForAndor(name,index)
%REINDEXFILENAMEFORANDOR get filename with 1 indexing for Andor indexing
%style
%  index:        1      2      3
%  andor name: file, file_1, file_2
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if index == 1
    andor_name = name; 
else
    andor_name = sprintf('%s_%g',name,index-1); 
end
