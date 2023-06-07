%% %%  from RR WM_DistractV2_Main_Practice.m adapted by HK, Sept 2021, for HK Fake Mem 
% make quadrants with center of circles at ~7deg periphery
% 1,2,4 set size conditions 
% addpath(genpath('/Applications/Psychtoolbox'))
% Inputs
% nruns: number of runs to execute sequentially 
% startRun: run number to start with if interrupted (default is 1)

% Stimulus presentation
% 4 rings, 1 in each quadrant, center fixation, center of each ring is 8
% deg periphery, 

% Stimulus categories
% Target: grating stim -> 1, 2, 4 set size, 2 contrast levels
% distractor: noise 
 
 % Experimental design
 % Run duration: ?
 % Block duration: ?
 % Task: orientation detection, full report
%% 
function WM_DistractV5(nruns, startRun)

 %% Prepare and collect basic info
%     
%     
    %Set Paths
    expdir = pwd;
    datadir = 'Data';
    addpath(pwd);
   
    % collect subject info
    info.Name = input('Subject initials: ', 's'); if isempty(info.Name); info.Name = 'tmp'; end % collect subject initials
    %subject.name = deblank((subject.name)); % remove null characters
    SubNum = input('Subject number: ', 's'); if isempty(SubNum); SubNum = '00'; end % collect subject number
    info.SubNum = sprintf('%02d', str2double(SubNum));
    % demographics
    info.Age = input('Subject Age: ', 's'); if isempty(info.Age); info.Age = 'tmp'; end
    info.Gender = input('Gender (M = male, F = female, O = non-binary or other, NR = prefer not to respond):' , 's'); if isempty(info.Gender); info.Gender = 'tmp'; end
    info.Handed = input('Handedness (R = right, L = left, O = other, NR = prefer not to respond):', 's'); if isempty(info.Handed); info.Gender = 'tmp'; end
    
    %get block num
%     currentBlock = input('Block number: ', 's'); if isempty(currentBlock); currentBlock = 1;end
%     currentBlock = str2double(currentBlock);
currentBlock = startRun;
  
    % get time info
    t.MySeed = sum(100*clock); %seeds the random number generator based on the current time
    rand('twister', t.MySeed); %sets random seed
    info.TheDate = datestr(now,'yymmdd'); %Collect todays date (in t.)
    info.TimeStamp = datestr(now,'HHMM'); %Timestamp for saving out a uniquely named datafile (so you will never accidentally overwrite stuff)
    
 
 %% Screen parameters !! 
 Screen('Preference', 'SkipSyncTests', 1);
 Screen('preference','Conservevram', 8192) ;
 Screens = Screen('Screens'); %look at available screens
    %ScreenNr = Screens(end); %pick screen with largest screen number
    ScreenNr = 0; % set to smallest when working with dual monitor setup to have display on laptop
    p.ScreenSizePixels = Screen('Rect', ScreenNr);
    tmprect = get(0, 'ScreenSize');
    computer_res = tmprect(3:4);
    if computer_res(1) ~= p.ScreenSizePixels(3) || computer_res(2) ~= p.ScreenSizePixels(4)
        Screen('CloseAll');clear screen;ShowCursor;
        disp('*** ATTENTION *** screensizes do not match''')
    end
    CenterX = p.ScreenSizePixels(3)/2;
    CenterY = p.ScreenSizePixels(4)/2;
    [width, height] = Screen('DisplaySize', ScreenNr); % this is in mm
    ScreenHeight = height/10; % in cm, ? cm in the scanner?
    ViewDistance = 57; % in cm, ? cm in the scanner!!! (57 cm is the ideal distance where 1 cm equals 1 visual degree)
    VisAngle = (2*atan2(ScreenHeight/2, ViewDistance))*(180/pi); % visual angle of the whole screen
    p.ppd = p.ScreenSizePixels(4)/VisAngle; % pixels per degree visual angle
    p.MyGrey = 132;% ask RR why this grey
    p.fNyquist = 0.5*p.ppd;
    black=BlackIndex(ScreenNr); white=WhiteIndex(ScreenNr);
    gammacorrect = false;
 
