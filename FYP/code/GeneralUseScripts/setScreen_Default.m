function [s,s2] = setScreen_Default()

% Change back to default dimensions & refresh rate
[s,~] = unix('xrandr --output DVI-I-0 --mode "1600x1200"','-echo');

% Make it so that the screen will go to sleep!
[s2,~] = unix('xset dpms 300 0 0');

if s || s2 % if changing a setting fails
    error('Could not execute unix command to change display mode! Look into it!')
end

end