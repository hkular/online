%% goals:

% get error total
% get error saw something that wasn't there
% get reaction times
% get confidence rankings
% match confidence rankings to error
%%

clear
close all
clc

subs = ['01';'02';'03';'04';'05';'06';'07';'08'];

%my_path = '/mnt/neurocube/local/serenceslab/Rosanne/NN/OSF/';
my_path = '/Users/hollykular/Documents/FYP/code/HK/Behavioral/WM_DistractV3/'
%my_path = '/Users/hkular/Documents/FYP/code/HK/Behavioral/Sherlock/';

addpath([my_path 'SupportFunctions'])
cd('Data/V10')

% plot_individuals = 1; % can plot individual subjects if you'd like
%set up a collection bin
Alldata = []; 
for s = 1:size(subs,1)
    

    %find the filenames for the subject data
    myFolder = pwd;
    filePattern = fullfile(myFolder, 'WM_DistractV*'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);
    
    %load this subjects data
    load([theFiles(s).name])
    length(TheData); 
    nonresp = [];
    correct = [];
    falsereport = [];
    correctn = [];
    falsereportn = [];
    % calculate some things
    for run = 1:length(TheData) % for each run
  
        nonresp = [nonresp;TheData(run).nonresp];
        correct = [correct; TheData(run).correct];
        falsereport =  [falsereport; TheData(run).falsereport];
        correctn = [correctn; TheData(run).correctn];
        falsereportn =  [falsereportn; TheData(run).falsereportn];
        
    end 
    collect_things_here = [[s;s;s;s;s;s;s;s],...
            [1;2;3;4;5;6;7;8],...
            correct,...
            correctn,...
            falsereportn,...
            falsereport,...              
            nonresp]; 
        Alldata = [Alldata; collect_things_here];
        Alldata_names = {'subject', 'run', 'hitsr', 'hitsn','falsereportn' ,'falsereportr', 'nonresponse'};

end

%% preliminary thoughts
% question - is it too easy?
% question - is the response time good?
% question - is the contrast good?
% is orientation good?
% number of trials good?
% V6 - 192 (2 sessions 384)
% V7 - 240 (2 sessions 480)
%% Basic look
% Avg hit all subjects all runs: chance is 25%
Avg_hitr = mean(Alldata(:,3)); % 30.42%
Avg_hitn = mean(Alldata(:,4)); % 7.36 per run (24 or 30 trials per run)
Avg_hitnlow = mean(Alldata(1:24,4));% 7.13 per run for 24 trial runs and two practice blocks 
Avg_hitnhigh = mean(Alldata(25:64,4));% 7.5 per run for 30 trial runs and three practice blocks
% Avg false report all subjects all runs:
Avg_falserepr = mean(Alldata(:,6)); % 29.02%
Avg_falserepn = mean(Alldata(:,5)); % 7.3 per run (24 or 30 trials per run)
Avg_falserepnlow = mean(Alldata(1:24,5));% 4.42 per run for 24 trial runs and two practice blocks
Avg_falserpnhigh = mean(Alldata(25:64,5));% 9.05 per run for 30 trial runs and three practice blocks
% Avg non response all subjects all runs:
Avg_nonresp = mean(Alldata(:,7)); % 2.97 per run

% convert to csv to continue work in R because ggplot 
%csvwrite('WM_pilot_220404.csv', all_dat);
% name variables 
%Alldata1.Properties.VariableNames = Alldata_names
%writestruct(all_dat,'WM_pilot_220404.csv');
writetable(struct2table(all_dat),'WM_pilot_220512.csv');
 sm = cell2mat(table2array(cell2table(struct2cell(all_dat))));
 sm = cell2mat(reshape(struct2array(all_dat), [], numel(fieldnames(all_dat)))');
 sm = struct2table(all_dat);
 writetable(sm, 'WM_pilot.csv');