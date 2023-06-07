function [TrialStuff MinNumTrials] = CounterBalancingActV4(OrientBins, Quads, SetSize, Contrast)
%Syntax:
%CounterBalancingAct(DistType, DistTypeNames, cue_predict, OrientBins, Quads)
%
%This little function does all my counterbalancing such that I can save out
%what needs to happen on every trial and reload it several times for
%different runs. This is important, because once I fully counterbalance all
%my conditions I end up with a lot of trials, more that can be fit into a
%single run.
% aim to have equal number of trials for each set size condition, will
% fully counterbalance orientation and position, will pseudo-counterbalance
% contrast, and test
%
%IN --->
%     DistType: Type of distractor (vector of 1 by number of distractor types)
%     DistTypeNames: Names of distractors (cell array of size names by 1)
%     cue_predict: Is the cue predictive? (vector [0 1])
%     OrientBins: Orientation values in my bins (matrix of orients_in_bin
%     by num_bins big)
%     Quads: The quadrant of the screen the distractor or target is
%     presented
%     SetSize: how many stimuli are presented at once
%
%OUT --->
%     TrialStuff: A struct of which each entry has all the information
%     needed for a given trial. Index it by TrialStuff(trial_num) to see
%     all that is in there for that trial. Index it by
%     TrialStuff(trial_num).specific_thing_I_need to get the shit you need.
%     MinNumTrials: The minimum number of trials required for
%     counterbalancing. In the end if you wanna fully counterbalance your
%     life you want to run this many, or any multiple of this many trials.
%
%This is not the most flexible function ever written, it is really
%specifically geared to work in the context of WM_DistractV3
%
%Written by RR, July 2016
% adapted by HK, Jan 2022

%----------------------------------------------------------------------
%COUNTERBALANCING ACT--------------------------------------------------
%----------------------------------------------------------------------

% even number of trials per set size, 64
% 192 trials/ per session to balance ori and position, two sessions 384 trials total
% designMat = fullfact([3 2 2 2 2]) size


% Counterbalanced variables in design
prefs.setSize = [1,2,4]; % Memory set size
prefs.Ori = 1:2; % Make sure the prioritized item is equally counterbalanced
prefs.nPerCond = 8; % number of repeats of design matrix to get total # of trials desired per block

% Design matrix
prefs.design = fullfact([length(prefs.setSize),length(prefs.Ori),length(prefs.Ori),length(prefs.Ori), length(prefs.Ori),prefs.nPerCond]);

% Columns: 1 = set size, 2 = ori position 1, 3 = ori position 2, 4 = ori
% position 3, 5 = ori position 4, 6 = block number

shuf = Shuffle(prefs.design); % shuffle them
sor = sortrows(shuf, 6); % sort by trial number



% now let's convert into the structure the experiment script expects
TrialStuff = [];


for i = 1:length(sor)
    if sor(i,1) == 1
        trial.block = sor(i,6);
        trial.setsize = 1; % set size is full counterbalanced
        trial.orient = randsample(OrientBins(:,sor(i,2)),1); % orientation is full counterbalanced
        trial.position = randi(size(Quads,2)); % position is pseudo-balanced
        trial.contrast = datasample(Contrast,1); % contrast is pseudo-balanced
        choice = [trial.position, trial.position, trial.position, setdiff(Quads, trial.position)];
        trial.test = datasample(choice,1); % test is pseudo-balanced
        if trial.test == trial.position
             trial.testorient = trial.orient;
        else 
             trial.testorient = NaN;
        end
         TrialStuff = [TrialStuff  trial];
    elseif sor(i,1) == 2
        trial.block = sor(i,6);
         trial.setsize = 2;
         trial.orient = [randsample(OrientBins(:,sor(i,2)),1), randsample(OrientBins(:,sor(i,3)),1)];
         trial.position = randperm(size(Quads,2),2);
         trial.contrast = datasample(Contrast,2);
         trial.test = datasample([trial.position],1);
         if ismember(trial.test, trial.position) == 1
            j = find(trial.position == trial.test);
            trial.testorient = trial.orient(j);
        else 
            trial.testorient = NaN;
         end
         TrialStuff = [TrialStuff trial]; 
    elseif sor(i,1) == 3
        trial.block = sor(i,6);
        trial.setsize = 4;
        trial.orient = [randsample(OrientBins(:,sor(i,2)),1), randsample(OrientBins(:,sor(i,3)),1), randsample(OrientBins(:,sor(i,4)),1), randsample(OrientBins(:,sor(i,5)),1)];
        trial.position = randperm(size(Quads,2),4);
        trial.contrast = datasample(Contrast,4);
        trial.test = datasample(trial.position,1); 
        if ismember(trial.test, trial.position) == 1
            j = find(trial.position == trial.test);
            trial.testorient = trial.orient(j);
        else 
            trial.testorient = NaN;
         end
        TrialStuff = [TrialStuff trial];
    end
end

MinNumTrials = length(TrialStuff); % my number of trials follows from the minimum I need to get everything counterbalanced...
