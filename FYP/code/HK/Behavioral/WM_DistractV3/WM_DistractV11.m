%% %%  from RR WM_DistractV2_Main_Practice.m adapted by HK, 2021-2022, for HK Sherlock
% addpath(genpath('/Applications/Psychtoolbox'))
% Inputs
% nruns: number of runs to execute sequentially 
% startRun: run number to start with if interrupted (default is 1)

% Stimulus categories
% Target: gabor orientation w/noise - set size 1 and 2 + noise masks 
% distractor: dynamic noise - 2 contrast levels
 
 % Experimental design
 % Run duration: 8.6mins
 % Block duration: 68.8 mins
 % Task: orientation detection, 4 AFC and 3 level confidence report
%% 
function WM_DistractV11(p, info, nruns, startRun)

 %% Prepare and collect basic info
    
    %Set Paths
    expdir = pwd;
    datadir = 'Data';
    addpath(pwd);
 
    % set the random seed
    rng('default')
    rng('shuffle')
    t.MySeed = rng; % Save the random seed settings!!
    
    % get time info
    info.TheDate = datestr(now,'yymmdd'); %Collect todays date (in t.)
    info.TimeStamp = datestr(now,'HHMM'); %Timestamp for saving out a uniquely named datafile (so you will never accidentally overwrite stuff)
    
 
 %% Screen parameters !! 
 Screen('Preference', 'SkipSyncTests', 1);
 Screen('preference','Conservevram', 8192);
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
    if exist(['WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
        load(['WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
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
        p.trial_cnt_shuffled = TheData(end).p.trial_cnt_shuffled;
    else
        runnumber = 1; %If no data file exists this must be the first run
        p.Block = runnumber;
        p.TrialNumGlobal = 0;
        p.startRun = startRun; 
        p.nruns = nruns;
        %Experimental params required for counterbalancing
        p.NumOrientBins = 2; %must be multiple of the size of your orientation space (here: 180) 
        p.OrientBins = reshape([(4:2:22), (338:2:356), (94:2:112), (68:2:86)],[], p.NumOrientBins);
        p.Contrast = [.5 .8];
        p.Quads = [1 2 3 4];
        p.SetSize = [1 2];
        [TrialStuff, designMatFull, trial_cnt_shuffled, MinNumTrials] = CounterBalancingActV8(p.OrientBins, p.SetSize, p.Quads, p.Contrast);
        p.designMatFull = designMatFull;
        p.trial_cnt_shuffled = trial_cnt_shuffled;
        p.NumTrials = 24; %NOT TRIVIAL!!! --> must be divisible by MinTrialNum AND by the number of possible iti's (which is 3)
        %currently MinNumTrials is 192, meaning 8 blocks of 24 trials
        
    end
   
    cd(expdir); %Back to experiment dir
%% Main Parameters 

%Timing params -- 
    t.TargetTime = 0.2;%0.2;%2*t.PhaseReverseTime; %must be multiple of t.PhaseReverseTime is actually 2
    t.DistractorTime = 2; %20*t.PhaseReverseTime; % 2 seconds
    t.DelayTime = 0.05;%0.5*t.PhaseReverseTime; %total delay in sec
    t.isi1 = t.DelayTime; %time between memory stimulus and distractor
    t.isi2 = 0; %time between distractor and recall probe
    t.ResponseTime = 3;
    t.ConfidenceTime = 2;
    t.ActiveTrialDur = t.TargetTime+t.isi1+t.DistractorTime+t.isi2+t.ResponseTime; %non-iti portion of trial
    t.possible_iti = [2 4 6]; % changed from 3 5 8, can maybe do linspace 1-5? for iti jitter
    t.iti = Shuffle(repmat(t.possible_iti,1,p.NumTrials/length(t.possible_iti)));
    t.CueStartsBefore = 1; %starts 1 second before the stimulus comes on 
    t.BeginFixation = 3; %16 TRs need to be extra (16trs * .8ms)
    t.EndFixation = 3;
    t.TrialStory = []; %Will be the total story so you can go back and look at all that happened
    
    %Stimulus params (general) 
    p.Smooth_size = round(1*p.ppd); %size of fspecial smoothing kernel 50 or 1
    p.Smooth_sd = round(.5*p.ppd); %smoothing kernel sd 25 or .5
    p.PatchSize = round(2*4*p.ppd);% was 7
    p.DiscRadius = (3*p.ppd)-(p.Smooth_size/2); %Size of disc outsides, automatically defined in pixels.
    p.FixRadius = .2*p.ppd; % dot radius (in pixels)
    p.FixColor = black;
    p.ResponseLineWidth = 2; %in pixel 
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

    %Stimulus params (specific) 
    p.SF = 2; %spatial frequency in cpd is actally 2
    p.ContrastTarget = .3;%0.3; % is actually .3
    p.MaskContrast = .3;%0.3; % maybe decrease this
    p.Noise_f_bandwidth = 2;%2; % is actually 2 frequency of the noise bandwidth
    p.Noise_fLow = p.SF/p.Noise_f_bandwidth; %Noise low spatial frequency cutoff
    p.Noise_fHigh = p.SF*p.Noise_f_bandwidth; %Noise high spatial frequency cutoff
    p.PhaseJitterTarget = randsample(0:359,p.NumTrials,true)*(pi/180);
    t.MeantToBeTime = t.BeginFixation + t.ActiveTrialDur*p.NumTrials + sum(t.iti) + t.EndFixation;


%% Make target stimuli
for b = startRun:nruns % block loop
    
% start with a meshgrid
    X=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5; Y=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5;
    [x,y] = meshgrid(X,Y);
    % make a disc with gaussian blurred edge
    disc_out = x.^2 + y.^2 <= (p.DiscRadius)^2;
    disc = filter2(fspecial('gaussian', p.Smooth_size, p.Smooth_sd), disc_out);
    
    % make masks
    mask_sine = (sin(p.SF/p.ppd*2*pi*(y.*sin(0*pi/180)+x.*cos(0*pi/180))));
    sine_maskcontrast = std(mask_sine(:));
    % now make a matrix with with all my target stimuli for all my trials
    
    % 4D array - target position, x_size, y_size, numtrials
    % initialize with middle grey (background color), then fill in a
    % 1 or 2 as needed for each trial.  
    TargetsAreHere = ones(4,p.PatchSize,p.PatchSize,p.NumTrials) * p.MyGrey; 
    MasksAreHere = ones(4,p.PatchSize,p.PatchSize,p.NumTrials) * p.MyGrey;
    runner = 1; %Will count within-block trials
    
    startTrialThisBlock = (p.NumTrials * runnumber) - p.NumTrials + 1;
    
    for n = startTrialThisBlock:(startTrialThisBlock+p.NumTrials - 1) 
        
        ori_cnt = 1;
        for pos = TrialStuff(n).position
            % create grating
            sine = (sin(p.SF/p.ppd*2*pi*(y.*sin(TrialStuff(n).orient(ori_cnt)*pi/180)+x.*cos(TrialStuff(n).orient(ori_cnt)*pi/180))-p.PhaseJitterTarget(runner)));
            stim_phase = sine.*disc;
            %Give the grating the right contrast level and scale it
            TargetsAreHere(pos,:,:,runner) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase))); 
  
              ori_cnt = ori_cnt + 1;
              
            % Create noise to add with alpha blending
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
            scaling_factor = sine_maskcontrast/current_noise_contrast;
            filterednoise = filterednoise*scaling_factor;
            %Make it a disc
            filterednoise_phase = filterednoise .* disc;
            MasksAreHere(pos,:,:,runner) = max(0,min(255,p.MyGrey+p.MyGrey*(p.MaskContrast * filterednoise_phase)));
        end
        
        for pos = setdiff([1,2,3,4],TrialStuff(n).position)
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
            scaling_factor = sine_maskcontrast/current_noise_contrast;
            filterednoise = filterednoise*scaling_factor;
            %Make it a disc
            filterednoise_phase = filterednoise .* disc;
            %Make sure to scale contrast to where it does not get clipped
            TargetsAreHere(pos,:,:,runner) = max(0,min(255,p.MyGrey+p.MyGrey*(p.MaskContrast * filterednoise_phase)));
        end
        
        runner = runner + 1;
    end
            
    clear sine stim_phase 
    
 
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

    Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
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
    KbName('UnifyKeyNames');
    while 1
        [keyIsDown, secs, keyCode] = KbCheck([-1]); % KbCheck([-1])
        if keyCode(KbName('space'))
            t.StartTime = GetSecs;
            break; %let's go!
        end
    end
    FlushEvents('keyDown');
    
    GlobalTimer = 0; %this timer keeps track of all the timing in the experiment. TOTAL timing.
    TimeUpdate = t.StartTime; %what time is it now?
    % present begin fixation
    Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
    Screen('Flip', window);
    %TIMING!:
    GlobalTimer = GlobalTimer + t.BeginFixation;
    TimePassed = 0; %Flush the time the previous event took
    while (TimePassed<t.BeginFixation) %For as long as the cues are on the screen...
        TimePassed = (GetSecs-TimeUpdate);%And determine exactly how much time has passed since the start of the expt.
        if TimePassed>=(t.BeginFixation-t.CueStartsBefore)
            Screen('FillOval', window,  p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
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
          Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % add transparency with alpha blending
            for i = 1:4
                % draw targets and noise masks
                StimToDraw = Screen('MakeTexture', window, squeeze(TargetsAreHere(i,:,:,n))); % draw target
                Screen('DrawTexture', window, StimToDraw, [], MyPatch{i}, [], 0,1); % alpha = 1
                % draw noise mask on target
                MaskToDraw = Screen('MakeTexture', window, squeeze(MasksAreHere(i,:,:,n)));% draw noise
                Screen('DrawTexture', window, MaskToDraw, [], MyPatch{i}, [], 0, 0.5); % alpha = 0.5
            end

            Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
            Screen('DrawingFinished', window);
            Screen('Flip', window);
            
            %Screen('BlendFunction', window, 'GL_DST_ALPHA','GL_ONE_MINUS_DST_ALPHA'); don't know what this does
            %TIMING!:
            GlobalTimer = GlobalTimer + t.TargetTime;
            TargetTimePassed = 0; %Flush time passed.
            while (TargetTimePassed<t.TargetTime) %As long as the stimulus is on the screen...
                TargetTimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
            end
            TimeUpdate = TimeUpdate + t.TargetTime; %Update Matlab on what time it is.
            Screen('Close', StimToDraw);
            Screen('Close', MaskToDraw);
      
        t.TrialStory = [t.TrialStory; {'target'} num2str(t.TargetTime)];
clear i
         %% delay 1
        Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
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
       % make dynamic distractors and display
       % make distractors
       distractor_n = 10; % flip through 10, each one gets seen for 0.2 sec same as target display
  
       % start with a meshgrid
    X=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5; Y=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5;
    [x,y] = meshgrid(X,Y);
    % make a disc with gaussian blurred edge
    disc_out = x.^2 + y.^2 <= (p.DiscRadius)^2;
    disc = filter2(fspecial('gaussian', p.Smooth_size, p.Smooth_sd), disc_out);
    
 % now make a matrix with with all my distractors for all my trials
    DistractorsAreHere = NaN(p.PatchSize,p.PatchSize,distractor_n); %last dimension: 2 phases
    distractor_sine = (sin(p.SF/p.ppd*2*pi*(y.*sin(0*pi/180)+x.*cos(0*pi/180))));
    sine_contrast = std(distractor_sine(:));
    runner = 1;
    for num = 1:distractor_n
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
            %Make it a disc
            filterednoise_phase = filterednoise .* disc;
            %Make sure to scale contrast to where it does not get clipped
            DistractorsAreHere(:,:,runner) = max(0,min(255,p.MyGrey+p.MyGrey*(TrialStuff(p.TrialNumGlobal).contrast * filterednoise_phase)));
        
         end
        runner = runner+1;
    end
    clear i x y X Y disc sine sine2 stim_phase1 stim_phase2 filterednoise_phase1 filterednoise_phase2 distractor_sine
    
       
       %TIMING!:
            DistractorTimePassed = 0; %Flush time passed.
       % display loop for dynamic noise
       while (DistractorTimePassed < t.DistractorTime)
           DistractorTimePassed = (GetSecs-TimeUpdate);
           
           for d = 1:distractor_n
               for i = 1:4
                   DistToDraw = Screen('MakeTexture', window, DistractorsAreHere(:,:,d,1));
                   Screen('DrawTexture', window, DistToDraw, [], MyPatch{i}, [], 0);
               end
           
                Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
                Screen('DrawingFinished', window);
                Screen('Flip', window);
            
           end
            
       end
        TimeUpdate = TimeUpdate + t.DistractorTime;
        GlobalTimer = GlobalTimer + t.DistractorTime;
        t.TrialStory = [t.TrialStory; {'distractor'} num2str(t.DistractorTime)];
        
        Screen('Close', [DistToDraw]);
clear i d
%% response window
% get RT
%%%%% 4 AFC and then 3 level confidence rating

% get response to window specified in TrialStuff .test
i = TrialStuff(p.TrialNumGlobal).test; % the quadrant number to probe

 % make an arrow pointing to quad number i        
    Arrows = {-50, 50;50, 50;50, -50;-50, -50};
    head = [CenterX-Arrows{i,1},CenterY-Arrows{i,2}];
    width  = 20;           % width of arrow head
       if i == 1
        points = [head; head+[0,width]; head-[width,0]];
       elseif i == 2
        points = [head; head+[0,width]; head+[width,0]];
       elseif i == 3
        points = [head; head-[0,width]; head+[width,0]];
       elseif i == 4
        points = [head; head-[0,width]; head-[width,0]];
       end
         
        Screen('FillPoly', window,p.ResponseLineColor, points,[]); % makes a triangle
        Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window,[],1);
        
        resp_start = GetSecs;
        GlobalTimer = GlobalTimer + t.ResponseTime;
        RespTimePassed = GetSecs-resp_start; %Flush time passed.

    
        KbName('UnifyKeyNames');

        nResponsesMade = 0;
        responseHolder = NaN(1,1500);
        resp = 0;
        responseKeysSoFar= [];
        react = 0;
       
         while RespTimePassed<t.ResponseTime  %As long as no correct answer is identified

            RespTimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            %scanner buttons are: b y g r (form left-to-right)
          if sum(keyCode)==1
            %if keyCode(KbName('Up')) % b CCW from vertical
            if keyCode(KbName('UpArrow'))
                resp = 1;%'CCW v'
                react = secs - resp_start;
            %elseif keyCode(KbName('Left')) % y CCW from horizontal
            elseif keyCode(KbName('LeftArrow'))
                resp = 2;%'CCW h';
                react = secs - resp_start;
            %elseif keyCode(KbName('Right')) % g CW from horizontal
            elseif keyCode(KbName('RightArrow'))
                resp = 3;%'CW h';
                react = secs - resp_start;
            %elseif keyCode(KbName('Down')) % r CW from vertical
            elseif keyCode(KbName('DownArrow'))
                resp = 4;%'CW v';
                react = secs - resp_start;
            elseif keyCode(KbName('ESCAPE')) % If user presses ESCAPE, exit the program.
                %SAVE data progress
                cd(datadir); %Change the working directory back to the experimental directory
                if exist(['WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
                    load(['WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
                end
                %First I make a list of variables to save:
                TheData(runnumber).info = info;
                TheData(runnumber).t = t;
                TheData(runnumber).p = p;
                TheData(runnumber).data = data;
                eval(['save(''WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
                cd(expdir)
                
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
          elseif sum(keyCode) > 1
              resp=5;
          end
            % If they pressed one of the keys we are looking for, save what
            % key they pushed in our placeholder
            if resp > 0
                nResponsesMade = nResponsesMade + 1;
                if nResponsesMade <= 1500
                    responseHolder(nResponsesMade) = resp;
                end
            end
         end
         
         if sum(ismember(responseHolder,5))>0
             newResp = 5;
         else
             newResp = unique(responseHolder);
         end
                if isempty(responseKeysSoFar)
                    responseKeysSoFar = newResp;
                elseif ~ismember(responseKeysSoFar, newResp)
                    responseKeysSoFar = [responseKeysSoFar, newResp];
                end
        FlushEvents('keyDown'); %First discard all characters from the Event Manager queue
        

        if nResponsesMade > 0
            if length(responseKeysSoFar) == 1
                data.Response(n) = responseKeysSoFar;
                data.RTresp(n) = react;
            elseif length(responseKeysSoFar)>1
                data.Response(n) = 5;
                data.RTresp(n) = react;
            end
        else
            data.Response(n) = NaN;
            data.RTresp(n) = react;
        end
       
        TimeUpdate = TimeUpdate + t.ResponseTime; %Update Matlab on what time it is.
        t.TrialStory = [t.TrialStory; {'response'} num2str(t.ResponseTime)]; % save response time

        %% confidence rating
        % save RT !!
        
        
        confStr = 'How confident: Low Medium High';
       
        Screen('FillRect',window,p.MyGrey);
        DrawFormattedText(window,[confStr],CenterX-180,CenterY-50,white);
        Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window);
        
        conf_start = GetSecs;
         GlobalTimer = GlobalTimer + t.ConfidenceTime;
         RespTimePassed = GetSecs-conf_start;
        react = 0;
         while RespTimePassed<t.ConfidenceTime  %As long as no correct answer is identified
            RespTimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            %scanner buttons are: b y g r (form left-to-right)
            %if keyCode(KbName('Left')) % low confidence
            if keyCode(KbName('LeftArrow'))
                conf = 1;
                react = secs - conf_start;
            %elseif keyCode(KbName('Down')) % medium confidence
            elseif keyCode(KbName('DownArrow'))
                conf = 2;
                react = secs - conf_start;
            %elseif keyCode(KbName('Right')) % high confidence
            elseif keyCode(KbName('RightArrow'))
                conf = 3;
                react = secs - conf_start;
            elseif keyCode(KbName('ESCAPE')) % If user presses ESCAPE, exit the program.
                %SAVE data progress
                cd(datadir); %Change the working directory back to the experimental directory
                if exist(['WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
                    load(['WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
                end
                %First I make a list of variables to save:
                TheData(runnumber).info = info;
                TheData(runnumber).t = t;
                TheData(runnumber).p = p;
                TheData(runnumber).data = data;
                eval(['save(''WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
                cd(expdir)
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
         end
        
        FlushEvents('keyDown'); %First discard all characters from the Event Manager queue
        if exist('conf')
            data.Confidence(n) = conf;
            data.RTconf(n) = react;
        %make note of non-response
        else
            data.Confidence(n) = NaN;
            data.RTconf(n) = react;
        end
        
        TimeUpdate = TimeUpdate + t.ConfidenceTime; %Update Matlab on what time it is.
        t.TrialStory = [t.TrialStory; {'confidence'} num2str(t.ConfidenceTime)];

        clear conf
        
        %% iti
        Screen('FillRect',window,p.MyGrey);
        Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window);
        %TIMING!:
        
        GlobalTimer = GlobalTimer + t.iti(n);
        TimePassed = 0; %Flush time passed.
        while (TimePassed<t.iti(n)) %As long as the stimulus is on the screen...
            TimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
            if TimePassed>=(t.iti(n)-t.CueStartsBefore)
                Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
                Screen('Flip', window);
            end
        end
        TimeUpdate = TimeUpdate + t.iti(n); %Update Matlab on what time it is.
        t.TrialStory = [t.TrialStory; {'iti'} num2str(t.iti(n))];

        
end %end of experimental trial/block loop
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%% END OF TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % final fixation and feedback:
    Screen('FillOval', window, p.FixColor, [CenterX-p.FixRadius CenterY-p.FixRadius CenterX+p.FixRadius CenterY+p.FixRadius])
    Screen('Flip', window);
    blockStr = ['Finished block ' num2str(runnumber) ' out of 8'];
    feedbackStr = [blockStr sprintf('\n') 'Press the spacebar to continue'];
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
    if exist(['WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
        load(['WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
    end
    %First I make a list of variables to save:
    TheData(runnumber).info = info;
    TheData(runnumber).t = t;
    TheData(runnumber).p = p;
    TheData(runnumber).data = data;
    eval(['save(''WM_DistractV11_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
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
