clc
clear 

%% first let's simulate psychometric function data from method of adjustment expt

% Subjects task is to remember a single orientation for 3 seconds. During 
% these 2 seconds a second task-irrelevant orientation is presented. I want 
% to know whether subjects are always reporting the orientation in memory, 
% or that maybe on a proportion of trials they are reporting the wrong 
% (distractor) orientation. To do so we must compare 2 models. One is a
% fullmodel which has the bimodal (two) distibution accounted for, so something 
% like fullmodel = normrnd(0, .2, 10000,1); normrnd(-45, .2, 100,1)]; 
% The alternative is a single von Mises that fits all the data, so a nested
% model, somehting like nestedmodel = [normrnd(0, .2, 10100,1)]; We fit
% both models and then compare goodness of fit via a likelihood ratio test

% because we're dealing with circular data, we should make those normrnd's 
% a von mises, which is more accurate. 

% The log likelohood test is h = lratiotest(uLogL,rLogL,dof). Here, u is the
% full model (u=unconstrained), and r is nested (r=restricted). Make sure 
% they're logged likelihoods you enter.

 

% the set of parameters below are specific to a von mises.  If you're not
% familiar with what they do, feel free to change them and see how that
% affects the plot 
var = 6;            % the variance of the function basically, or SD (in º)
mu = 0;             % mean of the distribution
asymptote = 0.01;   % asymptote?  

% params assoociated with the simulated 'experiment'.  spend some time
% playing with these params, varying the number of trials, or noisiness of 
% your simulated subject.
n_obs = 100;        % total number of 'trials' simulated
sigma = .01;        % variance in simulated data (noisiness of observer)    
x = 1:180;          % x values (degree space)

p = 1./(2.*pi.*besseli(0,(var./180.*2.*pi).^-2)) .* exp((var./180.*2.*pi).^-2.*cos((x-mu)./180.*2.*pi)); % generate von mises function

p_noisy = normrnd(p,sigma);     % perturb function with noise 
% p_noisy = min(p_noisy, .99);            % prevent log of zero


% plot simulated data
subplot(1,3,1)
plot(x, p_noisy, 'o'); hold on;     
xlabel('orientation'); ylabel('frequency')


%% now, let's estimate the distribution these data came from, using MLE

startParams = [5 0];    % starting parameters for fminsearch to try

% Get Maximum Likelihood Estimate (MLE).  What we're doing here is
% iteratively 'trying out' different sets of free parameters, using
% 'fminsearch'. Fminsearch is an exceptionally handy function in matlab,
% that uses a 'gradient search' algorith to best fitting parameters.  Note
% that fminsearch actually is trying to find 'minimums', so in our function
% weibulFit, we just convert the log likelihood into a negative log
% likelihood, to make sure that we're maximizing log likelihood, rather than
% minimizing it.  Now, for other functions you may not be able to maximize
% likelihood.  For instance, with fmri data, there is not probability on
% the y-axis, so you can't have a 'likelihood' estimated if you were
% fitting data w/ some nonlinear function.  In that case, you can maximize
% other things, such as R^2.  This is nonlinear regression, which follows
% the same priciple as this tutorial, with very slight differences.
[est_params] = fminsearch('vonMises_fit', startParams, [], p_noisy, x); % obtain MLE

% plot weibull to the simulated data, based on estimated parameters.
% Depending on how noisy you decided to make the simulated data, it should
% do a pretty great job fitting the data!
p_est = 1./(2.*pi.*besseli(0,(var./180.*2.*pi).^-2)) .* exp((var./180.*2.*pi).^-2.*cos((x-mu)./180.*2.*pi)); 
plot(x, p_est, '--');


%% 1-parameter likelihood function for the variance (fixed mu)
% to get a better intuition for what we're doing with the fitting, let's
% just look at the likelihood function for one parameter (variance).  By
% assessing the likelihood of a range of variances, given the data, we can see
% where fminsearch decided to 'land' in determining it's best fit.  

variances = linspace(0,50,100); % generating a set of alpha values
mu = 0;

% calculate log likelihood for these values of alpha
for ii = 1:length(variances)
    p = 1./(2.*pi.*besseli(0,(variances(ii)./180.*2.*pi).^-2)) .* exp((variances(ii)./180.*2.*pi).^-2.*cos((x-mu)./180.*2.*pi));
    q = 1 - p;
    llik = n_correct.*log(p) + n_error.*log(q);
    llikelihoods(ii) = sum(llik);
end

% plot likelihood function...  here we can clearly see that there is a
% particular value for alpha that achieves the maximum likelihood.  
subplot(1,3,2)
plot(alphas, llikelihoods); hold on;     
xlabel('variance'); ylabel('log likelihood')


%% 1-parameter likelihood function for the mean (fixed variance)
mus = linspace(-20,20,100); % generating a set of alpha values

% calculate log likelihood for these values of alpha
for jj = 1:length(mus)
    p = 1./(2.*pi.*besseli(0,(var./180.*2.*pi).^-2)) .* exp((var./180.*2.*pi).^-2.*cos((x-mus(jj))./180.*2.*pi));
    q = 1 - p;
    llik = n_correct.*log(p) + n_error.*log(q);
    llikelihoods(jj) = sum(llik);
end

% plot likelihood function...  here we can clearly see that there is a
% particular value for alpha that achieves the maximum likelihood.  
subplot(1,3,3)
plot(mus, llikelihoods); hold on;     
xlabel('mu'); ylabel('log likelihood')


%% 3D likelihood surface for both variance and mu
% With nonlinear model fitting, in which you have multiple free parameters 
% you want to estimate simultaneously, you're often dealing with local
% maxima, which aren't exactly the best fit.  Here we plot a log
% likelihood 'suface' for variance and mu, given the simulated data.  You
% can see that while there is clearly a global maximum (the best pair of
% variances and mu's given this data), there are also local maximum 
% (those ridges), which if you're not careful, the fitting algorithm will 
% accidentlly 'settle on'. The more complex your model, the more likely 
% you may run into local maxima problems when fitting your data.


% calculate log likelihoods for a large permutations of alpha & beta
for ii = 1:length(variances)
    for jj = 1:length(mus)
        p = .5+(.5-.01)*(1-exp(-(x/alphas(ii)).^betas(jj)));
        q = 1 - p;
        llik = n_correct.*log(p) + n_error.*log(q);
        llikelihoods(jj,ii) = sum(llik);
    end
end

% plot likelihood surface for 2 params
figure
surf(alphas, betas, llikelihoods); 
xlabel('alpha'); ylabel('beta'); zlabel('log likelihood ')  
hold on;
colorbar
