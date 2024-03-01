function [ranovatbl,rm] = run_rm_anova_btwn_and_within_effects(Y1,Y2,alpha)
% run_rm_anova_btwn_and_within_effects run RM Anova with 1 between subject
% comparison (e.g. genotype) and N within subject comparisons (e.g. drug or field
% stimulation)
% Y1 - [num_dishes x num_conditions within dish] (e.g. WT)
% Y2 - [num_dishes2 x num_conditions within dish] (e.g. mutant)
if nargin < 2
   alpha = 0.05;  
end
num_dishes1 = size(Y1,1);
num_dishes2 = size(Y2,1);
genotype = [repmat({'WT'},1,num_dishes1),repmat({'KD'},1,num_dishes2)]';

% t = table(genotype,Y1(:))
t = array2table([Y1;Y2]);
t.Properties.VariableNames = numericVec2chars(1:size(Y1,2),'Cond%g');
t.genotype = genotype; 
stim_conds = array2table([1:size(Y1,2)]');
stim_conds.Properties.VariableNames = {'StimCond'};
rm = fitrm(t,sprintf('Cond1-Cond%g ~ genotype',size(Y1,2)),'WithinDesign',stim_conds);

ranovatbl = ranova(rm); 
end