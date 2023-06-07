%% Function to run a basic "additional singleton" task.
%
% Participants search an array of shapes (heterogeneous or homogeneous)
% for a particular target (e.g., green square). Some trials can contain a
% color singleton distractor (e.g., red circle).
%
% Written by Kirsten Adam, January 2019

function Additional_singleton_task_1block_popout_2colors(p,win,r)
%--------------------------------------------------------------------------
% Set up general preferences
%--------------------------------------------------------------------------
%----EEG stuff----------------------------------------------------------
if p.portCodes == 1
    ppdev_mex('Open', 1);
end

%----Screen stuff----------------------------------------------------------
w = win.onScreen;
win.hz = Screen('NominalFrameRate', w); % get refresh rate in Hz
win.ifi = Screen('GetFlipInterval', w); % get inter-flip interval (i.e. the refresh rate) -- Note, this is more precisely measured by PTB than "frame rate", so use this for timing
win.halfifi = win.ifi ./ 2;
win.fps = 1./win.ifi;
Priority(MaxPriority(w)); %give the current window max priority

%----Keyboard stuff--------------------------------------------------------
KbCheck([GetKeyboardIndices()]);
KbName('UnifyKeyNames'); %added for Windows  compatibility
horizontalKey = KbName('z');
verticalKey = KbName('/?');
p_key = KbName('p');
space = KbName('space');
escape = KbName('escape');
s_key = KbName('s');

% keyboard = min(GetKeyboardIndices());
% keyboard = min(keyboard);

ListenChar(2);
HideCursor;

%----Prefs-----------------------------------------------------------------
prefs = getPrefs(win);

prefs.date_time_start = clock;
%-------------------------------------------------------------------------
% Set the random seed: To regenerate the same state for the random number generator,
% we would type " rng(p.rng_settings) to do so.
%-------------------------------------------------------------------------
rng('default')
rng('shuffle')
prefs.rng_settings = rng; % Save the random seed settings!!
%--------------------------------------------------------------------------
% Set up save file
%--------------------------------------------------------------------------
fileName = [p.root,filesep,'Data',filesep,num2str(p.subNum), '_search_8_run',char(num2str(r)),'.mat'];
if p.subNum ~= 0
    if exist(fileName)
        Screen('CloseAll');
        msgbox('File already exists!', 'modal')
        return;
    end
end
%--------------------------------------------------------------------------
% Allocate space to save data
%--------------------------------------------------------------------------
data = struct();

data.rt =  NaN(prefs.nTrials,prefs.nBlocks); % Response time
data.acc = NaN(prefs.nTrials,prefs.nBlocks); % Accuracy
data.responseMade =  NaN(prefs.nTrials,prefs.nBlocks); % Did they press a key at all?
data.responseKey =  NaN(prefs.nTrials,prefs.nBlocks); % Which key did they press (1 = horizontal, 2 = vertical);

data.trialOrder = NaN(prefs.nTrials,prefs.nBlocks); % Randomized order that we read out from the design matrix!
data.setSize = NaN(prefs.nTrials,prefs.nBlocks); % Search set size
data.distractorPresent = NaN(prefs.nTrials,prefs.nBlocks); % Distractor present (1) or absent (0)
data.targetOrient = NaN(prefs.nTrials,prefs.nBlocks); % Target line is horizontal (1) or vertical (2)
data.targetColor = NaN(prefs.nTrials,prefs.nBlocks); % Target color is green (1) or red (2)
data.targetLoc = NaN(prefs.nTrials,prefs.nBlocks);
data.distractLoc = NaN(prefs.nTrials,prefs.nBlocks);

%data.iti_jitter = NaN(prefs.nTrials,prefs.nBlocks); % Jitter added to the minimum iti
data.iti = NaN(prefs.nTrials,prefs.nBlocks); % save the final TOTAL iti for each trial

