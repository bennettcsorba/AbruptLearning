%% SET-UP
% Edits line 5, 8, 11 and 14 to your desired parameters

% Load the pathstruct:
load('F:/F-2020/Abrupt_Learning/pathStruct.mat');

% Set the scenes we want to run:
itemsToRun = pathStruct.learnedM; %pathStruct.learnedF

% TimeStamp of Interest (for reference)
stampOfInterest = 'Scene'; %Foraging %Reward

% Time Range to Filter (relative to stamp of interest, in ms - integers only)
timeRange_ms = [-200,600];


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
    
    
    %% Make a directory for the channel plots:
    newPlotDirectory = strcat(pathStruct.channelAnalysisPath,listEntry,'/');
    if ~exist(newPlotDirectory)
        mkdir(newPlotDirectory)
    end
    
    %% Make a plot for each channel (in groups of 4), 
      %showing all trial data for our window:
    disp(['%%% Channel Plotting: Now on: ' eventStruct.fullName]);
    
    for channelCluster = 1:48
        baseChannelIdx = ((channelCluster-1)*4)+1
        disp(['%%% Ch # ' num2str(baseChannelIdx) 'to Ch #' num2str(baseChannelIdx+3)]);
        figChannel = figure('units','normalized','outerposition',[0 0 0.5 0.75]);
        for bunchIdx = 0:3
            channelExtract = reshape(filteredLFP(:,baseChannelIdx+bunchIdx,:),[eventStruct.nTrials 800]).';
            subplot(2,2,bunchIdx+1)
            plot(linspace(-0.3,0.5,800),channelExtract)
            title(strcat(eventStruct.fullName,{' | Scene Onset | Ch.#'},...
                  num2str(baseChannelIdx+bunchIdx)));
            xlabel('Time (s)');
            hy = ylabel(strcat('Amplitude (','\mu','V)'));
            set(hy, 'Interpreter', 'tex')
            xlim([-0.3 0.5])
        end
        saveLocation = strcat(newPlotDirectory,'Ch_',num2str(baseChannelIdx),...
                       'to',num2str(baseChannelIdx+3),'.png');
        saveas(figChannel,saveLocation);
        close(figChannel)
    end

    clearvars -except pathStruct runIDX itemsToRun timeRange_ms stampOfInterest
    
end