%This script is a LOCALIZER!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%It has some true fixation periods, and it displays either a grating in 
%shape of a donut (8 s) or grating in shape of a circle (with the size of 
%the inside of the donut/ donut hole). Edges all have gaussian blurr.
%IT CURRENTLY RUNS FOR 414 SECONDS (6 mins and 54 seconds)
%TR is 800 ms (0.8 s), oversampling at 1 sample per 200 mn, 5 samples per
%condition per run.

%This script is also here to use as a TRAINING SET for the IEM!!!!!!!!!!!!!
%Written by RR, July 2016 for WM distractor experiment 


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
    ScreenHeight = 90; % in cm, 90cm at the scanner!!!!! 
    ViewDistance = 370; % in cm, 370 cm at the scanner!!!! 57cm is ideal distance where 1 cm equals 1 visual degree
    VisAngle = (2*atan2(ScreenHeight/2, ViewDistance))*(180/pi); % visual angle of the whole screen
    p.ppd = p.ScreenSizePixels(4)/VisAngle; % pixels per degree visual angle
    p.MyGrey = 128;
    black=BlackIndex(ScreenNr); white=WhiteIndex(ScreenNr);
    gammacorrect = false;


    
    %----------------------------------------------------------------------
    %OPEN/INIT DATA FILES--------------------------------------------------
    %----------------------------------------------------------------------
    cd(datadir); % and go there to fetch stuff
    if exist(['WM_DistractV2_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_LocalizerPractice.mat']);
        load(['WM_DistractV2_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_LocalizerPractice.mat']);
        runnumber = length(TheData)+1; % set the number of the current run
    else
        runnumber = 1; % if no data file exists this must be the first run
    end
    cd(expdir); % back to where I need to be. go!
    
    

    %----------------------------------------------------------------------
    %DEFINE MAIN PARAMETERS------------------------------------------------
    %----------------------------------------------------------------------
    
    %Timing params
    t.StimTime = 9; %this many second block of flickering checkerboard stimulus (donut or circle)
    t.PhaseReverseFreq = 5; %in Hz
    t.PhaseReverseTime = 1/t.PhaseReverseFreq; %in sec (how long each grating is on the screen for)
    t.ReversalsPerBlock = t.StimTime/t.PhaseReverseTime;
    t.BeginFixation = 9;
    t.EndFixation = 9;
    
    %Experimental params
    p.StimTypes = [1 2]; %Stimulus can be a donut (1), or a circle (2)
    p.StimTypeNames = {'donut';'circle'};
    p.NumBlocksPerStimType = 20; %any even number will do
    p.NumBlocksFixation = 4;
    p.NumBlocks = length(p.StimTypes)*p.NumBlocksPerStimType + p.NumBlocksFixation;
    for n = 1:p.NumBlocks
        p.ChangingFreq(:,n) = CoinFlip(t.ReversalsPerBlock,2/t.ReversalsPerBlock);
    end
    if rem(runnumber,2)==0 %on even run numbers this is the order
        p.StimOrder = [1 2 1 2 1 2 1 2 0 ...
            2 1 2 1 2 1 2 1 0 ...
            1 2 1 2 1 2 1 2 0 ...
            2 1 2 1 2 1 2 1 0 ...
            1 2 1 2 1 2 1 2];
    elseif rem(runnumber,2)==1 %on uneven run numbers
        p.StimOrder = [2 1 2 1 2 1 2 1 0 ...
            1 2 1 2 1 2 1 2 0 ...
            2 1 2 1 2 1 2 1 0 ...
            1 2 1 2 1 2 1 2 0 ...
            2 1 2 1 2 1 2 1];
    end
    
    
    %Stimulus params
    p.Smooth_size = round(1*p.ppd); %size of fspecial smoothing kernel
    p.Smooth_sd = round(.5*p.ppd); %smoothing kernel sd
    p.PatchSize = round(2*7*p.ppd); %Size of the patch that is drawn on screen location, so twice the radius, in pixels
    p.OuterDonutRadius = (7*p.ppd)-(p.Smooth_size/2); %Size of donut outsides, automatically defined in pixels.
    p.InnerDonutRadius = (1.5*p.ppd)+(p.Smooth_size/2); %Size of donut insides, automatically defined in pixels.
    p.OuterCircleRadius = (1.5*p.ppd)-(p.Smooth_size/2); %Size of circle outsides
    p.OuterFixationRadius = .2*p.ppd; %outter dot radius (in pixels)
    p.InnerFixationRadius = .1*p.ppd; %set to zero if you a donut-hater
    p.FixColorOut = p.MyGrey; 
    p.FixColorIn = [200 0 226.6]; 
    p.PhaseJitter = randsample(0:359,p.NumBlocks,true)*(pi/180);
    p.SF = 2; %cpd
    p.SF_change = 1.5; 
    SFs = [p.SF p.SF_change];
    p.Contrast = 1;
    p.NumOrientBins = 10; %make this a *multiple of p.NumBlocks* and *divisible by 180*
    p.OrientBins = reshape(1:180,180/p.NumOrientBins,p.NumOrientBins);
    OrientDonut = []; OrientCircle = [];
    for bins = 1:p.NumOrientBins
        OrientDonut = [OrientDonut; randsample(p.OrientBins(:,bins),p.NumBlocksPerStimType/p.NumOrientBins)];
        OrientCircle = [OrientCircle; randsample(p.OrientBins(:,bins),p.NumBlocksPerStimType/p.NumOrientBins)];
    end
    p.Orient = reshape([Shuffle(OrientDonut) Shuffle(OrientCircle)]',1,(length(p.StimTypes)*p.NumBlocksPerStimType));
    
    t.MeantToBeTime = t.BeginFixation + (t.StimTime*p.NumBlocks) + t.EndFixation;
    
    
    %----------------------------------------------------------------------
    %MAKE THE GRATING STIMULI----------------------------------------------
    %----------------------------------------------------------------------
    % start with a meshgrid
    X=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5; Y=-0.5*p.PatchSize+.5:1:.5*p.PatchSize-.5;
    [x,y] = meshgrid(X,Y);
    % make a donut with gaussian blurred edge
    donut_out = x.^2 + y.^2 <= (p.OuterDonutRadius)^2;
    donut_in = x.^2 + y.^2 >= (p.InnerDonutRadius)^2;
    donut = donut_out.*donut_in;
    donut = filter2(fspecial('gaussian', p.Smooth_size, p.Smooth_sd), donut);
    % make a circle with gaussian blurred edge
    circle_out = x.^2 + y.^2 <= (p.OuterCircleRadius)^2;
    circle = filter2(fspecial('gaussian', p.Smooth_size, p.Smooth_sd), circle_out);
    % now make a matrix with with all my stimuli for all my trials
    StimuliAreHere = NaN(p.PatchSize,p.PatchSize,(length(p.StimTypes)*p.NumBlocksPerStimType),2,2); %last two dimensions: 2 phases and 2 sf's (normal & deviant)
    order = p.StimOrder(p.StimOrder~=0);
    for n = 1:(length(p.StimTypes)*p.NumBlocksPerStimType)
        for changestims = 1:2 %normal or sf-changing stimuli   
        sine = (sin(SFs(changestims)/p.ppd*2*pi*(y.*sin(p.Orient(n)*pi/180)+x.*cos(p.Orient(n)*pi/180))-p.PhaseJitter(n)));
        sine2 = (sin(SFs(changestims)/p.ppd*2*pi*(y.*sin(p.Orient(n)*pi/180)+x.*cos(p.Orient(n)*pi/180))-rem(p.PhaseJitter(n) + pi,2*pi)));
        if order(n) == 1 %if stimulus this block is a donut
            stim_phase1 = sine.*donut; 
            stim_phase2 = sine2.*donut;
        elseif order(n) == 2 %if stimulus this block is a circle
            stim_phase1 = sine.*circle;  
            stim_phase2 = sine2.*circle;
        end
        % give the grating the right contrast level and scale it
        StimuliAreHere(:,:,n,1,changestims) = max(0,min(255,p.MyGrey+p.MyGrey*(p.Contrast * stim_phase1)));
        StimuliAreHere(:,:,n,2,changestims) = max(0,min(255,p.MyGrey+p.MyGrey*(p.Contrast * stim_phase2)));
        end
    end
    clear x y X Y donut circle sine stim_phase1 stim_phase2
    
    
    
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
    p.Responses = zeros(t.ReversalsPerBlock,p.NumBlocks);
   
    
    
    %----------------------------------------------------------------------
    %WELCOME MESSAGE & WAIT FOR TRIGGER------------------------------------
    %----------------------------------------------------------------------
    % welcome welcome ya'll
    Screen(window,'TextSize',20);
    Screen('FillOval', window, p.FixColorOut, [CenterX-p.OuterFixationRadius CenterY-p.OuterFixationRadius CenterX+p.OuterFixationRadius CenterY+p.OuterFixationRadius])
    Screen('FillOval', window, p.FixColorIn, [CenterX-p.InnerFixationRadius CenterY-p.InnerFixationRadius CenterX+p.InnerFixationRadius CenterY+p.InnerFixationRadius])
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
    ListenChar;
    
    
    
    GlobalTimer = 0; %this timer keeps track of all the timing in the experiment. TOTAL timing.
    TimeUpdate = t.StartTime; %what time issit now?
    %Present begin fixation
    Screen('FillOval', window, p.FixColorOut, [CenterX-p.OuterFixationRadius CenterY-p.OuterFixationRadius CenterX+p.OuterFixationRadius CenterY+p.OuterFixationRadius])
    Screen('FillOval', window, p.FixColorIn, [CenterX-p.InnerFixationRadius CenterY-p.InnerFixationRadius CenterX+p.InnerFixationRadius CenterY+p.InnerFixationRadius])
    Screen('Flip', window);
    %TIMING!:
    GlobalTimer = GlobalTimer + t.BeginFixation;
    TimePassed = 0; %Flush the time the previous event took
    while (TimePassed<t.BeginFixation) %For as long as the cues are on the screen...
        TimePassed = GetSecs-TimeUpdate;%And determine exactly how much time has passed since the start of the expt.
    end
    TimeUpdate = TimeUpdate + t.BeginFixation;
    ListenChar(2);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% A TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    runner = 0;
    for n = 1:p.NumBlocks
        t.BlockStartTime(n) = GlobalTimer; %Get the starttime of each single block (relative to experiment start)
        TimeUpdate = t.StartTime + t.BlockStartTime(n);
        if p.StimOrder(n) ~=0;
            runner = runner+1; 
        end
        
        for revs = 1:t.ReversalsPerBlock
            if rem(revs,2)==0 %if this repetition is an even number
                StimToDraw = Screen('MakeTexture', window, StimuliAreHere(:,:,runner,1,1));
            end
            if rem(revs,2)==1 %if this repetition is an odd number
                StimToDraw = Screen('MakeTexture', window, StimuliAreHere(:,:,runner,2,1));
            end
            if rem(revs,2)==0 && p.ChangingFreq(revs,n)==1 %if this repetition is an even number and should be changed
                StimToDraw = Screen('MakeTexture', window, StimuliAreHere(:,:,runner,1,2));
            end
            if rem(revs,2)==1 && p.ChangingFreq(revs,n)==1 %if this repetition is an odd number and should be changed
                StimToDraw = Screen('MakeTexture', window, StimuliAreHere(:,:,runner,2,2));
            end
            if p.StimOrder(n) ~=0
                Screen('DrawTexture', window, StimToDraw, [], MyPatch, [], 0);
            end
            Screen('FillOval', window, p.FixColorOut, [CenterX-p.OuterFixationRadius CenterY-p.OuterFixationRadius CenterX+p.OuterFixationRadius CenterY+p.OuterFixationRadius])
            Screen('FillOval', window, p.FixColorIn, [CenterX-p.InnerFixationRadius CenterY-p.InnerFixationRadius CenterX+p.InnerFixationRadius CenterY+p.InnerFixationRadius])
            Screen('DrawingFinished', window);
            Screen('Flip', window);
            Screen('Close', StimToDraw);
            %TIMING!:
            GlobalTimer = GlobalTimer + t.PhaseReverseTime;
            ReversalTimePassed = 0; %Flush time passed.
            while (ReversalTimePassed<t.PhaseReverseTime) %As long as the stimulus is on the screen...
                ReversalTimePassed = GetSecs-TimeUpdate; %And determine exactly how much time has passed since the start of the expt.
                if CharAvail
                    [press] = GetChar;
                    if strcmp(press,'b') %scanner buttons are: b y g r (left-to-right)
                        foo = str2double(press); 
                        if isnan(foo)
                            p.Responses(revs,n) =1;
                        end
                    end
                    if strcmp(press,'q')
                        Screen('CloseAll');
                        ListenChar(1); %Unsuppressed keyboard mode
                        if exist('OriginalCLUT','var')
                            if exist('ScreenNr','var')
                                Screen('LoadCLUT', ScreenNr, OriginalCLUT);
                            else
                                Screen('LoadCLUT', 0, OriginalCLUT);
                            end
                        end
                    end
                end
            end
            TimeUpdate = TimeUpdate + t.PhaseReverseTime; %Update Matlab on what time it is.
        end
        FlushEvents('keyDown'); %First discard all characters from the Event Manager queue
        
    end %end of experimental trial/block loop
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%% END OF TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %End fixation:
    Screen('FillOval', window, p.FixColorOut, [CenterX-p.OuterFixationRadius CenterY-p.OuterFixationRadius CenterX+p.OuterFixationRadius CenterY+p.OuterFixationRadius])
    Screen('FillOval', window, p.FixColorIn, [CenterX-p.InnerFixationRadius CenterY-p.InnerFixationRadius CenterX+p.InnerFixationRadius CenterY+p.InnerFixationRadius])
    Screen('Flip', window);
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
    FlushEvents('keyDown'); %First discard all characters from the Event Manager queue
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
    
    
    
    %----------------------------------------------------------------------
    %SLOPPY LOOK AT BEHAVIORAL PERFOPRMANCE--------------------------------
    %----------------------------------------------------------------------
    hit=0; miss=0; resp_window=6;
    changes_happened = reshape(p.ChangingFreq,size(p.ChangingFreq,1)*size(p.ChangingFreq,2),1);
    responses_happened = [reshape(p.Responses,size(p.Responses,1)*size(p.Responses,2),1); resp; zeros(resp_window-1,1)];
    for allrevs = 1:t.ReversalsPerBlock*p.NumBlocks
       if changes_happened(allrevs) == 1 && sum(responses_happened(allrevs+1:allrevs+resp_window))>0
           hit = hit+1;
       elseif changes_happened(allrevs) == 1 && sum(responses_happened(allrevs+1:allrevs+resp_window))==0
           miss = miss+1;
       end
    end
    disp(' ');disp([' YOU DETECTED ' num2str(hit*100/sum(changes_happened)) '% OF THE CHANGES!'])
    if sum(responses_happened) > sum(changes_happened)
        disp(' '); disp(['HOLD ON... YOU MADE ' num2str((sum(responses_happened)-sum(changes_happened))) ' FALSE ALARMS...']);
        disp(' '); disp('PLEASE ONLY PRESS WHEN YOU DETECT A CHANGE');
    end
    
    
      
    %----------------------------------------------------------------------
    %SAVE OUT THE DATA-----------------------------------------------------
    %----------------------------------------------------------------------
    cd(datadir); 
    %First I make a list of variables to save:
    TheData(runnumber).info = info;
    TheData(runnumber).t = t;
    TheData(runnumber).p = p;
    eval(['save WM_DistractV2_S', num2str(info.SubNum), '_', num2str(info.TheDate), '_LocalizerPractice.mat TheData'])
    cd(expdir)
    

%     %Presented orientations were
%     figure;hist(p.Orient,1:1:180);
%     hold on
%     scatter([p.OrientBins(1,:)-.5 180.5], repmat(.5,1,p.NumOrientBins+1),'or')
%     set(gca,'XLim',[0 181]);
    


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

