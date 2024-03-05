function [rsq_adj, rsq] = calcAdjustedRsq(y,yfit,b)
% y - data points
% yfit - output of fit
% b - coefficients of fit
% Based on: https://www.mathworks.com/help/matlab/data_analysis/linear-regression.html
yresid = y - yfit; 
SSresid = sum(yresid.^2);
SStotal = (length(y)-1) * var(y); % total sum of squares y, variance of y * number of observations - 1
rsq = 1 - SSresid/SStotal; % normal R^2
rsq_adj = 1 - SSresid/SStotal * (length(y)-1)/(length(y) - length(b)); % Adjusted R^2

end