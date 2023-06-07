function [TrialStuff MinNumTrials] = CounterBalancingActV2(DistType, DistTypeNames, OrientBins)
%Syntax:
%CounterBalancingAct(DistType, DistTypeNames, cue_predict, OrientBins)
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
%specifically geared to work in the context of WM_Distract, so if you want
%to use it later (yeah, future me, read this carefully) DO NOT JUST BLINDLY
%ADAPT THIS (ha. like future me would, you fucking perfectionist)
%
%Written by RR, July 2016

%----------------------------------------------------------------------
%COUNTERBALANCING ACT--------------------------------------------------
%----------------------------------------------------------------------
TrialStuff = [];
for dist = DistType+1 %distractor type
    for orient_bin_target = 1:size(OrientBins,2)
        for orient_bin_dist = 1:size(OrientBins,2)
            trial.distractortype = dist-1; %distractor type
            trial.distractorname = DistTypeNames(dist);
            trial.orient = randsample(OrientBins(:,orient_bin_target),1);
            if strcmp('grating',char(DistTypeNames(dist)))
                trial.distractororient = randsample(OrientBins(:,orient_bin_dist),1);
            else
                trial.distractororient = [];
            end
            TrialStuff = [TrialStuff trial]; % big struct with all the info I need to present stimulus conditions
        end
    end
end
TrialStuff = Shuffle(TrialStuff); % do the shuffle!
MinNumTrials = length(TrialStuff); % my number of trials follows from the minimum I need to get everything counterbalanced...
