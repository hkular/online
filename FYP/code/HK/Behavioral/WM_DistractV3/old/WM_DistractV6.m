%% %%  from RR WM_DistractV2_Main_Practice.m adapted by HK, Sept 2021, for HK Holmes 
% addpath(genpath('/Applications/Psychtoolbox'))
% Inputs
% nruns: number of runs to execute sequentially 
% startRun: run number to start with if interrupted (default is 1)

% Stimulus categories
% Target: gabor orientation - set size 1 and 2 + noise masks in other
% quadrants
% distractor: noise - 2 contrast levels
 
 % Experimental design
 % Run duration: ?
 % Block duration: ?
 % Task: orientation detection, 4 AFC and 3 level confidence report
%% 
function WM_DistractV6(p, info, nruns, startRun)

 %% Prepare and collect basic info
    
    %Set Paths
    expdir = pwd;
    datadir = 'Data';
    addpath(pwd);
  
  
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
    if exist(['WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
        load(['WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
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
        %p.OrientBins = reshape([(75:2:105), (165:2:195)],[], p.NumOrientBins);% 15 deg around meridians
        %p.OrientBins = reshape([(72:2:88), (92:2:108), (162:2:178), (182:2:198)],[], p.NumOrientBins);
        %p.OrientBins = reshape([(82:2:88), (92:2:98), (172:2:178), (182:2:188)],[], p.NumOrientBins);
        p.OrientBins = reshape([(4:2:14), (346:2:356), (94:2:104), (76:2:86)],[], p.NumOrientBins);

        p.Contrast = [.5 .8];
        p.Quads = [1 2 3 4];
        p.SetSize = [1 2];
        [TrialStuff, designMatFull, trial_cnt_shuffled, MinNumTrials] = CounterBalancingActV6(p.OrientBins, p.SetSize, p.Quads, p.Contrast);
        p.designMatFull = designMatFull;
        p.trial_cnt_shuffled = trial_cnt_shuffled;
        p.NumTrials = 30; %NOT TRIVIAL!!! --> must be divisible by MinTrialNum AND by the number of possible iti's (which is 3)
        %currently MinNumTrials is 240, meaning 8 blocks of 30 trials
        
    end
   
    cd(expdir); %Back to experiment dir
%% Main Parameters 

%Timing params -- 
    t.PhaseReverseFreq = 4; %in Hz, how often gratings reverse their phase
    t.PhaseReverseTime = .4/t.PhaseReverseFreq;
    t.TargetTime = 2*t.PhaseReverseTime; %must be multiple of t.PhaseReverseTime is actually 2
    t.DistractorTime = 20*t.PhaseReverseTime; % 2 seconds
    t.isi1 = (t.DistractorTime)/2; %time between memory stimulus and distractor
    t.isi2 = t.isi1; %time between distractor and recall probe
    t.ResponseTime = 1.5;
    t.ConfidenceTime = 1.5;
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
    p.SF = 1.5; %spatial frequency in cpd is actally 2
    p.ContrastTarget = .7; % is actually .5
    p.MaskContrast = .7; % maybe decrease this
    p.Noise_f_bandwidth = 2; % is actually 2 frequency of the noise bandwidth
    p.Noise_fLow = p.SF/p.Noise_f_bandwidth; %Noise low spatial frequency cutoff
    p.Noise_fHigh = p.SF*p.Noise_f_bandwidth; %Noise high spatial frequency cutoff
    p.PhaseJitterTarget = randsample(0:359,p.NumTrials,true)*(pi/180);
    p.PhaseJitterDistGrating = NaN(1,p.NumTrials);
     
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
    
    % make masks
    mask_sine = (sin(p.SF/p.ppd*2*pi*(y.*sin(0*pi/180)+x.*cos(0*pi/180))));
    sine_maskcontrast = std(mask_sine(:));
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
            TargetsAreHere(pos,:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase1))); 
            TargetsAreHere(pos,:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase2)));
              ori_cnt = ori_cnt + 1;
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
            %Make it a donut
            filterednoise_phase1 = filterednoise .* donut;
            filterednoise_phase2 = -filterednoise .* donut;
            %Make sure to scale contrast to where it does not get clipped
            TargetsAreHere(pos,:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(p.MaskContrast * filterednoise_phase1)));
            TargetsAreHere(pos,:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(p.MaskContrast * filterednoise_phase2)));
        end
        
        runner = runner + 1;
    end
            
    clear sine sine2 stim_phase1 stim_phase2 
    
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
            %DistractorsAreHere(:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(TrialStuff(n).contrast * filterednoise_phase1)));
            %DistractorsAreHere(:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(TrialStuff(n).contrast * filterednoise_phase2)));
            DistractorsAreHere(:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(.7 * filterednoise_phase1)));
            DistractorsAreHere(:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(.7 * filterednoise_phase2)));
       
         end
        runner = runner+1;
    end
    clear i x y X Y donut sine sine2 stim_phase1 stim_phase2 filterednoise_phase1 filterednoise_phase2 distractor_sine
    
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
    
   % HideCursor;
 
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
    
  clear i
%% response window
% get RT
%%%%% 4 AFC and then 3 level confidence rating

% get response to window specified in TrialStuff .test
i = TrialStuff(p.TrialNumGlobal).test; % the quadrant number to probe

 % make an arrow pointing to quad number i        
    Arrows = {-50, 50;50, 50;50, -50;-50, -50};
    head = [CenterX-Arrows{i,1},CenterY-Arrows{i,2}];
    width  = 50;           % width of arrow head
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
        Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window,[],1);
        
        resp_start = GetSecs;
        GlobalTimer = GlobalTimer + t.ResponseTime;
        RespTimePassed = GetSecs-resp_start; %Flush time passed.

    
        KbName('UnifyKeyNames');

        nResponsesMade = 0;
        responseHolder = NaN(1,10);
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
                if exist(['WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
                    load(['WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
                end
                %First I make a list of variables to save:
                TheData(runnumber).info = info;
                TheData(runnumber).t = t;
                TheData(runnumber).p = p;
                TheData(runnumber).data = data;
                eval(['save(''WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
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
                if nResponsesMade <= 10
                    responseHolder(nResponsesMade) = resp;
                end
            end
         end
                newResp = unique(responseHolder);
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
        Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
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
                if exist(['WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
                    load(['WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
                end
                %First I make a list of variables to save:
                TheData(runnumber).info = info;
                TheData(runnumber).t = t;
                TheData(runnumber).p = p;
                TheData(runnumber).data = data;
                eval(['save(''WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
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

        
end %end of experimental trial/block loop
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%% END OF TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % final fixation and feedback:
    Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
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
    if exist(['WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'])
        load(['WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat']);
    end
    %First I make a list of variables to save:
    TheData(runnumber).info = info;
    TheData(runnumber).t = t;
    TheData(runnumber).p = p;
    TheData(runnumber).data = data;
    eval(['save(''WM_DistractV6_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_Main.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
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
