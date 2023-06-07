%-------------------------------------------------------------------------
% Script to run multiple experiment scripts in a row
%
% Kirsten Adam, last updated 24 Aug 2018
%-------------------------------------------------------------------------
clear all;  % clear everything out!
close all;  % close existing figures
warning('off','MATLAB:dispatcher:InexactMatch');  % turn off the case mismatch warning (it's annoying)
dbstop if error  % tell us what the error is if there is one
AssertOpenGL;    % make sure openGL rendering is working (aka psychtoolbox is on the path)
%-------------------------------------------------------------------------
% Build a GUI to get subject number
%-------------------------------------------------------------------------
prompt = {'Subject Number','Counterbalance Cond','Counterbalance Col','Unique ID','Age',...
    'Gender (M = male, F = female, O = non-binary or other, NR = prefer not to respond)',...
    'Handedness (R = right, L = left, O = other, NR = prefer not to respond)'};            % what information do we want from the subject?
defAns = {'','','','','','',''};                                           %s fill in some stock answers - here the fields are left blank
box = inputdlg(prompt,'Enter Subject Info',1,defAns);       % build the GUI

if length(box) == length(defAns)                            % check to make sure something was typed in
    p.subNum = str2num(box{1}); %%% used to  be num2str... for some reason changed to str2num..... then the stupid eyetracker file didn't save because it was more than 8 characters!!! EFFF.
    p.counterbalance_cond= str2num(box{2});
    p.counterbalance_col= str2num(box{3});
    p.uniqueID = str2num(box{4});
    p.age = str2num(box{5});
    p.gender = upper(box{6});
    p.handedness = upper(box{7});
else
    return;                                                 % if nothing was entered or the subject hit cancel, bail out
end
%-------------------------------------------------------------------------
% save date and time!
%-------------------------------------------------------------------------
p.date_time_session = clock;
%-------------------------------------------------------------------------
% Important options for all experiments
%-------------------------------------------------------------------------
p.environment = 2; % 1 = Linux machine, 2 = iMac, 3 = PC
p.portCodes = 0;  %1 = use p.portCodes (we're in the booth)
p.windowed = 1; % 1 = small win for easy debugging!
p.startClick = 0; % 1 = must press spacebar to initiate each trial. 
%-------------------------------------------------------------------------
% Build an output directory & check to make sure it doesn't already exist
%-------------------------------------------------------------------------
p.root = pwd;
addpath([p.root,'/SupportFunctions'])
if p.environment == 1
    if p.portCodes == 1   
        p.datadir = '/home/serencesadmin/Documents/Kirsten/switchSearch/Data';
        p.GeneralUseScripts = '/home/serencesadmin/Documents/Kirsten/switchSearch/GeneralUseScripts';
    else
        p.datadir = '/home/serencesadmin/Documents/Kirsten/switchSearch';
        p.GeneralUseScripts = '/home/serencesadmin/Documents/Kirsten/switchSearch/GeneralUseScripts';
    end
    addpath(genpath(p.GeneralUseScripts));
    addpath(genpath([p.GeneralUseScripts,'/Calibration']));
else % just save locally!
    if ~exist([p.root, filesep,'Data',filesep], 'dir')
        mkdir([p.root, filesep,'Data',filesep]);
    end
    p.datadir = [p.root, filesep,'Data',filesep];
end
%-------------------------------------------------------------------------
% If we're on a linux machine, but not in EEG, get the behavior room!
%-------------------------------------------------------------------------
if ~p.portCodes && p.environment==1
    prompt = {'Room Letter'};            % what information do we want from the subject?
    defAns = {''};                                           %s fill in some stock answers - here the fields are left blank
    box = inputdlg(prompt,'Enter Room Info',1,defAns);       % build the GUI
    if length(box) == length(defAns)                            % check to make sure something was typed in
        p.room = upper(box{1});
    else
        return;                                                 % if nothing was entered or the subject hit cancel, bail out
    end
else
    p.room = 'A';
end
%-------------------------------------------------------------------------
% Change to our desired resolution and refresh rate
%-------------------------------------------------------------------------
if p.environment == 1
%     s = setScreen_Exp(1024,768,120); % X, Y, 120 Hz
    s = setScreen_Default(); % just use Default for this experiment! 1600 x 1200, 85 Hz 
    if s == 0
        fprintf('Screen successfully set to Experiment Mode!');
    end
end
%-------------------------------------------------------------------------
% Build psychtoolbox window & hide the task bar
%-------------------------------------------------------------------------
win = openWindow(p);
%Manually hide the task bar so it doesn't pop up because of flipping
%the PTB screen during GetMouse:
if p.environment == 3
    ShowHideWinTaskbarMex(0);
end
%-------------------------------------------------------------------------
% Do gamma correction!
%-------------------------------------------------------------------------
if p.environment == 1
    win.OriginalCLUT = Screen('LoadClut', win.onScreen);
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
    [gamInverse,dacsize] = LoadCalibrationFileRR(CalibrationFile, p.root, p.GeneralUseScripts);
    LumSteps = linspace(MinLum, MaxLum, 256)';
    MyCLUT(:,:) = repmat(LumSteps, [1 3]);
    MyCLUT = round(map2map(MyCLUT,gamInverse)); %Now the screen output luminance per pixel is linear!
    Screen('LoadCLUT', win.onScreen, MyCLUT);
    clear CalibrationFile gamInverse
end

%-------------------------------------------------------------------------
% Run Main Experiment Scripts
%-------------------------------------------------------------------------

Additional_singleton_instruction_task_popout(p,win)

% Set up a place to keep track of incentive $$ earned! 
nBlocks = 7; 
p.blockCash = zeros(1,nBlocks*3); 

if p.counterbalance_cond == 1
    p.task_order = {'0','50','100'};
    p = SearchTask_Switch0(p,win,1);
    p = SearchTask_Switch50(p,win,2);
    p = SearchTask_Switch100(p,win,3);
    
elseif p.counterbalance_cond == 2
    p.task_order = {'0','100','50'};
    p = SearchTask_Switch0(p,win,1);
    p = SearchTask_Switch100(p,win,2);
    p = SearchTask_Switch50(p,win,3);
    
elseif p.counterbalance_cond == 3
    p.task_order = {'50','0','100'};
    p = SearchTask_Switch50(p,win,1);
    p = SearchTask_Switch0(p,win,2);
    p = SearchTask_Switch100(p,win,3);
    
elseif p.counterbalance_cond == 4
    p.task_order = {'50','100','0'};
    p = SearchTask_Switch50(p,win,1);
    p = SearchTask_Switch100(p,win,2);
    p = SearchTask_Switch0(p,win,3);
    
elseif p.counterbalance_cond == 5
    p.task_order = {'100','0','50'};
    p = SearchTask_Switch100(p,win,1);
    p = SearchTask_Switch0(p,win,2);
    p = SearchTask_Switch50(p,win,3);
    
elseif p.counterbalance_cond == 6
    p.task_order = {'100','50','0'};
    p = SearchTask_Switch100(p,win,1);
    p = SearchTask_Switch50(p,win,2);
    p = SearchTask_Switch0(p,win,3);
    
end
    
%-------------------------------------------------------------------------
% Change back gamma values!
%-------------------------------------------------------------------------
if p.environment == 1
    Screen('LoadCLUT', win.screenNumber, win.OriginalCLUT);
end
%-------------------------------------------------------------------------
% Change back screen to default mode!
%-------------------------------------------------------------------------
if p.environment == 1
s = setScreen_Default();
if s == 0
    fprintf('Screen successfully set back to default!');
end
end
%-------------------------------------------------------------------------
% Close psychtoolbox window & Postpare the environment
%-------------------------------------------------------------------------
sca;
ListenChar(0);
if p.environment == 3
    ShowHideWinTaskbarMex(1);
end
%% 
close all;

