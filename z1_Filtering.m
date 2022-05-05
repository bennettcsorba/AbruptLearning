%% SET-UP
 % Edits line 5, 8, 11, 14, 17 to your desired parameters

% Load the pathstruct:
load('F:/F-2020/Abrupt_Learning/pathStruct.mat');

% Set the scenes we want to run:
itemsToRun = pathStruct.learnedM; %pathStruct.learnedF

% Filter type to use:
filterChoice = 'Chronux';

% TimeStamp of Interest (for reference)
stampOfInterest = 'Scene'; %Foraging %Reward

% Time Range to Filter (relative to stamp of interest, in ms - integers only)
timeRange_ms = [-200,600];

%% BATCH LOOP %%%%

for runIDX = 1:length(itemsToRun)

    %% Get some basic data from the session
    listEntry = itemsToRun{runIDX}; % grab the string from the list

    %% Make two directories to hold our filtered data (if DNE):
    %{
    if ~exist(strcat(pathStruct.filteredPath,'LFP/',listEntry,'/')) %LFP
        %Make a directory to hold our results:
        mkdir(strcat(pathStruct.filteredPath,'LFP/',listEntry,'/'))
    end
    %}
    
    %{
    if ~exist(strcat(pathStruct.filteredPath,'HighPass/',listEntry,'/')) %HIGH-PASS
        %Make a directory to hold our results:
        mkdir(strcat(pathStruct.filteredPath,'HighPass/',listEntry,'/'))
    end
    %}
    
    %% Load the event struct for the scene being analyzed:
    
    load(strcat(pathStruct.extractedEventsPath,listEntry,'_eventStruct.mat'));
    
    %% %% Import trial signal for filtering/artifact removal/decimation %%%
   
    neuralDataDirectory = strcat(pathStruct.dataDrivePath,...
                                 eventStruct.sessionName);
    
    %wb = WBLoader(strcat(neuralDataDirectory)); %init WBLoader
    f = dir(fullfile(neuralDataDirectory, '*_ch*.flac')); %find all flac files in
                                                    %wideband data directory
                                                       
    %Define a (effectively) 6th order low-pass filter for extracting LFPs:
    [bLow,aLow] = butter(3, 300/(0.5*30000), 'low'); %cutoff frequency of 300Hz.
    
    %Set some chronux filtering params:
    chronuxParams = setChronuxParams_Filtering([3 5],30000,0); %set some Chronux filtering params
    
    %Init an array to hold our filtered data:
    nSamples = (timeRange_ms(2)-timeRange_ms(1));
    filteredLFP = zeros(eventStruct.nTrials,192,nSamples);
    
    %Grab Ripple times for the timestamp of interest
    if strcmp(stampOfInterest,'Scene')
        timeStamps = eventStruct.sceneOnset_rp;
        savePath = pathStruct.scenePath;
    elseif strcmp(stampOfInterest,'Reward')
        timeStamps = eventStruct.rewardOnset_rp;
        savePath = pathStruct.rewardPath;
    elseif strcmp(stampOfInterest,'Foraging')
        timeStamps = eventStruct.foragingOnset_rp;
        savePath = pathStruct.foragingPath;
    else
        error('stampOfInterest is not declared appropriately')
    end

    %% Main Loop
    disp(['%%% LFP Signal Filtering: Now on: ' eventStruct.fullName]);
    for trialIndex = 1:eventStruct.nTrials
        trialTimeStamp = timeStamps(trialIndex);
        %Display the trial # and fullName of the data dir being analyzed
        disp(['%%% Trial # ' num2str(trialIndex)]);
        %Read from 
        startRead = floor(((trialTimeStamp+(timeRange_ms(1)/1000))*30000));
        stopRead = startRead+(nSamples*30)-1;
        for chIdx = 1:192
            %Read in block data, filt. out 60Hz noise and movements, decimate by factor of 30
            %trialWBD = wb.getDataByTime(chIdx, startRead, stopRead);
            trialWBD = double(audioread(strcat(neuralDataDirectory,'/',f(chIdx).name), [startRead, stopRead], 'native'));
            filteredWBD = filtfilt(bLow,aLow,trialWBD); %Extract LFP
            %Remove 60Hz noise and then decimate to 1000Hz
            filteredWBD = filtfiltDecimate(filteredWBD,30000,30,filterChoice,0.208319345683157,chronuxParams);
            filteredLFP(trialIndex,chIdx,:) = filteredWBD;
        end
    end 
    % $$$$$$$$$$$$$$$$$$$ SAVING $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

    save(strcat(savePath,'LFP/',listEntry,'_filteredLFP.mat'),...
        'filteredLFP','chronuxParams','filterChoice',...
        'stampOfInterest','timeRange_ms','-v7.3');
    clearvars -except pathStruct runIDX itemsToRun filterChoice stampOfInterest timeRange_ms
end