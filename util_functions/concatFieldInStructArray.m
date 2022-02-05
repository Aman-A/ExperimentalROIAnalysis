function X = concatFieldInStructArray(S,field_name)
% CONCATFIELDINSTRUCTARRAY concatenates field from each element of struct 
% array, assumes same size, combines along first additional dimension 
% (e.g. for 2D matrices, concatenates along 3rd dimension)

sz = size(S(1).(field_name)); 
len_array = length(S); 
dims = [sz,len_array]; 
X = squeeze(reshape([S.(field_name)],dims)); 
