%% SET-UP
 % Edits line 5, 8, 11, 14, 17 and 20 to your desired parameters

% Load the pathstruct:
load('F:/F-2020/Abrupt_Learning/pathStruct.mat');

% Set the scenes we want to run:
itemsToRun = pathStruct.learnedM; %pathStruct.learnedF

% TimeStamp of Interest (for reference)
stampOfInterest = 'Scene'; %Foraging %Reward

% Time Range to Filter (relative to stamp of interest, in ms - integers only)
timeRange_ms = [-200,600];

% Frequency Range (in Hz)
freqRange = [1 100];

% Specgram Window/Step
cWindow = [0.2 0.01];

%% BATCH LOOP %%%%

for runIDX = 1:length(itemsToRun)

    
    %% Get some basic data from the session
    listEntry = itemsToRun{runIDX}; % grab the string from the list

    
    %% Load the event struct for the scene being analyzed:
    load(strcat(pathStruct.extractedEventsPath,listEntry,'_eventStruct.mat'));
    
    %% Load our filtered LFP data:
    if strcmp(stampOfInterest,'Scene')
        load(strcat(pathStruct.scenePath,'LFP/',listEntry,'_filteredLFP.mat'));
    elseif strcmp(stampOfInterest,'Reward')
        load(strcat(pathStruct.rewardPath,'LFP/',listEntry,'_filteredLFP.mat'));
    elseif strcmp(stampOfInterest,'Foraging')
        load(strcat(pathStruct.foragingPath,'LFP/',listEntry,'_filteredLFP.mat'));
    else
        error('stampOfInterest is not declared appropriately')
    end

    %% Make a directory to hold our arrays (if DNE):
    if ~exist(strcat(pathStruct.powerPath,listEntry,'/')) 
        %Make a directory to hold our results:
        mkdir(strcat(pathStruct.powerPath,listEntry,'/'))
    end
    
  
    %% Set some chronux power params:
    chronuxParams = setChronuxParams_SpecialBand(1); %set some Chronux filtering params
    nSamples = (timeRange_ms(2)-timeRange_ms(1));
    
    %% Init arrays to hold our coherence data:
    powerArray = zeros(eventStruct.nTrials,192,61,25); %last two numbers are size of output
    
    %% Main Loop
    disp(['%%% Power calculation: now on: ' eventStruct.fullName]);
    for trialIndex = 1:eventStruct.nTrials
        %Display the trial # and fullName of the data dir being analyzed
        disp(['%%% Trial # ' num2str(trialIndex)]);
        %Compute a spectrogram for the session, and condense for each
        %freq:
        for chIndex = 1:192
            data_A = reshape(filteredLFP(trialIndex,chIndex,:),[1 nSamples]).';
            [amplitude_out,t_out,f_out] = mtspecgramc(data_A,cWindow,chronuxParams);            
            %Store Trial Data:
            powerArray(trialIndex,chIndex,:,:) = amplitude_out;

        end
    end 
    % $$$$$$$$$$$$$$$$$$$ SAVING $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

    save(strcat(pathStruct.powerPath,listEntry,'/',listEntry,'_powerArray-P.mat'),...
        'powerArray','chronuxParams','stampOfInterest',...
        'timeRange_ms','freqRange','t_out','f_out','-v7.3');

    
    clearvars -except pathStruct runIDX itemsToRun filterChoice stampOfInterest ...
    timeRange_ms freqRange cWindow
end