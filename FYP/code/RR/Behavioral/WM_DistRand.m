%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This experiment is looking at VSTM for a single orientation when people
%are presented with a randomly oriented distractor during a 3s delay- 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Have subjects do 6 runs per day, 2 days total (1 run is ~10 minutes)




try
    %This should clear out the memory and stop sourcecode from being reprinted
    echo off
    clear all
    close all hidden
    
    expdir = pwd; %Set the experimental directory to the current directory 'pwd'
    GeneralUseScripts = '/home/serencesadmin/Documents/Rosanne/GeneralUseScripts';
    addpath(GeneralUseScripts); %Add my general use scripts to the path.
    
    
    
    %Collect information about the subject, the date, etc.
    p.Subject = input('Initials? (default is temp) --> ','s'); if isempty(p.Subject); p.Subject = 'tmp'; end %Collect subject name
    SubNum = input('Subject number? (default is "0") --> ','s'); if isempty(SubNum); SubNum = '00'; end % collect subject number
    p.SubNum = sprintf('%02d', str2num(SubNum));
    t.MySeed = sum(100*clock);
    rand('state', t.MySeed);
    t.TheDate = datestr(now,'yymmdd'); %Collect todays date (in t.)
    t.TimeStamp = datestr(now,'HHMM'); %Timestamp for saving out a uniquely named datafile (so you will never accidentally overwrite stuff)
    
    
    
    %OPEN/INIT DATA FILE---------------------------------------------------
    datadir_local = '/home/pclexp/Documents/Rosanne/WM_DistRand/Data'; %Set the data directory to a directory called 'Data'
    cd(datadir_local);
    if exist(['DataDistRand_', p.SubNum, '.mat']);
        load(['DataDistRand_', p.SubNum, '.mat']);
        runnumber = length(TheData)+1;
    else
        runnumber = 1;
    end
    cd(expdir);
    
    
    
    %SCREEN PARAMETERS ----------------------------------------------------
    Screenwidth = 40; %in cm
    ViewingDistance = 50; %in cm
    %Compute the visual angle of te whole screen (which consists of many pixels)
    %The visual angle is needed to calculate the amount of pixels per degree (ppd):
    VisAngle = (2*atan2(Screenwidth/2, ViewingDistance))*(180/pi);
    Screens = Screen('Screens'); % look at available screens
    ScreenNr = max(Screens);
    p.ScreenSizePixels = Screen('Rect',Screens(end));
    CenterX = p.ScreenSizePixels(3)/2;
    CenterY = p.ScreenSizePixels(4)/2;
    ScreenWidthInPixels = p.ScreenSizePixels(3); %in pixels
    p.ppd = ScreenWidthInPixels/VisAngle;
    p.MyGrey = 128;
    black=BlackIndex(ScreenNr); white=WhiteIndex(ScreenNr);
    gammacorrect = true;
    
    
    
    %DEFINE MAIN PARAMETERS------------------------------------------------
    %Size Parameters
    p.OuterGratingRadius = round(2*p.ppd); %Size of grating is automatically defined in pixels. So 1 degree radius, and 2 degree diameter. The smaller the gratings, the closer to fixation you can display them.
    p.InnerGratingRadius = 0; %Also automatically defined in pixels.
    p.Smooth_size = round(.5*p.ppd); %size of fspecial smoothing kernel
    p.Smooth_sd = round(.25*p.ppd); %sd of smoothing kernel
    p.PatchSize = round(2*p.OuterGratingRadius+p.Smooth_size); %Size of the patch that is drawn on various screen locations to fit gratings into (in pixels):
    p.OuterFixation = round(0.25*p.ppd); %Quarter of a degree radius, so half a degree of vis angle in diameter. Size of the outer fixation dot (radius, in pixels)
    p.InnerFixation = p.OuterFixation/2; %Size of the inner fixation dot (radius, in pixels)
    %Timing parameters
    t.StimTime = 0.2; %To be remembered grating is on the screen for 200 ms
    t.DistTime = 0.2; %DIstractor stimulus
    t.Delay = 3; %Retention in seconds
    t.DistAfter = t.Delay/2-t.DistTime/2; %distractor comes this soon after the stimulus
    t.ResponseTime = [];
    %Grating parameters
    p.NumOrientBins = 9; %must be multiple of the size of your orientation space (here: 180)
    p.OrientBins = reshape(1:180,180/p.NumOrientBins,p.NumOrientBins);
    p.Freq = 2; %Frequency of the grating in cycles per degree:
    p.Contrast = 0.2; %Make contast parameter between 0 and 1. This will be a ratio of (maxlum - meanlum)/meanlum
    
    
    
    %COUNTERBALANCING ACT--------------------------------------------------
    TrialStuff = [];
    for orient_bin_target = 1:size(p.OrientBins,2)
        for distpresent = [0 1]
            if ~distpresent
                trial.orient_target = randsample(p.OrientBins(:,orient_bin_target),1);
                trial.orient_distr = [];
                trial.dist_after = [];
                trial.distractor = {'no'};
                TrialStuff = [TrialStuff trial];
            elseif distpresent
                for orient_bin_dist = 1:size(p.OrientBins,2)
                    for dist_timing = t.DistAfter
                        trial.orient_target = randsample(p.OrientBins(:,orient_bin_target),1);
                        trial.orient_distr = randsample(p.OrientBins(:,orient_bin_dist),1);
                        trial.dist_after = dist_timing;
                        trial.distractor = {'yes'};
                        TrialStuff = [TrialStuff trial]; % big struct with all the info I need to present stimulus conditions
                    end
                end
            end
        end
    end
    TrialStuff = Shuffle(TrialStuff);
    p.NumTrials = size(TrialStuff,2);
    p.TestOrient = (randsample((1:180),p.NumTrials, true)); %The test lines that will be adjusted starts at random orientation.
    p.PhaseJitterTarget = randsample(0:359,p.NumTrials)*(pi/180);
    p.PhaseJitterDist = randsample(0:359,p.NumTrials)*(pi/180);
   
    t.iti = randsample(.8:.01:1,p.NumTrials,true); 
    t.MeantToBeishTime = p.NumTrials*(t.StimTime + t.Delay + .9 + 2);
    
    
    
    %CREATE PATCH----------------------------------------------------------
    %First a central patch:
    Center = [p.ScreenSizePixels(3)/2 p.ScreenSizePixels(4)/2];
    CenterPatch = [CenterX-p.PatchSize/2 CenterY-p.PatchSize/2 CenterX+p.PatchSize/2 CenterY+p.PatchSize/2];
    
    
    
    %%% MAKE GAUSSIAN STIMULI
    %Make meshgrid first
    X=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5; Y=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5;
    [x,y] = meshgrid(X,Y);
    %Make a circle with gaussian smoothing along its edges
    circle = x.^2 + y.^2 <= (p.OuterGratingRadius)^2;
    circle = filter2(fspecial('gaussian', p.Smooth_size, p.Smooth_sd), circle);
    %Put them in matrix
    gratings = NaN(p.PatchSize,p.PatchSize,p.NumTrials,2); %last dimension is for target and distractor
    for types = 1:2 %target and distractor 
        for n = 1:p.NumTrials
            if types == 1 %if a target
                orient = TrialStuff(n).orient_target;
                phase = p.PhaseJitterTarget(n);
            elseif types == 2 %if a distractor
                orient = TrialStuff(n).orient_distr;
                phase = p.PhaseJitterDist(n);
            end
            if types == 1 || (types == 2 && strcmp('yes',char(TrialStuff(n).distractor)))
                %Make a sinusoid with the correct orientation on his trial (in deg of visual angle)
                sine = (sin(p.Freq/p.ppd*2*pi*(y.*sin(orient*pi/180)+x.*cos(orient*pi/180)) - phase)); % make sine wave, range from -1 to 1
                %Make the grating (sine * fuzzy-edged circle)
                grating = sine .* circle;
                %Give the grating the right contrast and scale it to the 1:
                grating = max(0,min(255,p.MyGrey+p.MyGrey*(p.Contrast * grating)));
                gratings(:,:,n,types) = grating;
            end
        end
    end
    clear x y X Y circle sine grating
    
    
    
    %WINDOW SETUP & GAMMA CORRECTION---------------------------------------
    AssertOpenGL;
    PsychJavaTrouble;
    [window] = Screen('OpenWindow',ScreenNr, p.MyGrey,[],[],2);
    t.ifi = Screen('GetFlipInterval',window);
    if gammacorrect
        OriginalCLUT = Screen('LoadClut', window);
        MyCLUT = zeros(256,3); MinLum = 0; MaxLum = 1;
        CalibrationFile = 'calib_13-Jun-2016.mat';
        [gamInverse,dacsize] = LoadCalibrationFileRR(CalibrationFile, expdir, GeneralUseScripts);
        LumSteps = linspace(MinLum, MaxLum, 256)';
        MyCLUT(:,:) = repmat(LumSteps, [1 3]);
        MyCLUT = round(map2map(MyCLUT, gamInverse)); %Now the screen output luminance per pixel is linear!
        Screen('LoadCLUT', window, MyCLUT);
        clear CalibrationFile gamInverse
    end
    HideCursor;
    
    
    
    %START THE ACTUAL EXPERIMENT-----------------------------------------------
    %Draw some text to the screen first outside of the experimental loop:
    Screen('TextSize',window,18);
    Screen(window,'TextFont','Helvetica');
    WelcomeText = ['THIS IS A MEMORY EXPERIMENT, WELCOME!' '\n' '\n' '\n'...
        'A grating will be presented in middle of the screen, and your task is' '\n' '\n'...
        'to remember its orientation as precisely as possible over a 12s delay' '\n' '\n'...
        'During the delay another grating will appear, which you can view, but ignore' '\n' '\n'...
        'After the delay, two white lines appear, indicating a single orientation. Use the mouse' '\n' '\n'...
        'to replicate the remembered orientation by rotating the lines as accurately as possible' '\n' '\n'...
        'Left mouse-click to continue.'];
    DrawFormattedText(window, WelcomeText, 'center', 'center', white);
    Screen('Flip', window);
    GetClicks;
    %BeginFixation
    Screen('FillOval', window, white, [CenterX-p.OuterFixation CenterY-p.OuterFixation CenterX+p.OuterFixation CenterY+p.OuterFixation])
    Screen('FillOval', window, p.MyGrey, [CenterX-p.InnerFixation CenterY-p.InnerFixation CenterX+p.InnerFixation CenterY+p.InnerFixation])
    Screen('Flip', window);
    WaitSecs(1.5);
    
    
    t.StartTime = GetSecs; %Get the starttime of the experiment in seconds
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% A TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for n = 1:p.NumTrials
        
        %This trial what are my delay1 and delay2 durations going to be?
        if strcmp('yes',char(TrialStuff(n).distractor))
            delay1 = TrialStuff(n).dist_after;
            delay2 = t.Delay-TrialStuff(n).dist_after-t.DistTime;
        else
            delay1 = t.Delay/2;
            delay2 = t.Delay/2;
        end
            
        %Present the target grating
        Grating = Screen('MakeTexture', window, gratings(:,:,n,1));
        Screen('DrawTexture', window, Grating, [], CenterPatch)
        Screen('FillOval', window, white, [CenterX-p.OuterFixation CenterY-p.OuterFixation CenterX+p.OuterFixation CenterY+p.OuterFixation])
        Screen('FillOval', window, p.MyGrey, [CenterX-p.InnerFixation CenterY-p.InnerFixation CenterX+p.InnerFixation CenterY+p.InnerFixation])
        Screen('Flip', window);
        WaitSecs(t.StimTime);
        Screen('Close',Grating);
        
        %Delay1 (before distractor)
        Screen('FillOval', window, white, [CenterX-p.OuterFixation CenterY-p.OuterFixation CenterX+p.OuterFixation CenterY+p.OuterFixation])
        Screen('FillOval', window, p.MyGrey, [CenterX-p.InnerFixation CenterY-p.InnerFixation CenterX+p.InnerFixation CenterY+p.InnerFixation])
        Screen('Flip', window);
        WaitSecs(delay1);
        
        %Present the distractor grating
        if strcmp('yes',char(TrialStuff(n).distractor))
            Grating = Screen('MakeTexture', window, gratings(:,:,n,2));
            Screen('DrawTexture', window, Grating, [], CenterPatch)
            Screen('FillOval', window, white, [CenterX-p.OuterFixation CenterY-p.OuterFixation CenterX+p.OuterFixation CenterY+p.OuterFixation])
            Screen('FillOval', window, p.MyGrey, [CenterX-p.InnerFixation CenterY-p.InnerFixation CenterX+p.InnerFixation CenterY+p.InnerFixation])
            Screen('Flip', window);
            WaitSecs(t.DistTime);
            Screen('Close',Grating);
        end
        
        %Delay2 (after distractor)
        Screen('FillOval', window, white, [CenterX-p.OuterFixation CenterY-p.OuterFixation CenterX+p.OuterFixation CenterY+p.OuterFixation])
        Screen('FillOval', window, p.MyGrey, [CenterX-p.InnerFixation CenterY-p.InnerFixation CenterX+p.InnerFixation CenterY+p.InnerFixation])
        Screen('Flip', window);
        WaitSecs(delay2);
        
        %Test
        Screen('TextSize',window,16);
        FixedRad = p.OuterGratingRadius+(p.ppd*.25/2);
        InitX = round(abs(FixedRad * sin(p.TestOrient(n)*pi/180)+CenterX));
        InitY = round(abs(FixedRad * cos(p.TestOrient(n)*pi/180)-CenterY));
        allowedX = FixedRad * sin([0:179]*pi/180)+CenterX;
        allowedY = abs(FixedRad*cos([0:179]*pi/180)-CenterY);
        allowedXY = [allowedX.' allowedY.'];
        Screen('BlendFunction', window, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
        Screen('DrawLines', window, [2*CenterX-InitX, InitX; 2*CenterY-InitY, InitY], 1, white,[],1);
        Screen('BlendFunction', window, GL_ONE, GL_ZERO);
        Screen('FillOval', window, p.MyGrey, [CenterX-p.OuterGratingRadius CenterY-p.OuterGratingRadius CenterX+p.OuterGratingRadius CenterY+p.OuterGratingRadius])
        Screen('FillOval', window, white, [CenterX-p.OuterFixation CenterY-p.OuterFixation CenterX+p.OuterFixation CenterY+p.OuterFixation])
        Screen('FillOval', window, p.MyGrey, [CenterX-p.InnerFixation CenterY-p.InnerFixation CenterX+p.InnerFixation CenterY+p.InnerFixation])
        Screen('Flip', window,[],1);
        IsTime = GetSecs;
        Identified = 0;
        while 1
            SetMouse(InitX,InitY);
            [checkX,checkY]= GetMouse;
            if (checkX==InitX) && (checkY==InitY)
                break;
            end
        end
        [x,y,buttons] = GetMouse;
        while Identified == 0;  %As long as no correct answer is identified
            [keyIsDown, secs, keyCode] = KbCheck;
            Screen('BlendFunction', window, GL_ONE, GL_ZERO);
            Screen('FillRect', window, p.MyGrey);
            Screen('BlendFunction', window, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
            Screen('DrawLines', window, [2*CenterX-x, x; 2*CenterY-y, y], 1, white, [], 1);
            Screen('BlendFunction', window, GL_ONE, GL_ZERO);
            Screen('FillOval', window, p.MyGrey, [CenterX-p.OuterGratingRadius CenterY-p.OuterGratingRadius CenterX+p.OuterGratingRadius CenterY+p.OuterGratingRadius])
            Screen('FillOval', window, white, [CenterX-p.OuterFixation CenterY-p.OuterFixation CenterX+p.OuterFixation CenterY+p.OuterFixation])
            Screen('FillOval', window, p.MyGrey, [CenterX-p.InnerFixation CenterY-p.InnerFixation CenterX+p.InnerFixation CenterY+p.InnerFixation])
            Screen('Flip', window, [], 1,[], []);
            [realX,realY,buttons] = GetMouse;
            angle = atand(abs(CenterX-realX)/abs(CenterY-realY));
            if realX>CenterX && realY<CenterY
                x = abs(FixedRad * sin(angle*pi/180)+CenterX);
                y = abs(FixedRad*cos(angle*pi/180)-CenterY);
            elseif realX>CenterX && realY>CenterY
                x = abs(FixedRad * sin(angle*pi/180)+CenterX);
                y = abs(FixedRad*cos(angle*pi/180)+CenterY);
            elseif realX<CenterX && realY>CenterY
                x = abs(FixedRad * sin(angle*pi/180)-CenterX);
                y = abs(FixedRad*cos(angle*pi/180)+CenterY);
            elseif realX<CenterX && realY<CenterY
                x = abs(FixedRad * sin(angle*pi/180)-CenterX);
                y = abs(FixedRad*cos(angle*pi/180)-CenterY);
            end
            if keyCode(KbName('Escape')) % If user presses ESCAPE, exit the program.
                Screen('CloseAll');
                if exist('OriginalCLUT','var')
                    if exist('ScreenNr','var')
                        Screen('LoadCLUT', ScreenNr, OriginalCLUT);
                    else
                        Screen('LoadCLUT', 0, OriginalCLUT);
                    end
                end
                error('User exited program.');
            end
            if buttons(1) %If a mouse button is pressed
                Screen('FillOval', window, white, [CenterX-p.OuterFixation CenterY-p.OuterFixation CenterX+p.OuterFixation CenterY+p.OuterFixation])
                Screen('FillOval', window, p.MyGrey, [CenterX-p.InnerFixation CenterY-p.InnerFixation CenterX+p.InnerFixation CenterY+p.InnerFixation])
                Screen('Flip', window);
                Identified = 1; %The orientation answer is identified
                if x>CenterX && y>CenterY || x<CenterX && y<CenterY
                    response = round(180-atand(abs(x-CenterX)/abs(y-CenterY)));
                else
                    response = round(atand(abs(x-CenterX)/abs(y-CenterY)));
                end
                response(response==0)=180;
                resptime = GetSecs - IsTime;
                t.ResponseTime = [t.ResponseTime, resptime];
            end
        end
        FlushEvents('keyDown');
        
        
        %INTERMISSION (How accurate was subject?)
        clear OrientationDeviation
        OrientationDeviation(1) = abs(TrialStuff(n).orient_target-response);
        OrientationDeviation(2) = abs((360-(OrientationDeviation(1)*2))/2); %abs((180 + Data(GlobalTrialNumber,7)) - Data(GlobalTrialNumber,4));
        OrientationDeviation(3) = 360-(OrientationDeviation(1));
        accuracy = min(OrientationDeviation); %Calculates and records how far off participants really are from target
        %Add plus and minus signs (actually, just add minus signs where needed)
        if mod(TrialStuff(n).orient_target-accuracy, 360) == response; accuracy= -accuracy;
        elseif mod((TrialStuff(n).orient_target+180) - accuracy, 360) == response; accuracy= -accuracy; end
        

        %Draw some text to indicate rest period:
        if n == round(p.NumTrials/2)
            Now1 = GetSecs;
            Screen(window,'TextSize',18); Screen(window,'TextFont','Helvetica');
            RestText = 'Halfway there! You can take a short break now, or click the mouse to continue';
            DrawFormattedText(window, RestText, 'center', 'center', white);
            Screen('Flip', window);
            GetClicks;
            Now2 = GetSecs;
            t.RestTime(n) = (Now2-Now1);
            FlushEvents('keyDown'); %Discard GetChar characters from the Event Manager queue
        end
     
        
        %iti
        Screen('FillOval', window, white, [CenterX-p.OuterFixation CenterY-p.OuterFixation CenterX+p.OuterFixation CenterY+p.OuterFixation])
        Screen('FillOval', window, p.MyGrey, [CenterX-p.InnerFixation CenterY-p.InnerFixation CenterX+p.InnerFixation CenterY+p.InnerFixation])
        Screen('Flip', window);
        WaitSecs(t.iti(n));
        

        data_response(n) = response;
        data_accuracy(n) = accuracy;
    end %trails
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%% END OF TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    t.EndTime = GetSecs; %Get endtime of the experiment in seconds
    %Draw some more text to the screen outside of the loop:
    Screen(window,'TextSize',30);
    Screen(window,'TextFont','Helvetica');
    ByebyeText = 'Great work! You have finished this run';
    DrawFormattedText(window, ByebyeText, 'center', 'center', white);
    Screen('Flip', window);
    WaitSecs(3);
    FlushEvents('keyDown'); %First discard all characters from the Event Manager queue
    TotalExpTime = (t.EndTime-t.StartTime) + 2 + 3; %Gets the duration of the total run.
    t.TotalExpTime = TotalExpTime/60; %TOTAL exp time in mins including begin and end fixation.
    
    
    
    %WINDOW CLEANUP------------------------------------------------------------
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
    
    
    
    %SAVE OUT THE DATA FILE----------------------------------------------------
    %First I make a list of variables to save:
    TheData(runnumber).t = t;
    TheData(runnumber).p = p;
    TheData(runnumber).TrialStuff = TrialStuff; 
    TheData(runnumber).data = [data_response' data_accuracy'];
    cd(datadir_local);
    eval(['save DataDistRand_', p.SubNum, '.mat TheData'])
    %save to server too
    datadir_remote = '/mnt/pclexp/Rosanne/WM_DistRand/Data';
    cd(datadir_remote)
    eval(['save DataDistRand_', p.SubNum, '.mat TheData']);
    cd(expdir); %Change the working directory back to the experimental directory

    
catch %If an error occurred in the "try" block, this code is executed
    if exist('ThrowErrorDB','file') ~= 0 %If ThrowErrorDB exists, use it
        ThrowErrorDB; %Display last error (in a pretty way)
    else
        disp('An error occured, but ThrowErrorDB is not in path, so the error cannot be displayed.');
    end
end



%Quick check of performance (should be between 6-10 approx. If it's more,
%this participant may be bad:
figure;hist(data_accuracy,-90:1:90)
title(['Mean accuracy was ' num2str(mean(abs(TheData(runnumber).data(:,2)))) ' degrees'],'FontSize',16)
