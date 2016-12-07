function [] = stability(cfg,data)

% GRAB AVERAGE ROI WAVEFORMS
clear TEPs TEPsT
for i = 1:size(data,2) % FOR EACH CONDITION
    for j = 1:size(cfg.regs,2) % FOR EACH ROI
        TEPs(i,j).all = squeeze(nanmean(data(i).EEG.data(cfg.regs(j).chan,:,:),1));
        TEPs(i,j).avg = squeeze(nanmean(nanmean(data(i).EEG.data(cfg.regs(j).chan,:,:),3),1));
        TEPs(i,j).ROIname = cfg.regs(j).name;
        TEPs(i,j).time = data(i).EEG.times;
        TEPs(i,j).condName = data(i).condName;
        disp(['Gathering TEPs matfile ' num2str(i) ' : from ' cfg.regs(j).name])
    end
end

clear TEPsGrand
for j = 1:size(cfg.regs,2) % FOR EACH ROI
    for i = 1:size(data,2)
        dat(i,:) = TEPs(i,j).avg;
    end
    TEPsGrand.avg(j,:) = nanmean(dat,1);
    TEPsGrand.time(j,:) = TEPs(1,j).time;
    TEPsGrand.name{j} =  TEPs(1,j).ROIname;
end

figure,plot(TEPsGrand.time(1,:),TEPsGrand.avg(:,:))

% FIND TIMES FOR PEAKS
tForAUC = [0 50;50 100;100 150;150 250];
tNames = {'0-50';'50-100';'100-150';'150-250'};

clear AUC
for i = 1:size(data,2) % FOR EACH CONDITION
    for j = 1:size(cfg.regs,2) % FOR EACH ROI
        for k = 1:length(tForAUC) % For EACH TIMEFRAME
            tDat = find(TEPs(i,j).time > tForAUC(k,1) & TEPs(i,j).time < tForAUC(k,2));
            TEPs(i,j).AUC(k) = trapz(TEPs(i,j).time(tDat),TEPs(i,j).avg(tDat));
            AUC(i,j,k) = TEPs(i,j).AUC(k);
            TEPs(i,j).componentNames{k} = tNames{k};
        end
    end
end

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







