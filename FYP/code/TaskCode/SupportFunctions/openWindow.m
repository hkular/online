function win = openWindow(p) % open up the window!

%   p.windowed = 0; %%% 1  == smaller screen for debugging; 0 === full-sized screen for experiment
if p.windowed
    win.screenNumber = min(Screen('Screens'));

    [win.onScreen rect] = Screen('OpenWindow', win.screenNumber, [0 0 0],[0 0 1024 768],[],[],[]);
    win.screenX = 1024;
    win.screenY = 768;
    win.screenRect = [0 0 1600 1200];
    win.centerX = (1024)/2; % center of screen in X direction
    win.centerY = (768)/2; % center of screen in Y direction
    win.centerXL = floor(mean([0 win.centerX])); % center of left half of screen in X direction
    win.centerXR = floor(mean([win.centerX win.screenX])); % center of right half of screen in X direction
    % % Compute foreground and fixation rectangles
    win.foreRect = round(win.screenRect./1.35);
    win.foreRect = CenterRect(win.foreRect,win.screenRect);
else
    %%% new code in case there are multipel monitors
    if numel(Screen('Screens')) > 1
        win.screenNumber = 1;
    else
        win.screenNumber = 0;
    end
    
    [win.onScreen rect] = Screen('OpenWindow', win.screenNumber, [0 0 0],[],[],[],[]);
    [win.screenX, win.screenY] = Screen('WindowSize', win.onScreen); % check resolution
    win.screenRect  = [0 0 win.screenX win.screenY]; % screen rect
    win.centerX = win.screenX * 0.5; % center of screen in X direction
    win.centerY = win.screenY * 0.5; % center of screen in Y direction
    win.centerXL = floor(mean([0 win.centerX])); % center of left half of screen in X direction
    win.centerXR = floor(mean([win.centerX win.screenX])); % center of right half of screen in X direction
    % % Compute foreground and fixation rectangles
    win.foreRect = round(win.screenRect./1.35);
    win.foreRect = CenterRect(win.foreRect,win.screenRect);
    
    HideCursor; % hide the cursor since we're not debugging
end

Screen('BlendFunction', win.onScreen, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% basic drawing and screen variables
win.black    = BlackIndex(win.onScreen);
win.white    = WhiteIndex(win.onScreen);
win.gray     = mean([win.black win.black win.white]);

win.backColor = win.black;
win.foreColor = win.black;

%%% 9 colors mat
win.colors_9 = [255 0 0; ... % red
    0 255 0; ...% green
    0 0 255; ...% blue
    255 255 0; ... % yellow
    255 0 255; ... % magenta
    0 255 255; ... % cyan
    255 255 255; ... % white
    1 1 1; ... %black
    255 128 0]; % orange!

%%%% 7 colors mat
win.colors_7 = [255 0 0;... % red
    0 255 0;... %green
    0 0 255;... % blue
    255 255 0;... % yellow
    255 0 255; ... % magenta
    255 255 255;... % white
    0 0 0]; % black

win.fontsize = 24;

win.probeRect = [win.screenX-40 10 win.screenX-10 40]; %%%% Upper right Corner!!!!!

% make a dummy call to GetSecs to load the .dll before we need it
dummy = GetSecs; clear dummy;
end