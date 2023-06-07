%PUT THIS SOMEWHERE AFTER OPENING A WINDOW
%MAKE SURE TO UPDATE THE LAB INFO !!! (so don't accidentally load the clut
%from another lab

%check CLUT
clut_dir = '/home/serencesadmin/Documents/CLUT';
cd(clut_dir);load('OriginalCLUT_labC.mat')
curr_clut = Screen('LoadClut', window);
if ~isempty(find(ismember(OriginalCLUT,curr_clut)==0))
    disp('WRONG CLUT YO!!!');
    sca
end