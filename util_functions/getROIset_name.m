function roiset_filename_no_ext = getROIset_name(roiset_filename,transform_type,...
                                                 registration_rec)
%GETROISET_NAME ... 
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
if ischar(roiset_filename)
    [~,roiset_filename_no_ext] = fileparts(roiset_filename);     
    if ~strcmp(transform_type,'none') &&  ~isempty(transform_type)
        if ischar(registration_rec)
            registration_rec = strrep(registration_rec,'\','/');
            [~,fixed_img_name,~] = fileparts(registration_rec); 
        elseif isa(registration_rec,'Recording')
            fixed_img_name = registration_rec.img_name; 
        end
        roiset_filename_no_ext = sprintf('%s_%s_%s',roiset_filename_no_ext,...
                                                     fixed_img_name,...
                                                     transform_type); 
    end
elseif iscell(roiset_filename)
    error('Input string or valid input to ROIs constructer')
else
    roiset_filename_no_ext = 'custom';
end