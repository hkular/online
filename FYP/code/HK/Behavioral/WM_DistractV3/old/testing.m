
%% check screen 
[window] = Screen('OpenWindow',ScreenNr, p.MyGrey,[],[],2);
 Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
    Screen('DrawText',window, 'Experimenter press t to go', p.ScreenSizePixels(1)+10, p.ScreenSizePixels(2)+10, white);
    Screen('DrawText',window, 'Fixate', CenterX-100, CenterY, black); % change location potentially
    Screen('Flip', window);
%%



for n = 1:21
if TheData.data.Response(n) == TheData.p.TestOrient(n)
    TheData.data.Response(n) = NaN
end
end


% draw circles
%Screen('Preference', 'SkipSyncTests', 1);

%[window, window_size] = Screen('OpenWindow', 0, p.MyGrey, [],[], [])

Screen('FillRect',window,p.MyGrey);
      Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius])
        Screen('DrawingFinished', window);
        Screen('Flip', window);
Screen('FillOval', window, p.MyGrey, [CenterX-(p.InnerDonutRadius-p.Smooth_size/2) CenterY-(p.InnerDonutRadius-p.Smooth_size/2) CenterX+(p.InnerDonutRadius-p.Smooth_size/2) CenterY+(p.InnerDonutRadius-p.Smooth_size/2)]);
Screen('FillOval', window, p.FixColor, [CenterX-p.OuterFixRadius CenterY-p.OuterFixRadius CenterX+p.OuterFixRadius CenterY+p.OuterFixRadius]);
           



%--------
    % 5D array - target position, x_size, y_size, numtrials, spatial phase
    % initialize with middle grey (background color), then fill in a
    % 1,2,or 4 gratings as needed for each trial.  
    TargetsAreHere = ones(4,p.PatchSize,p.PatchSize,p.NumTrials,2) * p.MyGrey; %last dimension: 2 phases
    runner = 1; %Will count within-block trials
    
    % different for each set size
    nTrialsPerBlock = 61 % 183/3 = 61
    startTrialThisBlock = (nTrialsPerBlock * currentBlock) - nTrialsPerBlock + 1
    
    for n = startTrialThisBlock:(startTrialThisBlock+nTrialsPerBlock) 
        
        
        ori_cnt = 1
        for pos = TrialStuff(n).position
            sine = (sin(p.SF/p.ppd*2*pi*(y1.*sin(TrialStuff(n).orient*pi/180)+x1.*cos(TrialStuff(n).orient(ori_cnt)*pi/180))-p.PhaseJitterTarget(runner)));
            sine2 = (sin(p.SF/p.ppd*2*pi*(y1.*sin(TrialStuff(n).orient*pi/180)+x1.*cos(TrialStuff(n).orient(ori_cnt)*pi/180))-rem(p.PhaseJitterTarget(runner) + pi,2*pi)));
            stim_phase1 = sine.*donuts{TrialStuff(n).position};
            stim_phase2 = sine2.*donuts{TrialStuff(n).position};
            %Give the grating the right contrast level and scale it
            TargetsAreHere(pos,:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase1))); % TrialStuff(n).contrast
            TargetsAreHere(pos,:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase2)));
            ori_cnt = ori_cnt + 1
        end
        
        runner = runner + 1
    end
            
            
  
        %% Target rendering
        for revs = 1:t.TargetTime/t.PhaseReverseTime
            for pos = 1:4
                if rem(revs,2)==0 %if this repetition is an even number
                    StimToDraw = Screen('MakeTexture', window, TargetsAreHere(pos,:,:,n,1)); % 
                end
                if rem(revs,2)==1 %if this repetition is an odd number
                    StimToDraw = Screen('MakeTexture', window, TargetsAreHere(pos,:,:,n,2)); % 
                end
                Screen('DrawTexture', window, StimToDraw, [], MyPatch, [], 0);
                
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
        
        
        
        %% old make targets
        
 for n = (p.TrialNumGlobal+1):(p.TrialNumGlobal+p.NumTrials)
        
        
        if TrialStuff(n).setsize == 1
            sine = (sin(p.SF/p.ppd*2*pi*(y1.*sin(TrialStuff(n).orient*pi/180)+x1.*cos(TrialStuff(n).orient*pi/180))-p.PhaseJitterTarget(runner)));
            sine2 = (sin(p.SF/p.ppd*2*pi*(y1.*sin(TrialStuff(n).orient*pi/180)+x1.*cos(TrialStuff(n).orient*pi/180))-rem(p.PhaseJitterTarget(runner) + pi,2*pi)));
            stim_phase1 = sine.*donuts{TrialStuff(n).position};
            stim_phase2 = sine2.*donuts{TrialStuff(n).position};
            %Give the grating the right contrast level and scale it
            TargetsAreHere(TrialStuff(n).position,:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase1))); % TrialStuff(n).contrast
            TargetsAreHere(:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase2)));
        elseif TrialStuff(n).setsize == 2
            for i= 1:2
            sine = (sin(p.SF/p.ppd*2*pi*(y2.*sin(TrialStuff(n).orient(i)*pi/180)+x1.*cos(TrialStuff(n).orient(i)*pi/180))-p.PhaseJitterTarget(runner)));
            sine2 = (sin(p.SF/p.ppd*2*pi*(y2.*sin(TrialStuff(n).orient(i)*pi/180)+x1.*cos(TrialStuff(n).orient(i)*pi/180))-rem(p.PhaseJitterTarget(runner) + pi,2*pi)));
            stim_phase1 = sine.*donuts{TrialStuff(n).position(i)};
            stim_phase2 = sine2.*donuts{TrialStuff(n).position(i)};
            %Give the grating the right contrast level and scale it - not
            %sure about this part
            TargetsAreHere(:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase1)));
            TargetsAreHere(:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase2)));
            end
        elseif TrialStuff(n).setsize == 4
            for i= 1:4
            sine = (sin(p.SF/p.ppd*2*pi*(y2.*sin(TrialStuff(n).orient(i)*pi/180)+x1.*cos(TrialStuff(n).orient(i)*pi/180))-p.PhaseJitterTarget(runner)));
            sine2 = (sin(p.SF/p.ppd*2*pi*(y2.*sin(TrialStuff(n).orient(i)*pi/180)+x1.*cos(TrialStuff(n).orient(i)*pi/180))-rem(p.PhaseJitterTarget(runner) + pi,2*pi)));
            stim_phase1 = sine.*donuts{TrialStuff(n).position(i)};
            stim_phase2 = sine2.*donuts{TrialStuff(n).position(i)};
            %Give the grating the right contrast level and scale it - not
            %sure about this part
            TargetsAreHere(:,:,runner,1) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase1)));
            TargetsAreHere(:,:,runner,2) = max(0,min(255,p.MyGrey+p.MyGrey*(p.ContrastTarget * stim_phase2)));
            end
        end
       
        runner = runner+1;
    end
    clear sine stim1_phase1 stim1_phase2 stim2_phase1 stim2_phase2 stim3_phase1 stim3_phase2 stim4_phase1 stim4_phase2 
    
            
   