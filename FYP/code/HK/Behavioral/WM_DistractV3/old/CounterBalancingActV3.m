function [TrialStuff MinNumTrials] = CounterBalancingActV3(OrientBins, Quads, SetSize, Contrast)
%Syntax:
%CounterBalancingAct(DistType, DistTypeNames, cue_predict, OrientBins, Quads)
%
%This little function does all my counterbalancing such that I can save out
%what needs to happen on every trial and reload it several times for
%different runs. This is important, because once I fully counterbalance all
%my conditions I end up with a lot of trials, more that can be fit into a
%single run.
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

% change ori bins to 2?
% even number of set sizes all 81
% 243 trials to balance ori and position
% designMat = fullfact([3 3 3 3 3])


TrialStuff = [];

% assign set size, orientation, contrast, and position in the quadrant
for set = SetSize
   if set == 1
        for i = 1:(54/size(OrientBins,2)) %  should be 48 trials of set size 1 per contrast condition
        for orient_bin_target = 1:size(OrientBins,2)
            trial.setsize = 1;
            trial.orient = randsample(OrientBins(:,orient_bin_target),1);
            trial.position = randi(size(Quads,2));
            trial.contrast = datasample(Contrast,1);
            choice = [trial.position, trial.position, trial.position, setdiff(Quads, trial.position)];
            trial.test = datasample(choice,1);
            if trial.test == trial.position
                trial.testorient = trial.orient;
            else 
                trial.testorient = NaN;
            end
            TrialStuff = [TrialStuff  trial];
        end
        end  
     elseif set == 2
         for i = 1:(54/size(OrientBins,2)) % 54 trials of set size 2 per contrast condition
         for orient_bin_target = 1:size(OrientBins,2)
             trial.setsize = 2;
             trial.orient = randsample(OrientBins(:,orient_bin_target),2);
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
         end
         end
    elseif set == 4
        for i = 1:(81/size(OrientBins,2)) % 81 trials of set size 4 per contrast condition
        for orient_bin_target = 1:size(OrientBins,2)
            trial.setsize = 4;
            trial.orient = randsample(OrientBins(:,orient_bin_target),4);
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
    else 
        trial.orient = [];
   end  
end

TrialStuff = Shuffle(TrialStuff); % do the shuffle!
MinNumTrials = length(TrialStuff); % my number of trials follows from the minimum I need to get everything counterbalanced...


    
       