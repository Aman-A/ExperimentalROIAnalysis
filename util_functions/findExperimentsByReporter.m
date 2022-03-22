function exp_dates_reporter = findExperimentsByReporter(reporter,data_fold)

if nargin < 2
   data_fold = getDataFold();  
end

exp_date_dirs = dir(data_fold);
exp_dates = {exp_date_dirs([exp_date_dirs.isdir]).name};
exp_dates = exp_dates(~ismember(exp_dates ,{'.','..'}));
exp_index = []; 
reporters_by_dates = cell(length(exp_dates),1);
for i = 1:length(exp_dates)
    diri = dir(fullfile(data_fold,exp_dates{i})); 
    reportersi = {diri([diri.isdir]).name};
    reportersi = reportersi(~ismember(reportersi ,{'.','..'}));
    reporters_by_dates{i} = reportersi;
    exp_index = [exp_index, i*ones(1,length(reportersi))]; 
end
reporters_lin = [reporters_by_dates{:}];
reporter_date_inds = strcmp(reporter,reporters_lin); 
exp_dates_reporter = exp_dates(exp_index(reporter_date_inds)); 
end