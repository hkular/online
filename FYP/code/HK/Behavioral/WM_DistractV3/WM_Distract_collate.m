clear
close all
clc
 
subs = ['23' ;'24';'26'; '27'; '30';  '31'; '32'; '33'; '34'; '35'; '36'; '38'; '39'];
%my_path = '/mnt/neurocube/local/serenceslab/Rosanne/NN/OSF/';
my_path = '/Users/hollykular/Documents/FYP/code/HK/Behavioral/WM_DistractV3/'
%my_path = '/Users/hkular/Documents/FYP/code/HK/Behavioral/Sherlock/';
info.TheDate = datestr(now,'yymmdd');
addpath([my_path 'SupportFunctions'])
cd('Data/V11')
collated_data = [];
all_dat = [];
for s = 1:size(subs,1)
    
    %find the filenames for the subject data
    myFolder = pwd;
    filePattern = fullfile(myFolder, 'WM_DistractV*'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);
    
    %load this subjects data
    load([theFiles(s).name])
    length(TheData);
    subject = [];
    resp = [];
    respRT = [];
    conf = [];
    confRT = [];
    hits = [];
    falserep = [];
    
    for run = 1:length(TheData) % for each run
        
        subject = [subject; repmat(s, [length(TheData(run).data.Response),1])];
        resp = [resp;TheData(run).data.Response'];
        respRT = [respRT; TheData(run).data.RTresp'];
        conf = [conf; TheData(run).data.Confidence'];
        confRT = [confRT; TheData(run).data.RTconf'];

    end
    ss = num2cell(subject); [TrialStuff.('subject')] = ss{:};
    rs = num2cell(resp); [TrialStuff.('resp')] = rs{:};
    rrt = num2cell(respRT); [TrialStuff.('respRT')] = rrt{:};
    cf = num2cell(conf); [TrialStuff.('conf')] = cf{:};
    crt = num2cell(confRT); [TrialStuff.('confRT')] = crt{:};

  
    collect = TrialStuff;
    all_dat = [all_dat collect];
    clear collect ss rs rrt cf crt 
end
eval(['save(''WM_Distract_pilot_', num2str(info.TheDate), '.mat'', ''all_dat'', ''-v7.3'')']);
    