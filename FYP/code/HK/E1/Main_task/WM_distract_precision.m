%%  from RR WM_DistractV2_Main_Practice.m adapted by HK, Sept 2021, for FYP exp 1 does noise boost precision
%
% progress: made compatible with apple Big Sur on M1 - check
% get rid of grating distractor, we only want noise distractor - IP
% get rid of color cue, we don't want to cue the distractor 
% make quadrants with center of circles at 7deg periphery
% 3 contrast conditions?
%%
  %----------------------------------------------------------------------
    %PREPARE AND COLLECT BASIC INFO----------------------------------------
    %----------------------------------------------------------------------
    echo off
    clear all
    close all hidden
    
    %Get path info
    expdir = pwd;
    datadir = 'Data';
    addpath(pwd); %To ensure I can find my counterbalancing function (make sure it's in the same path)
    
    %PTB shoul always be on path, but just to be sure
    %addpath('/Applications/Psychtoolbox');
    
    %Get user info
    Subject = 'S01';
    info.Name = input('Initials? (default is temp) --> ','s'); if isempty(info.Name); info.Name = 'tmp'; end %Collect subject initials
    SubNum = input('Subject number? (default is "0") --> ','s'); if isempty(SubNum); SubNum = '00'; end % collect subject number
    info.SubNum = sprintf('%02d', str2num(SubNum));
    if ~strcmp(Subject,['S' info.SubNum]); disp('Subject name doesn''t match name in script, please check and try again'); return; end;
    
    %Get timing info
    t.MySeed = sum(100*clock); %seeds the random number generator based on the current time
    rand('twister', t.MySeed); %sets random seed
    info.TheDate = datestr(now,'yymmdd'); %Collect todays date (in t.)
    info.TimeStamp = datestr(now,'HHMM'); %Timestamp for saving out a uniquely named datafile (so you will never accidentally overwrite stuff)
    
%% 
    
    %----------------------------------------------------------------------
    %SCREEN PARAMETERS-----------------------------------------------------
    %----------------------------------------------------------------------
    Screen('preference','Conservevram', 8192) % added this based on PTB online discourse, this ruins timing according to MK, find a better fix before experiment
    Screens = Screen('Screens'); %look at available screens
    ScreenNr = Screens(1); % pick screen with largest screen number
    p.ScreenSizePixels = Screen('Rect', ScreenNr);
    tmprect = get(0, 'ScreenSize'); %
    computer_res = tmprect(3:4);
    if computer_res(1) ~= p.ScreenSizePixels(3) || computer_res(2) ~= p.ScreenSizePixels(4)
        Screen('CloseAll');clear screen;ShowCursor;
        disp('*** ATTENTION! *** Screensize does not match''')
    end
    CenterX = p.ScreenSizePixels(3)/2;
    CenterY = p.ScreenSizePixels(4)/2;
    ScreenHeight = 18; % in cm, 
    ViewDistance = 57; % in cm, 57 cm is ideal distance where 1 cm equals 1 visual degree
    VisAngle = (2*atan2(ScreenHeight/2, ViewDistance))*(180/pi); % visual angle of the whole screen
    p.ppd = p.ScreenSizePixels(4)/VisAngle; % pixels per degree visual angle
    p.MyGrey = 128;
    p.fNyquist = 0.5*p.ppd;
    black=BlackIndex(ScreenNr); white=WhiteIndex(ScreenNr);
    gammacorrect = false;
 %%
  %----------------------------------------------------------------------
    %OPEN/INIT DATA FILES--------------------------------------------------
    %----------------------------------------------------------------------
    cd(datadir); 
    if exist(['WM_DistractV2_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_MainPractice.mat']);
        load(['WM_DistractV2_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_MainPractice.mat']);
        runnumber = length(TheData) + 1; % set the number of the current run
        p.TrialNumGlobal = TheData(end).p.TrialNumGlobal;
        p.NumTrials = TheData(end).p.NumTrials;
        p.NumOrientBins = TheData(end).p.NumOrientBins;
        p.OrientBins = TheData(end).p.OrientBins;
        p.DistType = TheData(end).p.DistType;
        p.DistTypeNames = TheData(end).p.DistTypeNames;
        p.CueColors = TheData(end).p.CueColors;
    else
        runnumber = 1; %If no data file exists this must be the first run
        p.TrialNumGlobal = 0;
        %Experimental params required for counterbalancing
        p.NumOrientBins = 2; %must be multiple of the size of your orientation space (here: 180)
        p.OrientBins = reshape(1:180,180/p.NumOrientBins,p.NumOrientBins);
        p.DistType = [0 1];% removed 2 - which was grating
        p.DistTypeNames = {'none';'noise'};% removed grating option
        [TrialStuff, MinNumTrials] = CounterBalancingActV2(p.DistType, p.DistTypeNames, p.OrientBins);
        p.NumTrials = 6; %NOT TRIVIAL!!! --> must be divisible by MinTrialNum AND by the number of possible iti's (which is 3)
        %For the practice, MinTrialNum is 12. Running 6 trial blocks thus means
        %that 2 blocks need to be ran for one full counterbalancing act
        % Question: what is the counterbalancing and we don't want cue
        % colors right so we don't need this?
        %    have to run counterbalancingactv2 script to make CueColorsV2.mat
        %load('CueColorsV2.mat'); %6 subjects needed to fully between-subject counterbalance the cue colors
        %p.CueColors = CueColors((rem(str2num(info.SubNum)-1,length(CueColors)))+1);
    end
    cd(expdir); %Back to main_task dir
 %%
 %----------------------------------------------------------------------
    %DEFINE MAIN PARAMETERS------------------------------------------------
    %----------------------------------------------------------------------
    
    %Timing params
    t.PhaseReverseFreq = 4; %in Hz, how often gratings reverse their phase
    t.PhaseReverseTime = 1/t.PhaseReverseFreq;
    t.TargetTime = 2*t.PhaseReverseTime; %must be multiple of t.PhaseReverseTime
    t.DelayTime = 13; %total delay in sec.
    t.DistractorTime = 44*t.PhaseReverseTime; %must be multiple of t.PhaseReverseTime and be divisible by 4 after subtracting 3 (so (x-3)/4 should be an interture)
    t.isi1 = (t.DelayTime-t.DistractorTime)/2; %time between memory stimulus and distractor
    t.isi2 = t.isi1; %time between distractor and recall probe
    t.ResponseTime = 3;
    t.ActiveTrialDur = t.TargetTime+t.isi1+t.DistractorTime+t.isi2+t.ResponseTime; %non-iti portion of trial
    t.possible_iti = [3 5 8]; 
    t.iti = Shuffle(repmat(t.possible_iti,1,p.NumTrials/length(t.possible_iti)));
    t.CueStartsBefore = 1.4; %starts 1 second before the stimulus comes on 
    t.BeginFixation = 8;
    t.EndFixation = 0;
    t.TrialStory = []; %Will be the total story so you can go back and look at all that happened
    
    %Stimulus params (general)
    p.Smooth_size = round(1*p.ppd); %size of fspecial smoothing kernel
    p.Smooth_sd = round(.5*p.ppd); %smoothing kernel sd
    p.PatchSize = round(2*7*p.ppd); %Size of the patch that is drawn on screen location, so twice the radius, in pixels
    p.OuterDonutRadius = (7*p.ppd)-(p.Smooth_size/2); %Size of donut outsides, automatically defined in pixels.
    p.InnerDonutRadius = (1.5*p.ppd)+(p.Smooth_size/2); %Size of donut insides, automatically defined in pixels.
    p.OuterFixRadius = .2*p.ppd; %outer dot radius (in pixels)
    p.InnerFixRadius = p.OuterFixRadius/2; %set to zero if you a donut-hater
    p.FixColor = black;
    p.ResponseLineWidth = 2; %in pixel
    p.ResponseLineColor = white;
    
    %Stimulus params (specific)
    p.SF = 2; %spatial frequency in cpd
    p.ContrastTarget = 1;
    p.ContrastDistGrating = .5;
    p.ContrastDistNoise = p.ContrastDistGrating;
    p.Noise_f_bandwidth = 2; %frequency of the noise bandwidth
    p.Noise_fLow = p.SF/p.Noise_f_bandwidth; %Noise low spatial frequency cutoff
    p.Noise_fHigh = p.SF*p.Noise_f_bandwidth; %Noise high spatial frequency cutoff
    p.PhaseJitterTarget = randsample(0:359,p.NumTrials,true)*(pi/180);
    p.PhaseJitterDistGrating = NaN(1,p.NumTrials);
    p.TestOrient = randsample(1:180,p.NumTrials);
    
    t.MeantToBeTime = t.BeginFixation + t.ActiveTrialDur*p.NumTrials + sum(t.iti) + t.EndFixation;

  %----------------------------------------------------------------------
    %MAKE THE TARGET STIMULI-----------------------------------------------
    %----------------------------------------------------------------------
    % start with a meshgrid
    X=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5; Y=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5;
    [x,y] = meshgrid(X,Y);
    % make a donut with gaussian blurred edge
    donut_out = x.^2 + y.^2 <= (p.OuterDonutRadius)^2;
    donut_in = x.^2 + y.^2 >= (p.InnerDonutRadius)^2;
    donut = donut_out.*donut_in;
    donut = filter2(fspecial('gaussian', p.Smooth_size, p.Smooth_sd), donut);
    % now make a matrix with with all my target stimuli for all my trials
    TargetsAreHere = NaN(p.PatchSize,p.PatchSize,p.NumTrials,2); %last dimension: 2 phases
    runner = 1; %Will count within-block trials
    for n = (p.TrialNumGlobal+1):(p.TrialNumGlobal+p.NumTrials)
        sine = (sin(p.SF/p.ppd*2*pi*(y.*sin(TrialStuff(n).orient*pi/180)+x.*cos(TrialStuff(n).orient*pi/180))-p.PhaseJitterTarget(runner)));
        sine2 = (sin(p.SF/p.ppd*2*pi*(y.*sin(TrialStuff(n).orient*pi/180)+x.*cos(TrialStuff(n).orient*pi/180))-rem(p.PhaseJitterTarget(runner) + pi,2*pi)));
        stim_phase1 = sine.*donut;
        stim_phase2 = sine2.*donut;
        %Give the grating the right contrast level and scale it
        TargetsAreHere(:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase1)));
        TargetsAreHere(:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase2)));
        runner = runner+1;
    end
    clear sine stim_phase1 stim_phase2
 