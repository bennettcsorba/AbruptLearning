%% SET-UP
 % Edits line 5, 8, 11, 14, 17, 20 and 23 to your desired parameters

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

% Custom Time Range
cRange = 101:700;

% Cohgram Window/Step
cWindow = [0.2 0.05];

%% BATCH LOOP %%%%

for runIDX = 1:length(itemsToRun)

    %% Get some basic data from the session
    listEntry = itemsToRun{runIDX}; % grab the string from the list

    
    %% Load the event struct for the scene being analyzed:
    
    load(strcat(pathStruct.extractedEventsPath,listEntry,'_eventStruct.mat'));
    
    %% %% Import our filtered LFP for the session %%%
    if strcmp(stampOfInterest,'Scene')
        load(strcat(pathStruct.scenePath,'LFP/',listEntry,'_filteredLFP.mat'));
    elseif strcmp(stampOfInterest,'Reward')
        load(strcat(pathStruct.rewardPath,'LFP/',listEntry,'_filteredLFP.mat'));
    elseif strcmp(stampOfInterest,'Foraging')
        load(strcat(pathStruct.foragingPath,'LFP/',listEntry,'_filteredLFP.mat'));
    else
        error('stampOfInterest is not declared appropriately')
    end
    
    %% Make a directory to hold our coherence arrays (if DNE):
    if ~exist(strcat(pathStruct.cohgramPath,listEntry,'/TrialSmall/'))
        %Make a directory to hold our results:
        mkdir(strcat(pathStruct.cohgramPath,listEntry,'/TrialSmall/'))
    end
    
    %% Set some chronux coherence params:
    chronuxParams = setChronuxParams_SpecialBand(1); %set some Chronux filtering params
    
    timeRange_ms = [-200,400]; %quick fix
    nSamples = (timeRange_ms(2)-timeRange_ms(1));

    %% Main Loop
    disp(['%%% Brincat Coherence: Now on : ' eventStruct.fullName]);
    for trialIndex = 1:eventStruct.nTrials
        disp(['%%% Trial # : ' num2str(trialIndex)]);
        
        %% Init arrays to hold our coherence data:
        cohArrayM_Trial = zeros(192,192,9,25); %last two sizes based on output
        cohArrayP_Trial = zeros(192,192,9,25);

        for chIndex1 = 1:192
    
            %Grab a range of data (~ 5 trials unless at very start or end):
            if trialIndex == 1
                data_A = reshape(filteredLFP(trialIndex:trialIndex+2,chIndex1,cRange),[3 nSamples]).';
            elseif trialIndex == 2
                data_A = reshape(filteredLFP((trialIndex-1:trialIndex+2),chIndex1,cRange),[4 nSamples]).';
            elseif trialIndex == eventStruct.nTrials
                data_A = reshape(filteredLFP((trialIndex-2:trialIndex),chIndex1,cRange),[3 nSamples]).';
            elseif trialIndex == eventStruct.nTrials-1
                data_A = reshape(filteredLFP((trialIndex-2:trialIndex+1),chIndex1,cRange),[4 nSamples]).';
            else
                data_A = reshape(filteredLFP((trialIndex-2:trialIndex+2),chIndex1,cRange),[5 nSamples]).';
            end

            for chIndex2 = 1:192
                %If repeated pair:
                if chIndex2 <= chIndex1
                    continue
                %If unique pair:
                else

                    if trialIndex == 1
                        data_B = reshape(filteredLFP(trialIndex:trialIndex+2,chIndex2,cRange),[3 nSamples]).';
                    elseif trialIndex == 2
                        data_B = reshape(filteredLFP((trialIndex-1:trialIndex+2),chIndex2,cRange),[4 nSamples]).';
                    elseif trialIndex == eventStruct.nTrials
                        data_B = reshape(filteredLFP((trialIndex-2:trialIndex),chIndex2,cRange),[3 nSamples]).';
                    elseif trialIndex == eventStruct.nTrials-1
                        data_B = reshape(filteredLFP((trialIndex-2:trialIndex+1),chIndex2,cRange),[4 nSamples]).';
                    else
                        data_B = reshape(filteredLFP((trialIndex-2:trialIndex+2),chIndex2,cRange),[5 nSamples]).';
                    end

                    %Compute a spectrum for all epochs:
                    [coh_out,phi_out,~,~,~,t_out,f_out] = cohgramc(data_A,data_B,cWindow,chronuxParams);
                    
                    %Store MAX Band Data
                    cohArrayM_Trial(chIndex1,chIndex2,:,:) = coh_out;
                    cohArrayP_Trial(chIndex1,chIndex2,:,:) = phi_out;

                end
            end
        end
        
        % $$$$$$$$$$$$$$$$$$$ SAVING $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        %Save Per Trial cohgram
        save(strcat(pathStruct.cohgramPath,listEntry,'/TrialSmall/',listEntry,...
            '_BA-FullTrial_',num2str(trialIndex),'.mat'),...
            'cohArrayM_Trial','cohArrayP_Trial','chronuxParams','stampOfInterest',...
            'timeRange_ms','freqRange','t_out','f_out','-v7.3');
        
    end 
    

    %Clean-up
    clearvars -except pathStruct runIDX itemsToRun stampOfInterest ...
        timeRange_ms freqRange cWindow
end