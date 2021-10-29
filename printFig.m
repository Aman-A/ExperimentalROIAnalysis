function printFig(fig_handle,file_dir,file_name,varargin)
%PRINTFIG ... 
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
in.formats = {'fig','png'}; 
in.resolutions = {[],'-r300'}; 
in.print_level = 1; 
in = sl.in.processVarargin(in,varargin); 
if ischar(in.formats)
   in.formats = {in.formats};    
end
num_files = length(in.formats); 
if ischar(in.resolutions) % single resolution for all files
   in.resolutions = repmat({in.resolutions},1,num_files);  
end
assert(num_files == length(in.resolutions),...
    'Need to specify resolution for each format being saved');
if ~exist(file_dir,'dir')
   mkdir(file_dir); 
   fprintf('Created figure directory: %s\n',file_dir); 
end
for i = 1:num_files
    formati = in.formats{i};
    resi = in.resolutions{i};
    if strcmp(formati,'fig')
        savefig(fig_handle,fullfile(file_dir,[file_name '.fig']));
    elseif strcmp(formati,'png')
        if exist('export_fig','file')
            export_fig(fig_handle,fullfile(file_dir,[file_name '.png']),'-png',resi);
        else
            print(fig_handle,fullfile(file_dir,[file_name '.png']),'-dpng',resi);
        end
    elseif strcmp(formati,'eps')
        if exist('export_fig','file')
            export_fig(fig_handle,fullfile(file_dir,[file_name '.eps']),'-eps',resi);
        else
            print(fig_handle,fullfile(file_dir,[file_name '.eps']),'-depsc',resi);
        end
    end
end
print_str = [sprintf('Saved %s to %s in formats: ',file_name,strrep(file_dir,'\','/')),...
              sprintf('%s ',in.formats{:}),'\n'];
if in.print_level > 0
    fprintf(print_str)
end