%% Initialize data files and open 
cd(datadir); 
    if exist(['WM_DistractV5_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
        load(['WM_DistractV5_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
        runnumber = length(TheData) + 1; % set the number of the current run
        p.startRun = startRun;
        p.nruns = nruns;
        p.TrialNumGlobal = TheData(end).p.TrialNumGlobal;
        p.NumTrials = TheData(end).p.NumTrials;
        p.NumOrientBins = TheData(end).p.NumOrientBins;
        p.OrientBins = TheData(end).p.OrientBins;
        p.Contrast = TheData(end).p.Contrast;
        p.Quads = TheData(end).p.Quads;
        p.SetSize = TheData(end).p.SetSize;
        p.StartTrial = TheData(end).p.TrialNumGlobal+1;
        p.Block = TheData(end).p.Block+1;
        p.designMatFull = TheData(end).p.designMatFull;
        %p.trial_cnt_shuffled = TheData(end).p.trial_cnt_shuffled;
    else
        runnumber = 1; %If no data file exists this must be the first run
        p.Block = runnumber;
        p.TrialNumGlobal = 0;
        p.startRun = startRun; 
        p.nruns = nruns;
        %Experimental params required for counterbalancing
        p.NumOrientBins = 2; %must be multiple of the size of your orientation space (here: 180) 
        %p.OrientBins = reshape(2:2:180,90/p.NumOrientBins,p.NumOrientBins); 
        p.OrientBins = reshape([(82:2:98), (172:2:188)],[], p.NumOrientBins);% 8 deg around meridians
        p.Contrast = [.3 .8];
        p.Quads = [1 2 3 4];
        p.SetSize = [1 2 4];
        [TrialStuff, designMatFull, trial_cnt_shuffled, MinNumTrials] = CounterBalancingActV5(p.OrientBins, p.SetSize, p.Quads, p.Contrast);
        p.designMatFull = designMatFull;
        p.trial_cnt_shuffled = trial_cnt_shuffled;
        p.NumTrials = 18; %NOT TRIVIAL!!! --> must be divisible by MinTrialNum AND by the number of possible iti's (which is 3)
        %currently MinNumTrials is 144, meaning 8 blocks of 18 trials
        
    end
    
    
    cd(expdir); %Back to experiment dir
%% Main Parameters 

%Timing params -- 
    t.PhaseReverseFreq = 4; %in Hz, how often gratings reverse their phase
    t.PhaseReverseTime = 1/t.PhaseReverseFreq;
    t.TargetTime = 2*t.PhaseReverseTime; % 2%must be multiple of t.PhaseReverseTime
    t.DelayTime = 2; %total delay in sec. shortened from 13
    %t.DistractorTime = 44*t.PhaseReverseTime; %must be multiple of t.PhaseReverseTime and be divisible by 4 after subtracting 3 (so (x-3)/4 should be an interture)
    t.DistractorTime = 2;
    t.isi1 = (t.DelayTime-t.DistractorTime)/2; %time between memory stimulus and distractor
    t.isi2 = t.isi1; %time between distractor and recall probe
    t.ResponseTime = 4; 
    t.ActiveTrialDur = t.TargetTime+t.isi1+t.DistractorTime+t.isi2+t.ResponseTime; %non-iti portion of trial
    t.possible_iti = [2 4 6]; % changed from 3 5 8, can maybe do linspace 1-5? for iti jitter
    t.iti = Shuffle(repmat(t.possible_iti,1,p.NumTrials/length(t.possible_iti)));
    t.CueStartsBefore = 1.4; %starts 1 second before the stimulus comes on 
    t.BeginFixation = 3; %16 TRs need to be extra (16trs * .8ms)
    t.EndFixation = 3;
    t.TrialStory = []; %Will be the total story so you can go back and look at all that happened
    
    %Stimulus params (general) 
    p.Smooth_size = round(1*p.ppd); %size of fspecial smoothing kernel 50 or 1
    p.Smooth_sd = round(.5*p.ppd); %smoothing kernel sd 25 or .5
    p.PatchSize = round(2*4*p.ppd);% was 7
    p.OuterDonutRadius = (3*p.ppd)-(p.Smooth_size/2); %Size of donut outsides, automatically defined in pixels.
    p.InnerDonutRadius = (.3*p.ppd)+(p.Smooth_size/2); %Size of donut insides, automatically defined in pixels.
    p.OuterFixRadius = .2*p.ppd; %outer dot radius (in pixels)
    p.InnerFixRadius = p.OuterFixRadius/2; %set to zero if you a donut-hater
    p.FixColor = black;
    p.ResponseLineWidth = 8; % 2 %in pixel 
    p.ResponseLineColor = white;
    
    % Stimulus params quadrants 
    p.Offset = round(4*p.ppd); % offset from fixation in X and Y direction for center of stim quads
    CenterX1 = CenterX + p.Offset; % X center of patch in upper right
    CenterY1 = CenterY - p.Offset; % Y center of patch in upper right
    CenterX2 = CenterX - p.Offset; % X center of patch in upper left
    CenterY2 = CenterY - p.Offset; % Y center of patch in upper left
    CenterX3 = CenterX - p.Offset; % X center of patch in lower left
    CenterY3 = CenterY + p.Offset; % Y center of patch in lower left
    CenterX4 = CenterX + p.Offset; % X center of patch in lower right
    CenterY4 = CenterY + p.Offset; % Y center of patch in lower right
    Centers = {CenterX1, CenterY1; CenterX2, CenterY2; CenterX3, CenterY3; CenterX4, CenterY4};
    
    
    %Stimulus params (specific) 
    p.SF = 2; %spatial frequency in cpd is actally 2
    p.ContrastDistGrating = 0.5; % is actually .5 
    p.ContrastDistNoise = p.ContrastDistGrating;
    p.Noise_f_bandwidth = 2; % is actually 2 frequency of the noise bandwidth
    p.Noise_fLow = p.SF/p.Noise_f_bandwidth; %Noise low spatial frequency cutoff
    p.Noise_fHigh = p.SF*p.Noise_f_bandwidth; %Noise high spatial frequency cutoff
    p.PhaseJitterTarget = randsample(0:359,p.NumTrials,true)*(pi/180);
    p.PhaseJitterDistGrating = NaN(1,p.NumTrials);
    p.TestOrient = randsample(1:180,p.NumTrials);
    
    t.MeantToBeTime = t.BeginFixation + t.ActiveTrialDur*p.NumTrials + sum(t.iti) + t.EndFixation;


%% Make target stimuli
for b = startRun:nruns % block loop
    
% start with a meshgrid
    X=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5; Y=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5;
    [x,y] = meshgrid(X,Y);
    % make a donut with gaussian blurred edge
    donut_out = x.^2 + y.^2 <= (p.OuterDonutRadius)^2;
    donut_in = x.^2 + y.^2 >= (p.InnerDonutRadius)^2;
    donut = donut_out.*donut_in;
    donut = filter2(fspecial('gaussian', p.Smooth_size, p.Smooth_sd), donut);
    % now make a matrix with with all my target stimuli for all my trials
    
    % 5D array - target position, x_size, y_size, numtrials, spatial phase
    % initialize with middle grey (background color), then fill in a
    % 1,2,or 4 gratings as needed for each trial.  
    TargetsAreHere = ones(4,p.PatchSize,p.PatchSize,p.NumTrials,2) * p.MyGrey; %last dimension: 2 phases
    runner = 1; %Will count within-block trials
    
    startTrialThisBlock = (p.NumTrials * runnumber) - p.NumTrials + 1;
    
    for n = startTrialThisBlock:(startTrialThisBlock+p.NumTrials - 1) 
        
        ori_cnt = 1;
        for pos = TrialStuff(n).position
            sine = (sin(p.SF/p.ppd*2*pi*(y.*sin(TrialStuff(n).orient(ori_cnt)*pi/180)+x.*cos(TrialStuff(n).orient(ori_cnt)*pi/180))-p.PhaseJitterTarget(runner)));
            sine2 = (sin(p.SF/p.ppd*2*pi*(y.*sin(TrialStuff(n).orient(ori_cnt)*pi/180)+x.*cos(TrialStuff(n).orient(ori_cnt)*pi/180))-rem(p.PhaseJitterTarget(runner) + pi,2*pi)));
            stim_phase1 = sine.*donut;
            stim_phase2 = sine2.*donut;
            %Give the grating the right contrast level and scale it
            TargetsAreHere(pos,:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(TrialStuff(n).contrast(ori_cnt) * stim_phase1))); 
            TargetsAreHere(pos,:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(TrialStuff(n).contrast(ori_cnt) * stim_phase2)));
            ori_cnt = ori_cnt + 1;
        end
        
        runner = runner + 1;
    end
            
    clear sine stim1_phase1 stim1_phase2 stim2_phase1 stim2_phase2 stim3_phase1 stim3_phase2 stim4_phase1 stim4_phase2 
    
 %% Make distractor stimuli 
 
 % now make a matrix with with all my distractors for all my trials
    DistractorsAreHere = NaN(p.PatchSize,p.PatchSize,p.NumTrials,2); %last dimension: 2 phases
    distractor_sine = (sin(p.SF/p.ppd*2*pi*(y.*sin(0*pi/180)+x.*cos(0*pi/180))));
    sine_contrast = std(distractor_sine(:));
    runner = 1;
    for n = (p.TrialNumGlobal+1):(p.TrialNumGlobal+p.NumTrials)     
            % loop over the four positions
         for i = 1:4
            %Make uniform noise, put it into fourrier space, make sf filer
            noise = rand(p.PatchSize,p.PatchSize)*2-1;
            fn_noise = fftshift(fft2(noise));
            sfFilter = Bandpass2([p.PatchSize p.PatchSize], p.Noise_fLow/p.fNyquist, p.Noise_fHigh/p.fNyquist);
            %Get rid of gibbs ringing artifacts
            smoothfilter = fspecial('gaussian', 10, 4);   % make small gaussian blob
            sfFilter = filter2(smoothfilter, sfFilter); % convolve smoothing blob w/ s.f. filter
            %Bring noise back into real space
            filterednoise = real(ifft2(ifftshift(sfFilter.*fn_noise)));
            %Scale the contrast of the noise back up (it's lost some in the fourier
            %domain) by relating it to the contrast of the grating distractor (before gaussian was applied)
            current_noise_contrast = std(filterednoise(:));
            scaling_factor = sine_contrast/current_noise_contrast;
            filterednoise = filterednoise*scaling_factor;
            %Make it a donut
            filterednoise_phase1 = filterednoise .* donut;
            filterednoise_phase2 = -filterednoise .* donut;
            %Make sure to scale contrast to where it does not get clipped
            DistractorsAreHere(:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastDistNoise * filterednoise_phase1)));
            DistractorsAreHere(:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastDistNoise * filterednoise_phase2)));
   
        end
        runner = runner+1;
    end
    clear x y X Y donut sine sine2 stim_phase1 stim_phase2 filterednoise_phase1 filterednoise_phase2 distractor_sine
    
 %% window setup and gamma correction
 % clock
    PsychJavaTrouble;
    [window] = Screen('OpenWindow',ScreenNr, p.MyGrey,[],[],2);
    t.ifi = Screen('GetFlipInterval',window);
    if gammacorrect
        OriginalCLUT = Screen('LoadClut', window);
        MyCLUT = zeros(256,3); MinLum = 0; MaxLum = 1;
        if strcmp(p.room,'A') % EEG Room
            CalibrationFile = 'LabEEG-05-Jul-2017';
        elseif strcmp(p.room,'B') % Behavior Room B
            CalibrationFile = 'LabB-05-Dec-2017.mat';
        elseif strcmp(p.room,'C') % Behavior Room C
            CalibrationFile = 'LabC-13-Jun-2016.mat';
        elseif strcmp(p.room,'D') % Beahvior room D
            CalibrationFile = 'calibRmD_16-Sep-2016.mat';
        else
            error('No calibration file specified')
        end
        [gamInverse,dacsize] = LoadCalibrationFileRR(CalibrationFile, expdir, GeneralUseScripts);
        LumSteps = linspace(MinLum, MaxLum, 256)';
        MyCLUT(:,:) = repmat(LumSteps, [1 3]);
        MyCLUT = map2map(MyCLUT, repmat(gamInverse(:,4),[1 3])); %Now the screen output luminance per pixel is linear!
        Screen('LoadCLUT', window, MyCLUT);
        clear CalibrationFile gamInverse
    end
    
    HideCursor;
 
  MyPatch1 = [(CenterX1-p.PatchSize/2) (CenterY1-p.PatchSize/2) (CenterX1+p.PatchSize/2) (CenterY1+p.PatchSize/2)];
  MyPatch2 = [(CenterX2-p.PatchSize/2) (CenterY2-p.PatchSize/2) (CenterX2+p.PatchSize/2) (CenterY2+p.PatchSize/2)]; 
  MyPatch3 = [(CenterX3-p.PatchSize/2) (CenterY3-p.PatchSize/2) (CenterX3+p.PatchSize/2) (CenterY3+p.PatchSize/2)];
  MyPatch4 = [(CenterX4-p.PatchSize/2) (CenterY4-p.PatchSize/2) (CenterX4+p.PatchSize/2) (CenterY4+p.PatchSize/2)];
  MyPatch = {MyPatch1 ; MyPatch2; MyPatch3 ; MyPatch4};
