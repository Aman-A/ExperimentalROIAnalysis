function saveROIfuncOutput(func_output,output_folder,varargin)

in.funcs = 'all'; % default save all funcs in func_output, otherwise 
                  % replace with cell array of strings specifying funcion 
                  % outputs to save
in = sl.in.processVarargin(in,varargin);                   
% Default output folder name
if nargin < 2
   output_folder = [func_output.img_name '_output'];
end
% Create output folder directory if necessary
if ~exist(output_folder,'dir')
   mkdir(output_folder);
   fprintf('Created output folder: %s\n',output_folder); 
end
possible_funcs = {'mean','std','deltaF_F0','baseline'}; 
if strcmp(in.funcs,'all')
    save_funcs = possible_funcs;
elseif iscell(in.funcs)
    save_funcs = in.funcs;
end
% get funcs included in func_output
func_output_fields = fieldnames(func_output);
avail_funcs_to_save = intersect(func_output_fields,save_funcs);
if length(save_funcs) ~= length(avail_funcs_to_save)
    unavail_funcs = setdiff(save_funcs,func_output_fields); 
    invalid_funcs = setdiff(unavail_funcs,possible_funcs);
    if ~isempty(invalid_funcs)
       fprintf('WARNING: ''%s'' are not valid functions, skipping...\n',...
                strjoin(invalid_funcs,','));
    end
    remain_unavail_funcs = setdiff(unavail_funcs,invalid_funcs);
    if ~isempty(remain_unavail_funcs)
       fprintf(['WARNING: ''%s'' were not computed in given function output,',...
               ' please re-run calcROIfuncs with these included \n'],...
                strjoin(remain_unavail_funcs));
    end
end
if strcmp(func_output.roi_func_mode,'separate')
    header = numericVec2chars(func_output.roi_inds,'ROI%g');    
elseif strcmp(func_output.roi_func_mode,'combine')
    header = {'AllROIs'};
end
if iscolumn(header)
    header = header';
end
for i = 1:length(avail_funcs_to_save)
    funci = avail_funcs_to_save{i};
    datai = func_output.(funci);
    filenamei = fullfile(output_folder,sprintf('%s_%s_%s.csv',...
        func_output.img_name,funci,func_output.roi_func_mode));
    writecell(header,filenamei);
    writematrix(datai,filenamei,'WriteMode','append');     
end
print_str = ['Saved data from funcs: ', strjoin(avail_funcs_to_save,', '),...
              ' to ',strrep(output_folder,'\','\\'),'\n']; 
fprintf(print_str)