maxSS = max(prefs.setSize);
data.item_coords = NaN(prefs.nTrials,prefs.nBlocks,maxSS, 2);
data.item_colors = NaN(prefs.nTrials,prefs.nBlocks,maxSS, 3);
data.item_shapes = NaN(prefs.nTrials,prefs.nBlocks,maxSS);
data.item_lines = NaN(prefs.nTrials,prefs.nBlocks,maxSS);

%--------------------------------------------------------------------------
% Present instructions
%--------------------------------------------------------------------------
if r == 1
Screen(win.onScreen, 'DrawText', 'Find the square item as fast as you can.', win.centerX-250, win.centerY-100, [255 255 255]);
Screen(win.onScreen, 'DrawText', 'Press the "z" key if the line is horizontal --"', win.centerX-250, win.centerY-50, [255 255 255]);
Screen(win.onScreen, 'DrawText', 'Press the "?" key if the line is vertical |"', win.centerX-250, win.centerY-0, [255 255 255]);
end
Screen(win.onScreen, 'DrawText', 'Press spacebar to begin.', win.centerX-250, win.centerY+50, [255 255 255]);

Screen('Flip',win.onScreen);

% Wait for a button press to continue with next block
while 1
    [keyIsDown,secs,keyCode]=KbCheck([GetKeyboardIndices()]);
    if keyIsDown
        kp = find(keyCode);
        if kp == space
            break;
        end
    end
end

Screen('Flip',win.onScreen);

%--------------------------------------------------------------------------
% Block loop
%--------------------------------------------------------------------------
for b = 1:prefs.nBlocks
    
    data.trialOrder(:,b) = randperm(prefs.nTrials);
    data.setSize(:,b) = prefs.setSize(prefs.design(data.trialOrder(:,b),1));
    data.distractorPresent(:,b) = prefs.distractorPresent(prefs.design(data.trialOrder(:,b),2));
    data.targetOrient(:,b) = prefs.targetOrient(prefs.design(data.trialOrder(:,b),3));