%% Welcome and wait for trigger
    %Welcome welcome ya'll

    Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
    % if in fMRI use this->
    %Screen(window,'TextSize',20);
    % Screen('DrawText',window, 'Experimenter press t to go', p.ScreenSizePixels(1)+10, p.ScreenSizePixels(2)+10, white);
    
    % if in behavioral use this ->
    Screen(window,'TextSize',30);
    Screen('DrawText',window, 'Fixate. Press spacebar to begin.', CenterX-200, CenterY-100, black); % change location potentially
    Screen('Flip', window);
    FlushEvents('keyDown'); %First discard all characters from the Event Manager queue.
    ListenChar(2);
    % just sittin' here, waitin' on my trigger...
    while 1
        [keyIsDown, secs, keyCode] = KbCheck([-1]); % KbCheck([-1])
        if keyCode(KbName('space'))
            t.StartTime = GetSecs;
            break; %let's go!
        end
    end
    FlushEvents('keyDown');
    
    GlobalTimer = 0; %this timer keeps track of all the timing in the experiment. TOTAL timing.
    TimeUpdate = t.StartTime; %what time is sit now?
    % present begin fixation
    Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
    Screen('Flip', window);
    %TIMING!:
    GlobalTimer = GlobalTimer + t.BeginFixation;
    TimePassed = 0; %Flush the time the previous event took
    while (TimePassed<t.BeginFixation) %For as long as the cues are on the screen...
        TimePassed = (GetSecs-TimeUpdate);%And determine exactly how much time has passed since the start of the expt.
        if TimePassed>=(t.BeginFixation-t.CueStartsBefore)
            Screen('FillOval', window,  p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
            Screen('Flip', window);
        end
    end
    TimeUpdate = TimeUpdate + t.BeginFixation;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% A TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for n = 1:p.NumTrials
        t.TrialStartTime(n) = GlobalTimer; %Get the starttime of each single block (relative to experiment start)
        TimeUpdate = t.StartTime + t.TrialStartTime(n);
        p.TrialNumGlobal = p.TrialNumGlobal+1;
        
        
        %% Target rendering
   
        for revs = 1:t.TargetTime/t.PhaseReverseTime
            if rem(revs,2)==0 %if this repetition is an even number
                for i = 1:4
                    StimToDraw = Screen('MakeTexture', window, squeeze(TargetsAreHere(i,:,:,n,1))); 
                    Screen('DrawTexture', window, StimToDraw, [], MyPatch{i}, [], 0);
                end
            end
            if rem(revs,2)==1 %if this repetition is an odd number
                
                for i = 1:4
                    StimToDraw = Screen('MakeTexture', window, squeeze(TargetsAreHere(i,:,:,n,2))); 
                    Screen('DrawTexture', window, StimToDraw, [], MyPatch{i}, [], 0);
                end
            end
            
            Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
            Screen('DrawingFinished', window);
            Screen('Flip', window);
            Screen('Close', StimToDraw);
            %TIMING!:
            GlobalTimer = GlobalTimer + t.PhaseReverseTime;
            ReversalTimePassed = 0; %Flush time passed.
            while (ReversalTimePassed<t.PhaseReverseTime) %As long as the stimulus is on the screen...
                ReversalTimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
            end
            TimeUpdate = TimeUpdate + t.PhaseReverseTime; %Update Matlab on what time it is.
        end
        t.TrialStory = [t.TrialStory; {'target'} num2str(t.TargetTime)];
  %% delay 1
        Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window);
        %TIMING!:
        GlobalTimer = GlobalTimer + t.isi1;
        delay1TimePassed = 0; %Flush time passed.
        while (delay1TimePassed<t.isi1) %As long as the stimulus is on the screen...
            delay1TimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
        end
        TimeUpdate = TimeUpdate + t.isi1; %Update Matlab on what time it is.
        t.TrialStory = [t.TrialStory; {'delay 1'} num2str(t.isi1)];
        
        
        %% Distractor
        %if a distractor trial, make textures
        
        DistToDraw1 = Screen('MakeTexture', window, DistractorsAreHere(:,:,n,1,1));
        DistToDraw2 = Screen('MakeTexture', window, DistractorsAreHere(:,:,n,2,1));

        for revs = 1:t.DistractorTime/t.PhaseReverseTime

            if rem(revs,2)==1 %if this repetition is an even number
                for i = 1:4
                    Screen('DrawTexture', window, DistToDraw1, [], MyPatch{i}, [], 0);
                end
            end
            if rem(revs,2)==0 %if this repetition is an odd number
                for i = 1:4
                Screen('DrawTexture', window, DistToDraw2, [], MyPatch{i}, [], 0);
                end 
            end

            Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
            Screen('DrawingFinished', window);
            Screen('Flip', window);
            %TIMING!:
            GlobalTimer = GlobalTimer + t.PhaseReverseTime;
            ReversalTimePassed = 0; %Flush time passed.
            while (ReversalTimePassed<t.PhaseReverseTime) %As long as the stimulus is on the screen...
                ReversalTimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
            end
            TimeUpdate = TimeUpdate + t.PhaseReverseTime; %Update Matlab on what time it is.
        end
        t.TrialStory = [t.TrialStory; {'distractor'} num2str(t.DistractorTime)];
        
        Screen('Close', [DistToDraw1 DistToDraw2]);
    
         
        
        %% delay 2
        Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window);
        %TIMING!:
        GlobalTimer = GlobalTimer + t.isi2;
        delay2TimePassed = 0; %Flush time passed.
        while (delay1TimePassed<t.isi2) %As long as the stimulus is on the screen...
            delay2TimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
        end
        TimeUpdate = TimeUpdate + t.isi2; %Update Matlab on what time it is.
        t.TrialStory = [t.TrialStory; {'delay 2'} num2str(t.isi2)];
        
        
        %% response window
        resp_start = GetSecs;
        % get response in window specified in TrialStuff .test

        i = TrialStuff(n).test;
        test_orient = p.TestOrient(n);
        orient_trajectory = [test_orient];
        InitX = round(abs((p.OuterDonutRadius+p.Smooth_size/2) * sin(test_orient*pi/180)+Centers{i,1}));
        InitY = round(abs((p.OuterDonutRadius+p.Smooth_size/2) * cos(test_orient*pi/180)-Centers{i,2}));
        Screen('BlendFunction', window, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
        Screen('DrawLines', window, [2*Centers{i,1}-InitX, InitX; 2*Centers{i,2}-InitY, InitY], p.ResponseLineWidth, p.ResponseLineColor,[],1);
        Screen('BlendFunction', window, GL_ONE, GL_ZERO);
        Screen('FillOval', window, p.MyGrey, [Centers{i,1}-(p.InnerDonutRadius-p.Smooth_size/2) Centers{i,2}-(p.InnerDonutRadius-p.Smooth_size/2) Centers{i,1}+(p.InnerDonutRadius-p.Smooth_size/2) Centers{i,2}+(p.InnerDonutRadius-p.Smooth_size/2)]);
        Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window,[],1);
        
        GlobalTimer = GlobalTimer + t.ResponseTime;
        RespTimePassed = GetSecs-resp_start; %Flush time passed.

        KbName('UnifyKeyNames'); 
        while RespTimePassed<t.ResponseTime  %As long as no correct answer is identified
            RespTimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            %scanner buttons are: b y g r (form left-to-right)
            if keyCode(KbName('Up')) % b BIG step CCW
                test_orient = rem(test_orient-2+1440,180);
            elseif keyCode(KbName('Left')) % y small step CCW
                test_orient = rem(test_orient-.5+1440,180);
            elseif keyCode(KbName('Right')) % g small step CW
                test_orient = rem(test_orient+.5+1440,180);
            elseif keyCode(KbName('Down')) % r BIG step CW
                test_orient = rem(test_orient+2+1440,180);
            elseif keyCode(KbName('ESCAPE')) % If user presses ESCAPE, exit the program.
                Screen('CloseAll');
                ListenChar(1);
                if exist('OriginalCLUT','var')
                    if exist('ScreenNr','var')
                        Screen('LoadCLUT', ScreenNr, OriginalCLUT);
                    else
                        Screen('LoadCLUT', 0, OriginalCLUT);
                    end
                end
                error('User exited program.');
            end
                test_orient(test_orient==0)=180;
                orient_trajectory = [orient_trajectory test_orient];
                UpdatedX = round(abs((p.OuterDonutRadius+p.Smooth_size/2) * sin(test_orient*pi/180)+Centers{i,1}));
                UpdatedY = round(abs((p.OuterDonutRadius+p.Smooth_size/2) * cos(test_orient*pi/180)-Centers{i,2}));
                Screen('BlendFunction', window, GL_ONE, GL_ZERO);
                Screen('FillRect', window, p.MyGrey);
                Screen('BlendFunction', window, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
                Screen('DrawLines', window, [2*Centers{i,1}-UpdatedX, UpdatedX; 2*Centers{i,2}-UpdatedY, UpdatedY], p.ResponseLineWidth, p.ResponseLineColor, [], 1);
                Screen('BlendFunction', window, GL_ONE, GL_ZERO);
                Screen('FillOval', window, p.MyGrey, [Centers{i,1}-(p.InnerDonutRadius-p.Smooth_size/2) Centers{i,2}-(p.InnerDonutRadius-p.Smooth_size/2) Centers{i,1}+(p.InnerDonutRadius-p.Smooth_size/2) Centers{i,2}+(p.InnerDonutRadius-p.Smooth_size/2)]);        
                Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius]);
                Screen('Flip', window, [], 1,[], []);
        end
        FlushEvents('keyDown'); %First discard all characters from the Event Manager queue
        data.Response(n) = test_orient;
        %make note of non-response
        if data.Response(n) == p.TestOrient(n)
            data.Response(n) = NaN;
        end
        TimeUpdate = TimeUpdate + t.ResponseTime; %Update Matlab on what time it is.
        t.TrialStory = [t.TrialStory; {'response'} num2str(t.ResponseTime)];

        
        %% iti
        Screen('FillRect',window,p.MyGrey);
        Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window);
        %TIMING!:
        GlobalTimer = GlobalTimer + t.iti(n);
        TimePassed = 0; %Flush time passed.
        while (TimePassed<t.iti(n)) %As long as the stimulus is on the screen...
            TimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
            if TimePassed>=(t.iti(n)-t.CueStartsBefore)
                Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
                Screen('Flip', window);
            end
        end
        TimeUpdate = TimeUpdate + t.iti(n); %Update Matlab on what time it is.
        t.TrialStory = [t.TrialStory; {'iti'} num2str(t.iti(n))];
        Trajectory{n} = orient_trajectory;
        
    end %end of experimental trial/block loop
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%% END OF TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %----------------------------------------------------------------------
    %LOOK AT BEHAVIORAL PERFOPRMANCE---------------------------------------
    %----------------------------------------------------------------------
    startTrialThisBlock = (p.NumTrials * runnumber) - p.NumTrials + 1;
    targets_were = [TrialStuff(startTrialThisBlock:p.TrialNumGlobal).testorient];
    % need to filter NaNs
    acc(1,:) = abs(targets_were-data.Response);
    acc(2,:) = abs((360-(acc(1,:)*2))/2); 
    acc(3,:) = 360-(acc(1,:));
    acc = min(acc); 
    %Add minus signs back in
    acc(mod(targets_were-acc,360)==data.Response)=-acc(mod(targets_were-acc,360)==data.Response);
    acc(mod((targets_were+180)-acc,360)==data.Response)=-acc(mod((targets_were+180)-acc,360)==data.Response);
    data.Accuracy = acc;
    % exclude NaNs
    data.Accuracyfeedback = data.Accuracy(~isnan(data.Accuracy));
    %figure;hist(data.Accuracy,-90:1:90); set(gca,'XLim',[-90 90],'XTick',[-90:45:90]);
    %title(['Mean accuracy was ' num2str(mean(abs(data.Accuracyfeedback))) ' degrees'],'FontSize',16)
    % of the times there was a memory item here is the accuracy
    accStr = ['Mean accuracy was ' num2str(mean(abs(data.Accuracyfeedback))) ' degrees']; 
    
    % final fixation and feedback:
    Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
    Screen('Flip', window);
    blockStr = ['Finished block ' num2str(runnumber) ' out of 8'];
    feedbackStr = [blockStr sprintf('\n') accStr sprintf('\n') 'Press the spacebar to continue'];
    % may need to change spacing
    DrawFormattedText(window,[feedbackStr],CenterX-200,CenterY,white);
    Screen('Flip',window);
    
    while 1
            [keyIsDown, secs, keyCode] = KbCheck([-1]); % KbCheck([-1])
            if keyCode(KbName('space'))
                break; %next block
            end
        end
        FlushEvents('keyDown');
    
    
     GlobalTimer = GlobalTimer + t.EndFixation;
     
    closingtime = 0; resp = 0;
    
    while closingtime < t.EndFixation
        closingtime = GetSecs-TimeUpdate;
        ListenChar(1); %Unsuppressed keyboard mode
        if CharAvail
            [press] = GetChar;
            if strcmp(press,'1')
                resp = str2double(press);
            end
        end
    end
    t.EndTime = GetSecs; %Get endtime of the experiment in seconds
    t.TotalExpTime = (t.EndTime-t.StartTime); %Gets the duration of the total run.
    t.TotalExpTimeMins = t.TotalExpTime/60; %TOTAL exp time in mins including begin and end fixation.
    t.GlobalTimer = GlobalTimer; %Spits out the exp time in secs excluding begin and end fixation.
    
      %----------------------------------------------------------------------
    %SAVE OUT THE DATA-----------------------------------------------------
    %----------------------------------------------------------------------
    cd(datadir); %Change the working directory back to the experimental directory
    if exist(['WM_DistractV5_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
        load(['WM_DistractV5_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
    end
    %First I make a list of variables to save:
    TheData(runnumber).info = info;
    TheData(runnumber).t = t;
    TheData(runnumber).p = p;
    TheData(runnumber).data = data;
    TheData(runnumber).trajectory = Trajectory;
    eval(['save(''WM_DistractV5_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
    cd(expdir)
    
    FlushEvents('keyDown'); 
    
    runnumber = runnumber+1;
end  % end of block loop
    %----------------------------------------------------------------------
    %WINDOW CLEANUP--------------------------------------------------------
    %----------------------------------------------------------------------
    %This closes all visible and invisible screens and puts the mouse cursor
    %back on the screen
    Screen('CloseAll');
    if exist('OriginalCLUT','var')
        if exist('ScreenNr','var')
            Screen('LoadCLUT', ScreenNr, OriginalCLUT);
        else
            Screen('LoadCLUT', 0, OriginalCLUT);
        end
    end
    clear screen
    ListenChar(1);
    ShowCursor;

    

       
end
