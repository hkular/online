% This script should only be ran *ONCE* *EVER* (so *not* once per subject, 
% ONCE FOR THE ENTIRE EXPERIMENT!
%
% It makes the counterbalancing for the color cues, 6 subjects are required
% to fully counterbalance the cues
clear
close all

expdir = pwd;
datadir = 'Data';
    
color1 = [245.0980 36.8980 17.6039];    %red-ish
color2 = [0 121 0];                     %green
color3 = [14.5922 79.0745 150.6510];    %blue-ish

 cues_to_use = {'none';'noise';'grating'}; % so the three distractor-event types
%cues_to_use = {'none';'pics';'grating'}; % so the three distractor-event types

CueColors = [];
for cue1 = 1:size(cues_to_use,1)
    first_cue = cues_to_use(cue1);
    other_cues = cues_to_use(~ismember(cues_to_use,cues_to_use(cue1)));
    for cue2 = 1:size(cues_to_use,1)-1
        second_cue = other_cues(cue2);
        third_cue = setdiff(other_cues,second_cue);
   
        eval(['cuecolor.' char(first_cue) ' = [' num2str(color1) '];']);
        eval(['cuecolor.' char(second_cue) ' = [' num2str(color2) '];']);
        eval(['cuecolor.' char(third_cue) ' = [' num2str(color3) '];']);
        CueColors = [CueColors cuecolor];
        
    end
end
CueColors = Shuffle(CueColors);

cd(datadir)
 save CueColorsV2.mat CueColors
save CueColorsCTRL.mat CueColors
cd(expdir)