%     data.targetColor(:,b) = prefs.targetColor(prefs.design(data.trialOrder(:,b),4));
    data.iti(:,b) = prefs.iti(prefs.design(data.trialOrder(:,b),5));
    
    %----------------------------------------------------------------------
    % Trial loop
    %----------------------------------------------------------------------
    for t = 1:prefs.nTrials
        
        % Just draw fixation point
        Screen('DrawDots', win.onScreen, [win.centerX, win.centerY], prefs.fixationSize, 255);
        Screen('Flip',win.onScreen);
        
        %------------------------------------------------------------------
        % Caluclate everything for the trial, then do WaitSecs('UntilTime')
        % to make the ITI *exactly* the same after accounting for our texture drawing /
        % caluclation!
        %------------------------------------------------------------------
        tCalc = GetSecs;

        data.targetColor(t,b) = randi(2);
        
        % Basic info for this trial
        setSize = data.setSize(t,b);
        distract = data.distractorPresent(t,b);
        targOrient = data.targetOrient(t,b);
        targColor = data.targetColor(t,b);
        
        % Get item locations (points which we will later center stimuli
        % on! Add jitter to them, too!
        itemRadius = prefs.arrayRadius;
        degreeStep = round(360/setSize);
%         rotation = randi([round(-degreeStep/2),round(degreeStep/2)],1,1);
        rotation = 45; % use fixed locations for MRI experiment!! 
        coords = [sind([0:degreeStep:(360-degreeStep)] + rotation)'.* itemRadius, cosd([0:degreeStep:(360-degreeStep)] + rotation)'.* itemRadius] + repmat([win.centerX win.centerY], setSize, 1);
        rects = [coords(:, 1)-prefs.stimRadius_circle , coords(:, 2)-prefs.stimRadius_circle, coords(:, 1)+prefs.stimRadius_circle, coords(:, 2)+prefs.stimRadius_circle];
        
        data.item_coords(t,b,1:setSize,:) = coords;
        
        % Select one item location to be target, distractor, rest non-targets
        allLocs = 1:setSize;
        targetLoc = randi(setSize,1,1);
        distractLoc = PsychRandSample(allLocs(~ismember(allLocs,targetLoc)),[1,1]);
        ntLocs = allLocs(~ismember(allLocs,[targetLoc,distractLoc]));
        
        data.targetLoc(t,b) = targetLoc;
        data.distractLoc(t,b) = distractLoc;
        
        % Set up colors for target, non-targets, and distractors
        if targColor == 1 % target color is green
            tCol = prefs.green;
            dCol = prefs.red;
        else
            tCol = prefs.red;
            dCol = prefs.green;
        end
        trial_colors = repmat(tCol,setSize,1); % Make all the target color!
        if distract == 1
            trial_colors(distractLoc,:) = dCol;
        end
        
        data.item_colors(t,b,1:setSize,:) = trial_colors;
        
        % Assign shapes to each location!
        % Possible shapes (0 = circle, otherwise = # of sides...)
        all_shapes = Shuffle([prefs.possibleShapes]); % possible shapes
        item_shapes = all_shapes(1:setSize);
        item_shapes(targetLoc) = 4; % draw a square at the target location!
        data.item_shapes(t,b,1:setSize) = item_shapes;
        
        % Set up horizontal and vertical lines for target, non-targets, and
        % distractor
        item_lines = randi(1:2,[1,setSize]); % randomly decide if horizontal or vertical
        if targOrient==1 % if target orientation is supposed to be vertical!
            item_lines(targetLoc) = 1;
        else
            item_lines(targetLoc) = 2;
        end
        data.item_lines(t,b,1:setSize) = item_lines;
        
        % set up the trial port code
        cond_code = (setSize*10) + distract;
        %------------------------------------------------------------------
        % Show the search array and get a response!
        %------------------------------------------------------------------
        % DRAW SEARCH ARRAY
        Screen('DrawDots', win.onScreen, [win.centerX, win.centerY], prefs.fixationSize, 255); % Fixation
        
        for item = 1:setSize
            
            if item_shapes(item) == 0 % Draw a circle!
                Screen('FrameOval',win.onScreen,trial_colors(item,:),rects(item,:)',prefs.penWidth);
            else % Draw a polygon!
                % Demo here: http://peterscarfe.com/framedpolygondemo.html
                numSides = item_shapes(item);
                anglesDeg = linspace(0,360,numSides+1);
                anglesRad = anglesDeg * (pi/180);
                radius = prefs.stimRadius;
                
                xPosVector = cos(anglesRad) .* radius + coords(item,1); % +xCoord
                yPosVector = sin(anglesRad) .* radius + coords(item,2); % + yCoord
                
                Screen('FramePoly',win.onScreen,trial_colors(item,:),[xPosVector;yPosVector]', prefs.penWidth);
            end
            
            % Now draw the horizontal or vertical line inside!
            if item_lines(item) == 1 % horizontal
                c = coords(item,:);
                Screen('DrawLine',win.onScreen,prefs.white, c(:,1) - prefs.lineLength, c(:,2), c(:,1) + prefs.lineLength, c(:,2),prefs.penWidth);
            else
                c = coords(item,:);
                Screen('DrawLine',win.onScreen,prefs.white, c(:,1), c(:,2) - prefs.lineLength, c(:,1) , c(:,2) + prefs.lineLength,prefs.penWidth);
            end
        end
        
        Screen('DrawingFinished',win.onScreen) % Tell PTB we're done drawing!
        % Continue waiting the full ITI before flipping...
        WaitSecs('UntilTime',tCalc + data.iti(t,b) - win.halfifi); % subtract a half frame to make sure we don't miss it
        
        Screen('Flip',win.onScreen);
        
        % Initialize RT
        rtStart = GetSecs;
        
        response = 0; responseKey = 0;
        % Check for a response and score it!
        tic
        while toc < prefs.responseWait % if they make a response move onto the next trial (save a bunch of time!)
            % Check for a response
            [keyIsDown, secs, keyCode] =KbCheck([GetKeyboardIndices()]);
            if response == 0
            if sum(keyCode)==1
                if keyCode(horizontalKey)
                    if response == 0
                        response = 1;
                        rtEnd = GetSecs;
                        responseKey = 1; % pressed horizontal
                        if p.portCodes
                            write_parallel(93)
                        end
                    end
                elseif keyCode(verticalKey)
                    if response == 0
                        response = 1;
                        rtEnd = GetSecs;
                        responseKey = 2; % pressed vertical
                        if p.portCodes
                            write_parallel(93)
                        end
                    end
                elseif keyCode(p_key) % Pause the experiment then continue!
                    
                    Screen(win.onScreen, 'DrawText', 'Experiment is paused...Click to continue.', win.centerX-250, win.centerY-0, [255 255 255]);
                    Screen('Flip',win.onScreen);
                    
                    GetClicks(win.onScreen);
                    
                    Screen('Flip',win.onScreen);
                    
                elseif keyCode(escape)
                    save(fileName,'p','prefs','win','data');
                    Screen('CloseAll')
                    ListenChar(1);
                    ShowCursor;
                    if p.portCodes
                        ppdev_mex('Close', 1); % Close port.
                    end
                    return
                end
            end
            end
        end
        
        % Save response and accuracy information!
        data.responseMade(t,b) = response; % did they make a response? yes or no.
        data.responseKey(t,b) = responseKey; % which button did they press?
        if response
            data.rt(t,b) = rtEnd - rtStart; % response time
        end
        
        if responseKey == 1 && targOrient == 1
            data.acc(t,b) = 1;
        elseif responseKey == 2 && targOrient == 2
            data.acc(t,b) = 1;
        else
            data.acc(t,b) = 0;
        end
        
    end % End trial loop
    
    %----------------------------------------------------------------------
    %  BREAK WITH EACH BLOCK
    %----------------------------------------------------------------------
    % save data file at the end of each block
    save(fileName,'p','prefs','win','data');
    % tell subjects that they've finished the current block / the experiment
    if r < p.numRuns
        tic
        while toc < prefs.breakLength*60
            tocInd = round(toc);
            Screen('FillRect',win.onScreen,win.foreColor);            % Draw the foreground win
            Screen(win.onScreen, 'DrawText', 'Take a break.', win.centerX-110, win.centerY-75, [255 255 255]);
            Screen(win.onScreen, 'DrawText',['Time Remaining: ',char(num2str((prefs.breakLength*60)-tocInd))], win.centerX-110, win.centerY-40, [255 0 0 ]);
    		Screen(win.onScreen, 'DrawText', ['Block ',num2str(r),' of ',num2str(p.numRuns),' completed.'], win.centerX-110, win.centerY+20, [255 255 255]);

            % Give feedback
            block_acc = nanmean(data.acc(:,b))*100;
            text1 = sprintf('Average Accuracy = %.1f Percent',block_acc);
            block_rt = nanmedian(data.rt(:,b));
            text2 = sprintf('Average Speed = %.2f sec',block_rt);
            Screen(win.onScreen, 'DrawText', text1, win.centerX-110, win.centerY+75, [255 255 255]);
            Screen(win.onScreen, 'DrawText', text2, win.centerX-110, win.centerY+115, [255 255 255]);
            Screen('Flip', win.onScreen);
        end
        
        Screen(win.onScreen, 'DrawText', 'Press space to continue.', win.centerX-110, win.centerY-75, [255 255 255]);
        % Give feedback
        block_acc = nanmean(data.acc(:,b))*100;
        text1 = sprintf('Average Accuracy = %.1f Percent',block_acc);
        block_rt = nanmedian(data.rt(:,b));
        text2 = sprintf('Average Speed = %.2f seconds',block_rt);
        Screen(win.onScreen, 'DrawText', text1, win.centerX-110, win.centerY+75, [255 255 255]);
        Screen(win.onScreen, 'DrawText', text2, win.centerX-110, win.centerY+115, [255 255 255]);
        Screen('Flip', win.onScreen);
        
        % Wait for a spacebar press to continue with next block
        while 1
            [keyIsDown,secs,keyCode]=KbCheck([GetKeyboardIndices()]);
            if keyIsDown
                kp = find(keyCode);
                if kp == space
                    break;
                end
            end
        end
        
    end
    
    if r == p.numRuns
        
        Screen('TextSize',win.onScreen,24);
        Screen('TextFont',win.onScreen,'Arial');

            Screen(win.onScreen, 'DrawText', 'Finished! Please see the experimenter.', win.centerX-250, win.centerY-75, [255 255 255]);
        Screen('Flip', win.onScreen);
        
        % Wait for a spacebar press to continue with next block
        while 1
            [keyIsDown,secs,keyCode]=KbCheck([GetKeyboardIndices()]);
            if keyIsDown
                kp = find(keyCode);
                if kp == space
                    break;
                end
            end
        end
        
    end
    
    
end % End block loop

%--------------------------------------------------------------------------
% Save everything
%--------------------------------------------------------------------------
prefs.date_time_end = clock;

save(fileName,'p','prefs','win','data');

if p.portCodes
    ppdev_mex('Close', 1); % Close port.
end

ListenChar(1);
ShowCursor;
end
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
% EXTRA FUNCTIONS
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------


%--------------------------------------------------------------------------
% BASIC PREFERENCES
%--------------------------------------------------------------------------
function prefs = getPrefs(win)

prefs = struct();

%--------------------------------------------------------------------------
% Timing parameters
%--------------------------------------------------------------------------
%prefs.iti = .6; % Minimum ITI (without jitter...)
%prefs.jitter_amount = .5; % amount of jitter in ITI
%prefs.jitter_ports = .1; % add extra jitter for sending trial and block port codes (if running EEG)
prefs.responseWait = 2; % How long to wait to collect a response
prefs.breakLength = .5; % length of block break (in MINUTES)
%--------------------------------------------------------------------------
% Stimulus paramaters
%--------------------------------------------------------------------------
prefs.fixationSize = 7;
prefs.monWidth = 39;   % horizontal dimension of viewable screen (cm)
prefs.monHeight = 29.5; % vertical distance (cm) 
prefs.vDist = 52;   % viewing distance (cm)
prefs.arrayRadius = 261; % (pixels) radius of imaginary circle that stimuli are placed on...
prefs.stimRadius = 90; % (pixels) radius of stimulus bounding box
prefs.stimRadius_circle = (pi*((prefs.stimRadius/2)^2))^(1/2); % make the circle the same AREA as the square... 
prefs.lineLength = 35; % half of the length of the target line (vertical or horizontal)
prefs.penWidth = 3;
prefs.red = [255,0,0];
prefs.green = [0,255,0];
prefs.white = [255,255,255];
prefs.possibleShapes = [0 0 0 0]; % possible non-target and distractor shapes (0 = circle, otherwise # = # of sides in polygon);
%--------------------------------------------------------------------------
% Trial / Experiment Parameters
%--------------------------------------------------------------------------
% Variables in design
prefs.setSize = 4; % Search set size
prefs.distractorPresent = [0,1,1]; % 0 = absent, 1 = present
prefs.targetOrient = [1,2]; % 1 = horizontal, 2 = vertical
prefs.iti = [2 2 2 3 3 5 5 8]; 
prefs.nPerCond = 1; % number of repeats of design matrix to get total # of trials desired per block

% Design matrix
prefs.design = fullfact([length(prefs.setSize),length(prefs.distractorPresent),length(prefs.targetOrient),length(prefs.iti),prefs.nPerCond]);

% Trial counts
prefs.nBlocks = 1;
prefs.nTrials = length(prefs.design);
prefs.totalTrials = prefs.nBlocks*prefs.nTrials;

end
