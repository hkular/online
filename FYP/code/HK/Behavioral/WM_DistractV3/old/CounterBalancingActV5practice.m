function [TrialStuff designMatFull, MinNumTrials] = CounterBalancingActV5practice(OrientBins, SetSize, Quads, Contrast)
%Syntax:
%CounterBalancingAct(OrientBins, Quads, SetSize, Contrast)
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
%
%Written by RR, July 2016
% adapted by HK, Jan 2022

%----------------------------------------------------------------------
%COUNTERBALANCING ACT--------------------------------------------------
%----------------------------------------------------------------------

%----------------------------------------------------------------------
% number of spatial configurations differs across set size 1,2, and 4
%
%  make 3 mini design matrices, and then put them all together again at the end for your full
% experimental design.... 
%
% After we get them all put together, we'll have a design matrix with 6
% columns that are fully counterbalanced:
% [set size, ori loc 1, ori loc 2, ori loc 3, ori loc 4, spatial config]

designMat1 = fullfact([2 1 1 1 4]); % length = 8, 4 spatial config

% For set size 2, we have 6 possible spatial configurations (i.e., 2 items left, 2 items right
% Both items upper, 2 items lower, on diagonal, off diagonal 

designMat2 = fullfact([2 2 1 1 6]); % length  = 24, 6 spatial config

% For set size 4, we actually only have 1 possible spatial configuration
% since all locations are occupied 

designMat4 = fullfact([2 2 2 2 1]); % length = 16, 1 spatial config

% replicate each one of these the necessary amount of times so our trials
% are matched, size 48

designMat1 = repmat(designMat1,6,1);
designMat2 = repmat(designMat2,2,1);
designMat4 = repmat(designMat4,3,1);

% After replicating the appropriate number of times, we now have 3
% separate design matrices, each with 48 trials in them

% Now, we could just manually add a column for set size and combine them
% all together
nT_setsize = length(designMat1);

designMat1 = [ones(nT_setsize,1), designMat1];
designMat2 = [ones(nT_setsize,1)*2, designMat2];
designMat4 = [ones(nT_setsize,1)*4, designMat4];

designMatFull = [designMat1;designMat2;designMat4]; % length 144 trials

% Since we have some columns with just 1's in them, we'll just need to remember to make sure to draw the orientations based on the first
% N columns of the design matrix 

% We also just need to keep in mind that the "spatial configuration column"
% will depend on set size. For set size 1, 1 = quadrant 1, 2 = quadrant 2,
% etc. For set size 2, 1 = quadrants 1 & 2, 2 = quadrants 3 & 4, 
% 3 = quads 1&3, 4 = quads 1&4, 5 = quads 2&3, 6 = quads 2&4
% 
pos = [[1 2];[3 4];[1 3];[2 3];[1 4];[2 4]];

% pseudo-counterbalancing contrast
half_trials = length(designMatFull)/2; 
contrast_item1 = [ones(half_trials,1);ones(half_trials,1)*2];
contrast_item2 = [ones(half_trials,1);ones(half_trials,1)*2];
contrast_item3 = [ones(half_trials,1);ones(half_trials,1)*2];
contrast_item4 = [ones(half_trials,1);ones(half_trials,1)*2];
% randomized
designMatContrast = [Shuffle(contrast_item1), Shuffle(contrast_item2),Shuffle(contrast_item3),Shuffle(contrast_item4)];


% pseudo-counterbalancing test
% 1 is on target, 2 is off target
test_item  = [ones(half_trials,1);ones(half_trials,1)*2];
% randomized
designMatTest = Shuffle(test_item);

designMatFull = [designMatFull,designMatContrast, designMatTest]; %<- this adds 4 new columns which tells you teh contrast level for items 1-4 on each trial... these columns correspond to the 4 orientation bin columns we already made
% col1 = set size, col2 = ori1, col3 = ori2, col4 = ori3, col5 = ori4, 
% col6 = spatial config, col7 = cont1, col8 = cont2, col9 = cont3, 
% col10 = cont4, col11 = test
%----------------------------------------------------------------------

% even number of trials per set size, 48
% 144 trials total for counterbalance
trial_cnt = 1:length(designMatFull);
trial_cnt_shuffled = Shuffle(trial_cnt); % shuffle index 

%trial_orient = randsample(OrientBins(designMatFull(trial_cnt_shuffled,2:5)),1);
trial.setsize = designMatFull(trial_cnt_shuffled,1);


%% ----------------------------------------------------------------------

% now let's convert into the structure the experiment script expects
TrialStuff = [];

for i = 1:length(designMatFull)
    trial.setsize = designMatFull(trial_cnt_shuffled(i),1);
    if  trial.setsize == 1 % set size if full counterbalanced
        trial.orient = randsample(OrientBins(:,(designMatFull(trial_cnt_shuffled(i),2))),1);% orientation is full counterbalanced
        trial.position = designMatFull(trial_cnt_shuffled(i),6); % position is full counterbalanced
        trial.contrast = Contrast(designMatFull(trial_cnt_shuffled(i),7));% contrast is pseudo-balanced
        if designMatFull(trial_cnt_shuffled(i),11) == 1
            trial.test = trial.position;
        elseif designMatFull(trial_cnt_shuffled(i),11) == 2
            trial.test = datasample(setdiff(Quads, trial.position),1);
        end
        if trial.test == trial.position
             trial.testorient = trial.orient;
        else 
             trial.testorient = NaN;
        end
         TrialStuff = [TrialStuff  trial];
    elseif trial.setsize == 2
         trial.orient = [randsample(OrientBins(:,(designMatFull(trial_cnt_shuffled(i),2))),1),randsample(OrientBins(:,(designMatFull(trial_cnt_shuffled(i),3))),1)];
         trial.position = pos(designMatFull(trial_cnt_shuffled(i),6),:);
         trial.contrast = [Contrast(designMatFull(trial_cnt_shuffled(i),7)),Contrast(designMatFull(trial_cnt_shuffled(i),8))];
         if designMatFull(trial_cnt_shuffled(i),11) == 1
            trial.test = datasample(trial.position,1);
        elseif designMatFull(trial_cnt_shuffled(i),11) == 2
            trial.test = datasample(setdiff(Quads, trial.position),1);
        end
         if ismember(trial.test, trial.position) == 1
            j = find(trial.position == trial.test);
            trial.testorient = trial.orient(j);
         else 
            trial.testorient = NaN;
         end
         TrialStuff = [TrialStuff trial];
    elseif trial.setsize == 4
        trial.orient = [randsample(OrientBins(:,(designMatFull(trial_cnt_shuffled(i),2))),1), randsample(OrientBins(:,(designMatFull(trial_cnt_shuffled(i),3))),1), randsample(OrientBins(:,(designMatFull(trial_cnt_shuffled(i),4))),1), randsample(OrientBins(:,(designMatFull(trial_cnt_shuffled(i),5))),1)];
        trial.position = [1 2 3 4]; % position is full counterbalanced
        trial.contrast = [Contrast(designMatFull(trial_cnt_shuffled(i),7)),Contrast(designMatFull(trial_cnt_shuffled(i),8)),Contrast(designMatFull(trial_cnt_shuffled(i),9)), Contrast(designMatFull(trial_cnt_shuffled(i),10))];% contrast is pseudo-balanced
        trial.test = datasample(Quads,1); 
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

% j = [];
%  for i = 1:144
%     j(i) = isnan(TrialStuff(i).testorient);
%  end
% sum(j)

