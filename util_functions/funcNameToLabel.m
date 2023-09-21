function label_str = funcNameToLabel(func_name,indicator_flipped)
%FUNCNAMETOLABEL Convert function name input to calcROIfunc to label for plotting 
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
if nargin == 1
    indicator_flipped = 0; 
end
if strcmp(func_name,'deltaF_F0')
    label_str = '\Delta F/F_{0}';
elseif strcmp(func_name,'deltaF')
    label_str = '\Delta F';
elseif regexp(func_name,'aligned','ONCE')
    label_str = 'Mean \Delta F/F_{0}';
elseif strcmp(func_name,'mean')
    label_str = 'mean F (a.u.)';
else
   label_str = strrep(func_name,'_',' '); 
end
if indicator_flipped
    label_str = ['- ' label_str];
end