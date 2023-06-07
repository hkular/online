%This script is a WM EXPERIMENT PRACTICE FOR ON MY AIR!!!!!!!!!!!!!!!!!!!!!
%It displays a grating in the shape of a donut and subjects have to
%remember its orientation. During the delay there is either no distractor,
%a filtered noise distractor (matched for sf) or a grating distractor. The
%fixation dot color indicates the type of distractor people can expect.
%
%Currently a run is 6 trials (139 seconds), 2 runs are required to fully
%counterbalance, after that no more runs are possible on the same day
%(because the counterbalancing is only ran once)

%Written by RR, July 2016, apdapted October 2016, for WM distractor experiment


try
    
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
    GeneralUseScripts = '/Users/rosanne/Dropbox/GeneralUseScripts';
    addpath(GeneralUseScripts); %Add my general use scripts to the path.
    
    %Get user info
    Subject = 'S06';
    info.Name = input('Initials? (default is temp) --> ','s'); if isempty(info.Name); info.Name = 'tmp'; end %Collect subject initials
    SubNum = input('Subject number? (default is "0") --> ','s'); if isempty(SubNum); SubNum = '00'; end % collect subject number
    info.SubNum = sprintf('%02d', str2num(SubNum));
    if ~strcmp(Subject,['S' info.SubNum]); disp('Subject name doesn''t match name in script, please check and try again'); return; end;
    
    %Get timing info
    t.MySeed = sum(100*clock); %seeds the random number generator based on the current time
    rand('twister', t.MySeed); %sets random seed
    info.TheDate = datestr(now,'yymmdd'); %Collect todays date (in t.)
    info.TimeStamp = datestr(now,'HHMM'); %Timestamp for saving out a uniquely named datafile (so you will never accidentally overwrite stuff)
    
    
    
    %----------------------------------------------------------------------
    %SCREEN PARAMETERS-----------------------------------------------------
    %----------------------------------------------------------------------
    Screens = Screen('Screens'); %look at available screens
    ScreenNr = Screens(1); %pick screen with largest screen number
    p.ScreenSizePixels = Screen('Rect', ScreenNr);
    tmprect = get(0, 'ScreenSize');
    computer_res = tmprect(3:4);
    if computer_res(1) ~= p.ScreenSizePixels(3) || computer_res(2) ~= p.ScreenSizePixels(4)
        Screen('CloseAll');clear screen;ShowCursor;
        disp('*** ATTENTION! *** Yo screensizes ain''t matchin''')
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
        p.DistType = [0 1 2];
        p.DistTypeNames = {'none';'noise';'grating'};
        [TrialStuff, MinNumTrials] = CounterBalancingActV2(p.DistType, p.DistTypeNames, p.OrientBins);
        p.NumTrials = 6; %NOT TRIVIAL!!! --> must be divisible by MinTrialNum AND by the number of possible iti's (which is 3)
        %For the practice, MinTrialNum is 12. Running 6 trial blocks thus means
        %that 2 blocks need to be ran for one full counterbalancing act
        load('CueColorsV2.mat'); %6 subjects needed to fully between-subject counterbalance the cue colors
        p.CueColors = CueColors((rem(str2num(info.SubNum)-1,length(CueColors)))+1);
    end
    cd(expdir); %Back to where I need to be. go!
    
    
    
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
    p.OuterFixRadius = .2*p.ppd; %outter dot radius (in pixels)
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
    
    
    
    %----------------------------------------------------------------------
    %MAKE THE DISTRACTOR STIMULI-------------------------------------------
    %----------------------------------------------------------------------
    % now make a matrix with with all my distractors for all my trials
    DistractorsAreHere = NaN(p.PatchSize,p.PatchSize,p.NumTrials,2); %last dimension: 2 phases
    distractor_sine = (sin(p.SF/p.ppd*2*pi*(y.*sin(0*pi/180)+x.*cos(0*pi/180))));
    sine_contrast = std(distractor_sine(:));
    runner = 1;
    for n = (p.TrialNumGlobal+1):(p.TrialNumGlobal+p.NumTrials)
        if strcmp('noise',char(p.DistTypeNames(TrialStuff(n).distractortype==p.DistType))) %If a noise distractor trial
            %Make uniform noise, put it into fourrier space, make sf filer
            noise = rand(p.PatchSize,p.PatchSize)*2-1;
            fn_noise = fftshift(fft2(noise));
            sfFilter = Bandpass2([p.PatchSize p.PatchSize], p.Noise_fLow/p.fNyquist, p.Noise_fHigh/p.fNyquist);
            %Get rid of gibbs ringing artifacts
            smoothfilter = fspecial('gaussian', 10, 4);   % make small gaussian blob
            sfFilter = filter2(smoothfilter, sfFilter); % convolve smoothing blob w/ s.f. filter
            %Bring noise back into real space
            filterednoise = real(ifft2(ifftshift(sfFilter.*fn_noise)));
            %Scale the contrast of the noise back up (it's lost some in the fourrier
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
        elseif strcmp('grating',char(p.DistTypeNames(TrialStuff(n).distractortype==p.DistType))) %If a grating distractor trial
            p.PhaseJitterDistGrating(runner) = randsample(0:359,1)*(pi/180);
            %Make distractor gratings
            sine = (sin(p.SF/p.ppd*2*pi*(y.*sin(TrialStuff(n).distractororient*pi/180)+x.*cos(TrialStuff(n).distractororient*pi/180))-p.PhaseJitterDistGrating(runner)));
            sine2 = (sin(p.SF/p.ppd*2*pi*(y.*sin(TrialStuff(n).distractororient*pi/180)+x.*cos(TrialStuff(n).distractororient*pi/180))-rem(p.PhaseJitterDistGrating(runner) + pi,2*pi)));
            stim_phase1 = sine.*donut;
            stim_phase2 = sine2.*donut;
            sine_contrast = std(sine(:));
            %Give the grating the right contrast level and scale it
            DistractorsAreHere(:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastDistGrating * stim_phase1)));
            DistractorsAreHere(:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastDistGrating * stim_phase2)));
        end
        runner = runner+1;
    end
    clear x y X Y donut sine sine2 stim_phase1 stim_phase2 filterednoise_phase1 filterednoise_phase2 distractor_sine
    
    
    
    %----------------------------------------------------------------------
    %WINDOW SETUP & GAMMA CORRECTION---------------------------------------
    %----------------------------------------------------------------------
    AssertOpenGL;
    PsychJavaTrouble;
    [window] = Screen('OpenWindow',ScreenNr, p.MyGrey,[],[],2);
    t.ifi = Screen('GetFlipInterval',window);
    if gammacorrect
        OriginalCLUT = Screen('LoadClut', window);
        MyCLUT = zeros(256,3); MinLum = 0; MaxLum = 1;
        CalibrationFile = 'calib_30-Jul-2016.mat';
        [gamInverse,dacsize] = LoadCalibrationFileRR(CalibrationFile, expdir, GeneralUseScripts);
        LumSteps = linspace(MinLum, MaxLum, 256)';
        MyCLUT(:,:) = repmat(LumSteps, [1 3]);
        MyCLUT = round(map2map(MyCLUT, repmat(gamInverse(:,4),[1 3]))); %Now the screen output luminance per pixel is linear!
        Screen('LoadCLUT', window, MyCLUT);
        clear CalibrationFile gamInverse
    end
    HideCursor;
    
    
    
    %----------------------------------------------------------------------
    %MISC AND PREALLOCATE STUFF--------------------------------------------
    %----------------------------------------------------------------------
    MyPatch = [(CenterX-p.PatchSize/2) (CenterY-p.PatchSize/2) (CenterX+p.PatchSize/2) (CenterY+p.PatchSize/2)];
    
    
    
    %----------------------------------------------------------------------
    %WELCOME MESSAGE & WAIT FOR TRIGGER------------------------------------
    %----------------------------------------------------------------------
    %See what cue color we start on 
    fix_predict_col = eval(['p.CueColors.' char(TrialStuff(p.TrialNumGlobal+1).distractorname)]);
    %Welcome welcome ya'll
    Screen(window,'TextSize',20);
    Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
    Screen('DrawText',window, 'waiting for scanner to initiate', p.ScreenSizePixels(1)+10, p.ScreenSizePixels(2)+10, white);
    Screen('Flip', window);
    FlushEvents('keyDown'); %First discard all characters from the Event Manager queue.
    ListenChar(2);
    % just sittin' here, waitin' on my trigger...
    while 1
        [keyIsDown, secs, keyCode] = KbCheck([-1]);
        if keyCode(KbName('t'))
            t.StartTime = GetSecs;
            break; %let's go!
        end
    end
    FlushEvents('keyDown');
    
    
    
    GlobalTimer = 0; %this timer keeps track of all the timing in the experiment. TOTAL timing.
    TimeUpdate = t.StartTime; %what time issit now?
    % presentt begin fixation
    Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
    Screen('Flip', window);
    %TIMING!:
    GlobalTimer = GlobalTimer + t.BeginFixation;
    TimePassed = 0; %Flush the time the previous event took
    while (TimePassed<t.BeginFixation) %For as long as the cues are on the screen...
        TimePassed = (GetSecs-TimeUpdate);%And determine exactly how much time has passed since the start of the expt.
        if TimePassed>=(t.BeginFixation-t.CueStartsBefore)
            Screen('FillOval', window, fix_predict_col, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
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
        
        
        %% Target
        for revs = 1:t.TargetTime/t.PhaseReverseTime
            if rem(revs,2)==0 %if this repetition is an even number
                StimToDraw = Screen('MakeTexture', window, TargetsAreHere(:,:,n,1,1));
            end
            if rem(revs,2)==1 %if this repetition is an odd number
                StimToDraw = Screen('MakeTexture', window, TargetsAreHere(:,:,n,2,1));
            end
            Screen('DrawTexture', window, StimToDraw, [], MyPatch, [], 0);
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
        if ~strcmp('none',char(TrialStuff(p.TrialNumGlobal).distractorname)) 
            DistToDraw1 = Screen('MakeTexture', window, DistractorsAreHere(:,:,n,1,1));
            DistToDraw2 = Screen('MakeTexture', window, DistractorsAreHere(:,:,n,2,1));
        end
        for revs = 1:t.DistractorTime/t.PhaseReverseTime
            if ~strcmp('none',char(TrialStuff(p.TrialNumGlobal).distractorname))
                if rem(revs,2)==1 %if this repetition is an even number
                    Screen('DrawTexture', window, DistToDraw1, [], MyPatch, [], 0);
                end
                if rem(revs,2)==0 %if this repetition is an odd number
                    Screen('DrawTexture', window, DistToDraw2, [], MyPatch, [], 0);
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
        t.TrialStory = [t.TrialStory; TrialStuff(p.TrialNumGlobal).distractorname num2str(t.DistractorTime)];
        if ~strcmp('none',char(TrialStuff(p.TrialNumGlobal).distractorname))
            Screen('Close', [DistToDraw1 DistToDraw2]);
        end
         
        
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
        test_orient = p.TestOrient(n);
        orient_trajectory = [test_orient];
        InitX = round(abs((p.OuterDonutRadius+p.Smooth_size/2) * sin(test_orient*pi/180)+CenterX));
        InitY = round(abs((p.OuterDonutRadius+p.Smooth_size/2) * cos(test_orient*pi/180)-CenterY));
        Screen('BlendFunction', window, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
        Screen('DrawLines', window, [2*CenterX-InitX, InitX; 2*CenterY-InitY, InitY], p.ResponseLineWidth, p.ResponseLineColor,[],1);
        Screen('BlendFunction', window, GL_ONE, GL_ZERO);
        Screen('FillOval', window, p.MyGrey, [CenterX-(p.InnerDonutRadius-p.Smooth_size/2) CenterY-(p.InnerDonutRadius-p.Smooth_size/2) CenterX+(p.InnerDonutRadius-p.Smooth_size/2) CenterY+(p.InnerDonutRadius-p.Smooth_size/2)]);
        Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window,[],1);
        GlobalTimer = GlobalTimer + t.ResponseTime;
        RespTimePassed = GetSecs-resp_start; %Flush time passed.
        while RespTimePassed<t.ResponseTime  %As long as no correct answer is identified
            RespTimePassed = (GetSecs-TimeUpdate); %And determine exactly how much time has passed since the start of the expt.
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            %scanner buttons are: b y g r (form left-to-right)
            if keyCode(KbName('1!')) %BIG step CCW
                test_orient = rem(test_orient-2+1440,180);
            elseif keyCode(KbName('2@')) %small step CCW
                test_orient = rem(test_orient-.5+1440,180);
            elseif keyCode(KbName('3#')) %small step CW
                test_orient = rem(test_orient+.5+1440,180);
            elseif keyCode(KbName('4$')) %BIG step CW
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
            UpdatedX = round(abs((p.OuterDonutRadius+p.Smooth_size/2) * sin(test_orient*pi/180)+CenterX));
            UpdatedY = round(abs((p.OuterDonutRadius+p.Smooth_size/2) * cos(test_orient*pi/180)-CenterY));
            Screen('BlendFunction', window, GL_ONE, GL_ZERO);
            Screen('FillRect', window, p.MyGrey);
            Screen('BlendFunction', window, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
            Screen('DrawLines', window, [2*CenterX-UpdatedX, UpdatedX; 2*CenterY-UpdatedY, UpdatedY], p.ResponseLineWidth, p.ResponseLineColor, [], 1);
            Screen('BlendFunction', window, GL_ONE, GL_ZERO);
            Screen('FillOval', window, p.MyGrey, [CenterX-(p.InnerDonutRadius-p.Smooth_size/2) CenterY-(p.InnerDonutRadius-p.Smooth_size/2) CenterX+(p.InnerDonutRadius-p.Smooth_size/2) CenterY+(p.InnerDonutRadius-p.Smooth_size/2)]);
            Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius]);
            Screen('Flip', window, [], 1,[], []);
        end
        FlushEvents('keyDown'); %First discard all characters from the Event Manager queue
        data.Response(n) = test_orient;
        TimeUpdate = TimeUpdate + t.ResponseTime; %Update Matlab on what time it is.
        t.TrialStory = [t.TrialStory; {'response'} num2str(t.ResponseTime)];

        
        %% iti
        if n~=p.NumTrials %if cue predicts distractor condition
            fix_predict_col = eval(['p.CueColors.' char(TrialStuff(p.TrialNumGlobal+1).distractorname)]);
        elseif n==p.NumTrials
            fix_predict_col = p.FixColor;
        end
        
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
                Screen('FillOval', window, fix_predict_col, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
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
%     % final fixation:
%     Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
%     Screen('Flip', window);
%     GlobalTimer = GlobalTimer + t.EndFixation;
%     closingtime = 0; resp = 0;
%     while closingtime < t.EndFixation
%         closingtime = GetSecs-TimeUpdate;
%         ListenChar(1); %Unsuppressed keyboard mode
%         if CharAvail
%             [press] = GetChar;
%             if strcmp(press,'1')
%                 resp = str2double(press);
%             end
%         end
%     end
    t.EndTime = GetSecs; %Get endtime of the experiment in seconds
    t.TotalExpTime = (t.EndTime-t.StartTime); %Gets the duration of the total run.
    t.TotalExpTimeMins = t.TotalExpTime/60; %TOTAL exp time in mins including begin and end fixation.
    t.GlobalTimer = GlobalTimer; %Spits out the exp time in secs excluding begin and end fixation.

    
    
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
    ShowCursor;
    ListenChar(1);
    
    
    %----------------------------------------------------------------------
    %LOOK AT BEHAVIORAL PERFOPRMANCE---------------------------------------
    %----------------------------------------------------------------------
    targets_were = [TrialStuff(p.TrialNumGlobal+1-p.NumTrials:p.TrialNumGlobal).orient];
    acc(1,:) = abs(targets_were-data.Response);
    acc(2,:) = abs((360-(acc(1,:)*2))/2); 
    acc(3,:) = 360-(acc(1,:));
    acc = min(acc); 
    %Add minus signs back in
    acc(mod(targets_were-acc,360)==data.Response)=-acc(mod(targets_were-acc,360)==data.Response);
    acc(mod((targets_were+180)-acc,360)==data.Response)=-acc(mod((targets_were+180)-acc,360)==data.Response);
    data.Accuracy = acc;
    figure;hist(data.Accuracy,-90:1:90); set(gca,'XLim',[-90 90],'XTick',[-90:45:90]);
    title(['Mean accuracy was ' num2str(mean(abs(data.Accuracy))) ' degrees'],'FontSize',16)
    
    
    
    %----------------------------------------------------------------------
    %SAVE OUT THE DATA-----------------------------------------------------
    %----------------------------------------------------------------------
    cd(datadir); %Change the working directory back to the experimental directory
    if exist(['WM_DistractV2_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_MainPractice.mat']);
        load(['WM_DistractV2_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_MainPractice.mat']);
    end
    %First I make a list of variables to save:
    TheData(runnumber).info = info;
    TheData(runnumber).t = t;
    TheData(runnumber).p = p;
    TheData(runnumber).data = data;
    TheData(runnumber).trajectory = Trajectory;
    eval(['save(''WM_DistractV2_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_MainPractice.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
    cd(expdir)
    
    
    
    %----------------------------------------------------------------------
    %TRY CATCH STUFF-------------------------------------------------------
    %----------------------------------------------------------------------
catch %If an error occurred in the "try" block, this code is executed
    if exist('ThrowErrorDB','file') ~= 0 %If ThrowErrorDB exists, use it
        ThrowErrorDB; %Display last error (in a pretty way)
    else
        disp('An error occured, but ThrowErrorDB is not in path, so the error cannot be displayed.');
    end
end

