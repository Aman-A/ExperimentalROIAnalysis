function [ranovatbl,rm] = run_2way_rm_anova(Y,varargin)
% Y - [num_dishes x num_var1 x num_var2] 

in.var_names = {'Var1','Var2'};
in.display_anova = 1;
in = sl.in.processVarargin(in,varargin);

num_var1 = size(Y,2);
num_var2 = size(Y,3);
[inds_var1,inds_var2] = meshgrid(1:num_var1,1:num_var2);
inds_var1 = inds_var1';
inds_var2 = inds_var2';
Y_tbl = Y(:,:); % [num_dishes x (num_var1 + num_var2)]

within = table(categorical(inds_var1(:)),categorical(inds_var2(:)),...
                'VariableNames',in.var_names);
% conditions_labels_all = repmat(conditions_labels,num_dishes,1);
t = array2table(Y_tbl); 
rm = fitrm(t,sprintf('%s-%s ~ 1',t.Properties.VariableNames{[1 end]}),...
            'WithinDesign',within,'WithinModel',sprintf('%s*%s',in.var_names{:})); 
[ranovatbl, A,C,D] = ranova(rm,'WithinModel',sprintf('%s*%s',in.var_names{:})); 
if in.display_anova
    disp(anovaTable(ranovatbl,'Value'))
end
end


% -----------------------------------------------------------------------------------
% Scott's function to create a standard-looking ANOVA table from the
% terrible anova table created by the ranova function.
% From: https://www.mathworks.com/matlabcentral/answers/886394-repeated-measures-anova-with-two-variables?s_tid=mlc_ans_email_ques
function [s] = anovaTable(AT, dvName)
    c = table2cell(AT);
    % remove erroneous entries in F and p columns 
    for i=1:size(c,1)       
            if c{i,4} == 1
                c(i,4) = {''};
            end
            if c{i,5} == .5
                c(i,5) = {''};
            end
    end
    % use conventional labels in Effect column
    effect = AT.Properties.RowNames;
    for i=1:length(effect)
        tmp = effect{i};
        tmp = erase(tmp, '(Intercept):');
        tmp = strrep(tmp, 'Error', 'Participant');
        effect(i) = {tmp}; 
    end
    % determine the required width of the table
    fieldWidth1 = max(cellfun('length', effect)); % width of Effect column
    fieldWidth2 = 57; % field needed for df, SS, MS, F, and p columns
    barDouble = sprintf('%s\n', repmat('=', 1, fieldWidth1 + fieldWidth2));
    barSingle = sprintf('%s\n', repmat('-', 1, fieldWidth1 + fieldWidth2));
    % re-organize the data 
    c = c(2:end,[2 1 3 4 5]);
    c = [num2cell(repmat(fieldWidth1, size(c,1), 1)), effect(2:end), c]';
    % create the ANOVA table
    s = sprintf('ANOVA table for %s\n', dvName);
    s = [s barDouble];
    s = [s sprintf('%-*s %4s %10s %14s %10s %10s\n', fieldWidth1, 'Effect', 'df', 'SS', 'MS', 'F', 'p')];
    s = [s barSingle];
    s = [s, sprintf('%-*s %4d %14.3f %14.3f %10.3f %10.4f\n', c{:})];
    s = [s, barDouble];
end