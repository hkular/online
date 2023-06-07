% vonMises_fit.m fits a von mises in degrees (1:180)


function Error = vonMises_fit(param_est,ydata,x) %llMises = vonMises_fit(est_params, x, n_correct, n_error)

% parameters
var = param_est(1);
mu = param_est(2);

% von Mises function
yfit = (1./(2.*pi.*besseli(0,var))) .* exp(var*cos((x-mu)/180*2*pi));

Error = ydata - yfit;   % difference between actual and fitted y values, at each value of x
Error = sum(Error.^2);  % sum of squared error terms


% q = 1 - p;


% % calculate the log likelihood
% llik = n_correct.*log(p) + n_error.*log(q);
% 
% % Value to minimize.
% llWeib = -sum(llik);

