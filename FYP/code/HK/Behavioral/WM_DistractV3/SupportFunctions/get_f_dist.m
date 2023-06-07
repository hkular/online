function [p_vals, ranova_table, iter] = get_f_dist(in_data, num_shuffles, make_hist)
% Makes a null distribution of f-values for the main effect(s) in a within
% subject repeated measures 1 or 2 way ANOVA. In case of a 2-way ANOVA it
% will also return an f-distribution for the interaction. Originally 
% written for a situation where I had 7 levels in one factor (ROI) and 3 in 
% the second factor (condition).
%
% OUTPUT
% p_vals: p-values associated with the real compared to shuffled f-values.
% ranova_table: the ANOVA table for the actual data (intact labels). This
% is where you can look up your data's actual F-values, and df's
% iter: the actual f-distributions in case you wanna see their shape.
%
% INPUT
% in_data: must be a matrix of num_measurements (i.e. subjects) x factor 1
% (roi) x factor 2 (condition). For a one-way ANOVA this input would 
% naturally have one dimension fewer (so only num_measurements x factor 1)
% num_shuffles: number of shuffles you wanna do (default is 1000)
% make_hist: makes histogram of your f-distributions if true (default is true)

if nargin < 3, make_hist = 1; end % default is to show histogram of f's
if nargin < 2, num_shuffles = 1000; end % default is 1000 shuffles

% is this a one-way or two-way anova?
nway_indata = ndims(in_data)-1;  

% get some info from my input data
num_subs = size(in_data,1); % 1st dimension of in_data is number of subjects
num_f1 = size(in_data,2); % 2nd dimension is how many levels there are of factor 1
factor1_names = strseq('f1_',1:num_f1); % name the levels of my factor
num_all = num_f1; % number of all data columns combined
if nway_indata == 2 % if a two-way, also specify my second factor
    num_f2 = size(in_data,3); % 3rd dimension is how many levels there are for factor 2
    factor2_names = strseq('f2_',1:num_f2); % name the levels of my factor
    num_all = num_f1*num_f2; % number of all data columns combined
end

% make labels & within subject factor table
if nway_indata == 1 % if a one-way
    % make within subject factor table
    within_table = table(factor1_names,'VariableNames',{'factor1_names'});
elseif nway_indata == 2 % if a two-way
    % make labels for my two independent repeated measures factors
    factor1_labels = reshape(repmat(factor1_names',num_f2,1),num_f1*num_f2,1);
    factor2_labels = reshape(repmat(factor2_names',1,num_f1),num_f1*num_f2,1);
    % make within subject factor table
    within_table = table(factor1_labels, factor2_labels,'VariableNames',{'factor1_labels','factor2_labels'});
end

% make dependent variable table 
if nway_indata == 1
    dep_var = in_data;
elseif nway_indata == 2
    dep_var = reshape(permute(in_data,[1,3,2]),num_subs,num_f1*num_f2);
end
my_str = strseq('V',11:10+num_all)';
dep_var_table = array2table(dep_var,'VariableNames',my_str);

% build the model
rm = fitrm(dep_var_table,[char(my_str(1)),'-', char(my_str(end)),'~1'],'WithinDesign',within_table);

% do the anova on the in_data
if nway_indata == 1
    [ranova_table] = ranova(rm,'WithinModel','factor1_names');
elseif nway_indata == 2
    [ranova_table] = ranova(rm,'WithinModel','factor1_labels*factor2_labels');
end


%% do the shuffle
iter = NaN(num_shuffles,3);

for i = 1:num_shuffles
    
    
    % for each subject
    for n = 1:num_subs
        shuf_indx = Shuffle(1:num_all);
        dep_var_shuffled(n,:) = dep_var(n,shuf_indx);
    end
    
    % then make a new dep_var table
    dep_var_table_shuffled = array2table(dep_var_shuffled,'VariableNames',my_str);
    
    % build the model 
    rm_shuffled = fitrm(dep_var_table_shuffled,[char(my_str(1)),'-', char(my_str(end)),'~1'],'WithinDesign',within_table);
    
    % do the anova & save out the f-values when all things are shuffled.
    if nway_indata == 1 % if a one-way
        [ranova_tmp] = ranova(rm_shuffled,'WithinModel','factor1_names');
        iter(i,1) = ranova_tmp{3,4};
    elseif nway_indata == 2 % if a two-way
        [ranova_tmp] = ranova(rm_shuffled,'WithinModel','factor1_labels*factor2_labels');
        iter(i,:) = ranova_tmp{[3 5 7],4}';
    end
end

if nway_indata == 1 % if a one-way
    p_vals = sum(iter(:,1)>ranova_table{3,4})/num_shuffles;
elseif nway_indata == 2 % if a two-way
    p_vals = [sum(iter(:,1)>ranova_table{3,4})/num_shuffles sum(iter(:,2)>ranova_table{5,4})/num_shuffles sum(iter(:,3)>ranova_table{7,4})/num_shuffles];
end


%% plot if you wanna
if make_hist
    figure;
    if nway_indata == 1 % if a one-way
        data_fs = ranova_table{3,4}';
        hold on; title(['factor 1, p = ', num2str(p_vals(1))]); xlabel('F Values'); ylabel('Frequency');
        h = histogram(iter(:,1),0:max(iter(:,1))/50:max(iter(:,1))); plot([data_fs(1) data_fs(1)],[0 max(h.Values)+max(h.Values)/10],'r');        
    elseif nway_indata == 2 % if a two-way        
        data_fs = ranova_table{[3 5 7],4}';
        subplot(1,3,1); hold on; title(['factor 1, p = ', num2str(p_vals(1))]); xlabel('F Values'); ylabel('Frequency');
        h = histogram(iter(:,1),0:max(iter(:,1))/50:max(iter(:,1))); plot([data_fs(1) data_fs(1)],[0 max(h.Values)+max(h.Values)/10],'r');
        subplot(1,3,2); hold on; title(['factor 2, p = ', num2str(p_vals(2))]);
        h = histogram(iter(:,2),0:max(iter(:,2))/50:max(iter(:,2))); plot([data_fs(2) data_fs(2)],[0 max(h.Values)+max(h.Values)/10],'r');
        subplot(1,3,3); hold on; title(['interaction, p = ', num2str(p_vals(3))]);
        h = histogram(iter(:,3),0:max(iter(:,3))/50:max(iter(:,3)));plot([data_fs(3) data_fs(3)],[0 max(h.Values)+max(h.Values)/10],'r');
    end
end




