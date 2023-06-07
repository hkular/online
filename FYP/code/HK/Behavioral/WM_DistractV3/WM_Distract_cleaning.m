clear
close all
clc

subs = ['01';'02';'03';'04';'05';'06';'07';'08'];

%my_path = '/mnt/neurocube/local/serenceslab/Rosanne/NN/OSF/';
my_path = '/Users/hollykular/Documents/FYP/code/HK/Behavioral/WM_DistractV3/'
%my_path = '/Users/hkular/Documents/FYP/code/HK/Behavioral/Sherlock/';

addpath([my_path 'SupportFunctions'])
cd('Data/Session1')

% plot_individuals = 1; % can plot individual subjects if you'd like
%set up a collection bin

for s = 1:size(subs,1)
    

    %find the filenames for the subject data
    myFolder = pwd;
    filePattern = fullfile(myFolder, 'WM_DistractV*'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);
    
    %load this subjects data
    load([theFiles(s).name])
    length(TheData); 
    nonresp = [];
    correct = [];
    falsereport = [];
    % calculate some things
    for run = 1:length(TheData) % for each run
         % targets
            %targets_were = TrialStuff.testorient;
            % recommended to exclude subjects who did not respond to most trials
        for runs = 1:length(TheData)
            foo(run) = sum(isnan(abs(TheData(run).data.Response)));
            TheData(run).nonresp = sum(isnan(abs(TheData(run).data.Response)));
        end
        if sum(foo>15)~=0 % maybe change this cut off
            disp([' SUBJECT ', char(subs(s,:)), ' DID REALLY POORLY ON THE TASK, EXCLUDE!!!'])
        end
        
        for trial = 1:length(TrialStuff)/8 % for each trial
            
            %accuracy - total correct
            if TheData(run).data.Response(trial) == TrialStuff(trial).correctresp
                TheData(run).data.acc(trial) = 1;% correct
            elseif TheData(run).data.Response(trial) ~= TrialStuff(trial).correctresp
                if  isnan(TheData(run).data.Response(trial))
                    TheData(run).data.acc(trial) = NaN; % no response
                else
                    TheData(run).data.acc(trial) = 0; % incorrect
                end
            end
            
            %false reports
            if TrialStuff(trial).correctresp == 5
                if TheData(run).data.Response(trial) == 5 % correct response
                   TheData(run).data.FR(trial) = 0;
                elseif isnan(TheData(run).data.Response(trial))
                    TheData(run).data.FR(trial) = NaN; % no response
                else
                    TheData(run).data.FR(trial) = 1; % false report
                end
            end  
        end
         %within subject and session means
        %TheData(run).correct = mean(TheData(run).data.acc, 'omitnan');
        %TheData(run).falsereport = mean(TheData(run).data.FR, 'omitnan');
        TheData(run).correctn = sum(TheData(run).data.acc, 'omitnan');
        TheData(run).falsereportn = sum(TheData(run).data.FR, 'omitnan');
             
    end 
    
         %save new stuff
        if s > 3
            eval(['save(''WM_DistractV7_S', num2str(TheData(run).info.SubNum), '_', num2str(TheData(run).info.TheDate), '_Main.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
        else 
            eval(['save(''WM_DistractV6_S', num2str(TheData(run).info.SubNum), '_', num2str(TheData(run).info.TheDate), '_Main.mat'', ''TheData'', ''TrialStuff'', ''-v7.3'')']);
        end
     
end% extra end


% for run = 1:length(TheData)
%     TheData(run).info.Handed = 'R';
% end
