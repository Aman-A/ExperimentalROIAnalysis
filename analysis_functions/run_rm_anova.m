function [ranovatbl,mult_comp] = run_rm_anova(Y,alpha)
% Y - [num_conditions x num_dishes] 
if nargin < 2
   alpha = 0.05;  
end
num_conditions = size(Y,1);
num_dishes = size(Y,2);
dish_names = numericVec2chars(1:num_dishes,'dish%g');
% Y_lin = Y(:); % [dish1_cond1;dish1_cond2;dish1_cond3;...]
Y_tbl = Y'; %[num_dishes x num_conditions]
conditions_labels = numericVec2chars(1:num_conditions,'cond%g');
conditions_table = cell2table(conditions_labels');
conditions_table.Properties.VariableNames = {'Condition'}; 

% conditions_labels_all = repmat(conditions_labels,num_dishes,1);
t = array2table(Y_tbl); 
t.Properties.VariableNames = conditions_labels;
% sprintf('cond%g-%g ~ response',1,num_conditions)
rm = fitrm(t,sprintf('cond1-cond%g ~ 1',num_conditions),'WithinDesign',conditions_table); 
ranovatbl = ranova(rm); 

if ranovatbl.pValue(1) < alpha
    mult_comp = zeros(num_conditions); % multiple comparisons using wilcoxon rank-sum test (matched samples)
    % [
    for i = 1:num_conditions
        xi =  Y(i,:);
        for j = 1:num_conditions            
            if i ~= j && i < j
                yj = Y(j,:); 
                mult_comp(i,j) = ranksum(xi,yj); 
            end
        end
    end
    mult_comp = triu(mult_comp) + tril(mult_comp',1);
else
    mult_comp = []; 
    fprintf('Failed to reject null with alpha = %.3f\n',alpha); 
end
end