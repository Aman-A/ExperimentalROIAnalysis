function roiset_filename_no_ext = getROIset_name(roiset_filename,transform_type,...
                                                 registration_rec)
%GETROISET_NAME(roiset_filename,transform_type,registration_rec) 
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
    roiset_filename_no_ext = appendRegistrationSuff(roiset_filename_no_ext,...
                                        transform_type,registration_rec);
elseif iscell(roiset_filename)
    error('Input string or valid input to ROIs constructer')
elseif isa(roiset_filename,'ROIs')
    roiset_filename_no_ext = roiset_filename.roiset_filename; 
    roiset_filename_no_ext = appendRegistrationSuff(roiset_filename_no_ext,...
        transform_type,registration_rec);
else
    roiset_filename_no_ext = 'custom';
end
end
function roiset_filename_no_ext2 = appendRegistrationSuff(roiset_filename_no_ext1,...
                                            transform_type,registration_rec)
if ~strcmp(transform_type,'none') &&  ~isempty(transform_type)
    if ischar(registration_rec)
        registration_rec = strrep(registration_rec,'\','/');
        [~,fixed_img_name,~] = fileparts(registration_rec);
    elseif isa(registration_rec,'Recording')
        fixed_img_name = registration_rec.img_name;
    end
    roiset_filename_no_ext2 = sprintf('%s_%s_%s',roiset_filename_no_ext1,...
        fixed_img_name,...
        transform_type);
else
    roiset_filename_no_ext2 = roiset_filename_no_ext1;
end
end