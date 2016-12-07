function [] = getauc(cfg,data)

numsplit=2;
numSplit = 2;
numCond = 2;
numDays = 2;
numSubjects = 10;
numTEPcomp = 4;

% GRAB AVERAGE ROI WAVEFORMS
clear TEPs TEPsT isplit AUC
%Let's make TEP a 5-D array with dimensions in order above
for i = 1:size(data,2) % FOR EACH CONDITION %And subject
    splitmark = floor(size(data(i).EEG.data,3)/numsplit);%Find trial number for split half analysis
    
    for j = 1:size(cfg.regs,2) % FOR EACH ROI
        %Note: EEG.data is 3 dimensional array with dimensions
        %1:electrodes (64) 2:milliseconds (1500) 3:trials (~150)
        TEPs(i,j).all = squeeze(nanmean(data(i).EEG.data(cfg.regs(j).chan,:,:),1));%finds avg across channels in given reg
        TEPs(i,j).avg = squeeze(nanmean(nanmean(data(i).EEG.data(cfg.regs(j).chan,:,:),3),1));%finds avg across chan AND trial
        for isplit=1:numsplit;%This loop creates an array with split half data
            range = [1+splitmark*(isplit-1)  splitmark*(isplit)];
            TEPs(i,j).split(:,:,isplit) = squeeze(nanmean(nanmean(data(i).EEG.data(cfg.regs(j).chan,:,range(1):range(2)),3),1));
        end
        TEPs(i,j).ROIname = cfg.regs(j).name;
        TEPs(i,j).time = data(i).EEG.times;
        TEPs(i,j).condName = data(i).EEG.condition;
        disp(['Gathering TEPs matfile ' num2str(i) ' : from ' cfg.regs(j).name])
    end
end
%So at this point we have for the called patient:
%A structure array TEP
%with a cell for each 1.condition 2.ROI
%Where each cell contains
%1) A 2D array of every millisecond and trial 
%2) A 1D array of every millisecond averaged across trials
%3) The name of the: 1.condition 2.roi 3.time for each data point

%%
% %This part is only relevant when we pick peaks in educated way
% clear TEPsGrand
% for j = 1:size(cfg.regs,2) % FOR EACH ROI
%     for i = 1:size(data,2) % for each condition
%         dat(i,:) = TEPs(i,j).avg;
%     end
%     TEPsGrand.avg(j,:) = nanmean(dat,1);%Averages across all conditions (again for a given sub and ROI)
%     TEPsGrand.time(j,:) = TEPs(1,j).time;
%     TEPsGrand.name{j} =  TEPs(1,j).ROIname;
% end
% 
% figure,plot(TEPsGrand.time(1,:),TEPsGrand.avg(:,:))
%%
% FIND TIMES FOR PEAKS - NOW COPIED INTO WRAPPER
tForAUC = [0 50;50 100;100 150;150 250];
tNames = {'0-50';'50-100';'100-150';'150-250'};

% %Corey's Loop
% for i = 1:size(data,2) % FOR EACH CONDITION
%     for j = 1:size(cfg.regs,2) % FOR EACH ROI
%       %Add in here loop for each split
%         for k = 1:length(tForAUC) % For EACH TIMEFRAME - good to have lowest since collapses in AUC
%             tDat = find(TEPs(i,j).time > tForAUC(k,1) & TEPs(i,j).time < tForAUC(k,2));
%             TEPs(i,j).AUC(k) = trapz(TEPs(i,j).time(tDat),TEPs(i,j).avg(tDat));
%             AUC(i,j,k) = TEPs(i,j).AUC(k);
%             TEPs(i,j).componentNames{k} = tNames{k};
%         end
%     end
% end

%My loop
for isplit = 1:numsplit
    for icond = 1:numcond

clear condName
for i = 1:size(data,2)
    condName{i,1} = TEPs(i,1).condName;
end

close all;figure
for k = 1:length(tNames)
    subplot(2,2,k)
    imagesc(squeeze(AUC(:,:,k)))
    title(tNames{k})
    set(gca,'YTick',1:length(tNames))
%     set(gca,'YTickLabels',condName)
    set(gca,'XTick',1:size(cfg.regs,2))
%     set(gca,'YTickLabels',condName)
    colorbar
end







