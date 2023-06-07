clear
close all
clc

% demographics
subs =  ['23' ;'24';'26'; '27'; '30';  '31'; '32'; '33'; '34'; '35'; '36'; '38'; '39'];
%my_path = '/mnt/neurocube/local/serenceslab/Rosanne/NN/OSF/';
my_path = '/Users/hollykular/Documents/FYP/code/HK/Behavioral/WM_DistractV3/'
%my_path = '/Users/hkular/Documents/FYP/code/HK/Behavioral/Sherlock/';
info.TheDate = datestr(now,'yymmdd');
addpath([my_path 'SupportFunctions'])
cd('Data/V11')
collated_data = [];
all_demo = [];
for s = 1:size(subs,1)
    
    %find the filenames for the subject data
    myFolder = pwd;
    filePattern = fullfile(myFolder, 'WM_DistractV*'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);
    
    %load this subjects data
    load([theFiles(s).name])

    subject = [];
    age = [];
    gender = [];
    hand = [];
   
    
    
      
        subject = [subject; TheData(1).info.SubNum];
        age = [age; TheData(1).info.Age];
        gender = [gender; TheData(1).info.Gender];
        hand = [hand; TheData(1).info.Handed];
     
    [demo.('subject')] = subject;
    [demo.('age')] = str2double(age);
    [demo.('gender')] = gender;
    [demo.('hand')] = hand;
    
        
        
    all_demo = [all_demo demo];

    clear demo ss aa gg hh
     
end
eval(['save(''WM_Distract_demo_', num2str(info.TheDate), '.mat'', ''all_demo'', ''-v7.3'')']);
    