%% SET-UP
 % Edits line 5, 8, 11, 14-16 to your desired parameters

% Load the pathstruct:
load('F:/F-2020/Abrupt_Learning/pathStruct.mat');

% Set the scenes we want to run:
itemsToRun = pathStruct.learnedM; %pathStruct.learnedF

% TimeStamp of Interest (for reference)
stampOfInterest = 'Scene'; %Foraging %Reward

% Time Range to Filter (relative to stamp of interest, in ms - integers only)
timeRange_ms = [-300,500];
t_out = linspace(-0.2,0.6,24000);
tSize = 24000; tSize_comp = 800;

%% BATCH LOOP %%%%

for runIDX = 1:length(itemsToRun)

    %% Get some basic data from the session
    listEntry = itemsToRun{runIDX}; % grab the string from the list

    %% Load the event struct for the epoch being analyzed:
    load(strcat(pathStruct.extractedEventsPath,listEntry,'_eventStruct.mat'));
    
    %% Init arrays to hold our power data:
    multiUnitArray = zeros(192,eventStruct.nTrials,tSize);
    multiUnitCompressed = zeros(192,eventStruct.nTrials,tSize_comp);
    
    %% Main Loop
    disp(['%%% MUA MERGE: now on: ' eventStruct.fullName]); %Disp Sesh Name
    for chIndex = 1:192
        %Display the channel number #
        disp(['%%% Ch.# ' num2str(chIndex)]);
     
        if strcmp(stampOfInterest,'Scene')
            load(strcat(pathStruct.scenePath,'MUA_Trains/',listEntry,'/Ch',...
            num2str(chIndex),'_muaTrain.mat'));
        elseif strcmp(stampOfInterest,'Reward')
            load(strcat(pathStruct.rewardPath,'MUA_Trains/',listEntry,'/Ch',...
            num2str(chIndex),'_muaTrain.mat'));
        elseif strcmp(stampOfInterest,'Foraging')
            load(strcat(pathStruct.foragingPath,'MUA_Trains/',listEntry,'/Ch',...
            num2str(chIndex),'_muaTrain.mat'));
        else
            error('stampOfInterest is not declared appropriately')
        end
        
        load(strcat(pathStruct.filteredPath,'MUA_Trains/',listEntry,'/Ch',...
            num2str(chIndex),'_muaTrain.mat'));
        
        %Do some condensing for a smaller array (for rasters):
        compressMatrix = zeros(eventStruct.nTrials,tSize_comp);
        for compressIndex = 1:tSize_comp
            rangeStart = ((compressIndex-1)*30)+1;
            rangeEnd = ((compressIndex)*30);
            compressMatrix(:,compressIndex) = sum(channelCrossings(:,rangeStart:rangeEnd),2);
        end

        multiUnitArray(chIndex,:,:) = channelCrossings;   
        multiUnitCompressed(chIndex,:,:) = compressMatrix;  
    end 
    

    % $$$$$$$$$$$$$$$$$$$ SAVING $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    if strcmp(stampOfInterest,'Scene')
        savePath = pathStruct.scenePath;
    elseif strcmp(stampOfInterest,'Reward')
        savePath = pathStruct.rewardPath;
    elseif strcmp(stampOfInterest,'Foraging')
        savePath = pathStruct.foragingPath;
    else
        error('stampOfInterest is not declared appropriately')
    end
    

    %Save Merged MUA (8Hz)
    save(strcat(savePath,'MUA/',listEntry,'_multiUnitArray.mat'),...
        'multiUnitArray','stampOfInterest',...
        'timeRange_ms','t_out','-v7.3');

    save(strcat(savePath,'MUA/',listEntry,'_multiUnitCompressed.mat'),...
        'multiUnitCompressed','stampOfInterest',...
        'timeRange_ms','t_out','-v7.3');
    
    clearvars -except pathStruct runIDX itemsToRun stampOfInterest ...
    timeRange_ms t_out tSize tSize_comp

end