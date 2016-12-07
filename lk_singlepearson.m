%start with split 1 vs 2
%FUNCTION DESIGNED FOR SINGLE-SUBJECT ANALYSIS
function reliability=lk_singlepearson(reliability,data,cfg,sub)

clear axisname  pearsonmatrix


%Set axis name
for ireg=1:length(cfg.regs)
    axisname{ireg} = cfg.regs(ireg).name;
end

%FIND NUMBER OF TRIALS IN COND WITH FEWEST TRIALS
cfg.single.mintrial(sub)=150;
for icond=1:size(data,2)
    if size(data(sub,icond).EEG.AUC,3)<cfg.single.mintrial(sub)
        cfg.single.mintrial(sub) = size(data(sub,icond).EEG.AUC,3); 
    else; end;
end
splitlength = floor(cfg.single.mintrial(sub)/cfg.numsplit);

%DEFINE AUCmatrix TO HAVE THIS NUMBER OF TRIALS
AUCmatrix = zeros(size(cfg.regs,2),size(cfg.peak.wndw,1),cfg.single.mintrial(sub),size(data,2))

%POPULATE PEARSON MATRIX
pearsonduration=250;
pearsontimebin=10;
for icond=1:2 
    starttime = -data(sub,icond).EEG.times(1);
    for ireg =1:size(cfg.regs,2)
        for itime=1:pearsonduration/pearsontimebin
            timerange= (starttime + (itime-1)*pearsontimebin +1):(starttime + itime*pearsontimebin);
            for isplit=1:cfg.numsplit
                splitrange= ((isplit-1)*splitlength+1):isplit*splitlength;
                %Three averages: over electrodes in region, over times in
                %timebin, over all conditions
                pearsonmatrix(ireg,itime,isplit,icond) = mean(mean(mean(data(sub,icond).EEG.data(cfg.regs(ireg).chan,timerange,splitrange),1),2),3);
            end
        end
    end
end

%SPLIT-HALF PEARSON
for ireg=1:size(cfg.regs,2)
   x = mean(pearsonmatrix(ireg,:,:,1),3)';%per wei's rec we average across trials for time serires
   y = mean(pearsonmatrix(ireg,:,:,2),3)';
   reliability.single.pearson(ireg,1,sub) = corr(x,y);
   
end
%graph
reliability.image(1) = subplot(3,2,1)
imagesc(reliability.single.pearson(:,1,sub)')
TITLE = 'Pearson Correlation Between Splits for Subject %d';
title (sprintf(TITLE,sub))
for ireg=1:length(cfg.regs)
    axisname{ireg} = cfg.regs(ireg).name;
end
set(gca,'XTickLabel', axisname,'YTickLabel', '','XAxisLocation', 'top' );
xlabel('Regions');
colorbar
caxis([0,1])

%INTER-CONDITION PEARSON
for ireg=1:length(cfg.regs)
   x = mean(pearsonmatrix(ireg,:,1,:),4)';
   y = mean(pearsonmatrix(ireg,:,2,:),4)';
   reliability.single.pearson(ireg,2,sub) = corr(x,y);
   
end
%graph
reliability.image(2) = subplot(3,2,2)
imagesc(reliability.single.pearson(:,2,sub)')
TITLE = 'Pearson Correlation Between Contidtions for Subject %d';
title (sprintf(TITLE,sub))
for ireg=1:length(cfg.regs)
    axisname{ireg} = cfg.regs(ireg).name;
end
set(gca,'XTickLabel', axisname,'YTickLabel', '','XAxisLocation', 'top' );
xlabel('Regions');
colorbar
caxis([0,1])

%POPULATE AUCMATRIX FOR T TEST
for icond=1:size(data,2)
    AUCmatrix(:,:,:,icond) = data(sub,icond).EEG.AUC(:,:,1:cfg.single.mintrial(sub));
end


%SPLIT-HALF T-test
for ireg=1:size(cfg.regs,2)
    for iwndw = 1:size(cfg.peak.wndw,1)
        
        x = reshape(AUCmatrix(ireg,iwndw,1:splitlength,:),[],1);%One half (both conds combined)
        y = reshape(AUCmatrix(ireg,iwndw,splitlength+1:(2*splitlength),:),[],1);%The other half
        [reliability.single.ttesth(ireg,iwndw,1,sub),reliability.single.ttestp(ireg,iwndw,1,sub)] = ttest(x,y);
       
        
    end
end
%graph
reliability.image(3) =subplot(3,2,3)
 imagesc(reliability.single.ttestp(:,:,1,sub)')
TITLE = 'T-Test p value Between Splits for Subject %d';
title (sprintf(TITLE,sub))
for ireg=1:length(cfg.regs)
    axisname{ireg} = cfg.regs(ireg).name;
end
set(gca,'XTickLabel', axisname,'YTick',1:4,'YTickLabel', cfg.peak.wndwnames,'XAxisLocation', 'top');
ylabel('Peak Windows'); xlabel('Regions');
colorbar
caxis([0,1])

%INTER-CONDITION T-Test
for ireg=1:length(cfg.regs)
    for iwndw = 1:size(cfg.peak.wndw,1)
        x = reshape(AUCmatrix(ireg,iwndw,1:cfg.single.mintrial(sub),1),[],1);
        y = reshape(AUCmatrix(ireg,iwndw,1:cfg.single.mintrial(sub),2),[],1);
        [reliability.single.ttesth(ireg,iwndw,2,sub),reliability.single.ttestp(ireg,iwndw,2,sub)] = ttest(x,y);
        %reliability.single.pearson(ireg,iwndw,2,sub) = corr(x,y);
        
    end
end

reliability.image(4) =subplot(3,2,4)
imagesc(reliability.single.ttestp(:,:,2,sub)')
TITLE = 'T-Test p value Between Conditions for Subject %d';
title (sprintf(TITLE,sub))
for ireg=1:length(cfg.regs)
    axisname{ireg} = cfg.regs(ireg).name;
end
set(gca,'XTickLabel', axisname,'YTick',1:4,'YTickLabel', cfg.peak.wndwnames,'XAxisLocation', 'top');
ylabel('Peak Windows'); xlabel('Regions');
colorbar

%change subplot hegiht
figsize = get(reliability.image(3),'position')
height = figsize(4) 
%...for the split half pearson
figsize = get (reliability.image(1),'position')
figsize(4) = height/3
set(reliability.image(1),'position',figsize)
%And for the inter-condtiion perason
figsize = get (reliability.image(2),'position')
figsize(4) = height/3
set(reliability.image(2),'position',figsize)
   




end