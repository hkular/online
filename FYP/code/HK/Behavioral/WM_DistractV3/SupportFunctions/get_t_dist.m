function [p_val, t_data, t_iter] = get_t_dist(in_data, num_shuffles, make_hist)
% Makes a null distribution of t-values for a within subject (so paired)
% t-test.
%
% OUTPUT
% p_val: p-value associated with the real t compared to shuffled t-values.
% t_data: t value calculated from the actual data (intact labels). 
% t_iter: the actual t-distribution in case you wanna see its shape.
%
% INPUT
% in_data: must be a vector of num_measurements (i.e. subjects) x 1 (if you
% want to test against zero), or a matrix of num_measurements x 2 (if you
% want to compare two conditions).
% num_shuffles: number of shuffles you wanna do (default is 1000)
% make_hist: makes histogram of your f-distributions if true (default is true)

if nargin < 3, make_hist = 1; end % default is to show histogram of f's
if nargin < 2, num_shuffles = 1000; end % default is 1000 shuffles

% get some info about my data
num_subs = size(in_data,1); % 1st dimension of in_data is number of subjects

% get the t-value of my data
t_data = mean((in_data(:,2)-in_data(:,1))-0)/(std(in_data(:,2)-in_data(:,1)) / sqrt(num_subs));


% do the permutations
t_iter = NaN(1,num_shuffles);
for p = 1:num_shuffles
    
    % first break the condition labels
    for n = 1:num_subs
        shuffled_in_data(n,:) = in_data(n,Shuffle(1:2));
    end
    
    % get the t-value of my shuffled data
    t_iter(p) = mean((shuffled_in_data(:,2)-shuffled_in_data(:,1))-0)/(std(shuffled_in_data(:,2)-shuffled_in_data(:,1)) / sqrt(num_subs));
end
       
% get p-value (two sided test)
p_val = min(sum(t_data>t_iter), sum(t_data<t_iter))/num_shuffles*2;


if make_hist
    figure;hold on;
    h = histogram(t_iter,[-6:.1:6]);
    ci = prctile(t_iter,[2.5 97.5]);
    plot([ci; ci],[0 0; max(get(h,'Values'))+(max(get(h,'Values'))/100*10) max(get(h,'Values'))+(max(get(h,'Values'))/100*10)],'r')
    plot([t_data t_data],[0 0; max(get(h,'Values'))+(max(get(h,'Values'))/100*10) max(get(h,'Values'))+(max(get(h,'Values'))/100*10)],'k:','Linewidth',2)
    set(gca,'Ylim',[0 max(get(h,'Values'))+(max(get(h,'Values'))/100*10)]);
end




