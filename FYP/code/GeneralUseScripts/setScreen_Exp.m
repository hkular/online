function s = setScreen_Exp(x,y,refresh)

mode_name = sprintf('%dx%d_%.2f',x,y,refresh);

[s,~] = unix(['xrandr --output DVI-I-0 --mode ',mode_name],'-echo');

if s % If the unix command fails
    
    error('Could not execute unix command to change display mode! You may need to create the mode!')
    
end

end