%% WRAPPER FOR STABILITY CODE
% EDITED 11/03
% ---------------------------------
close all
[cfg] = spTMS_start();      % INITIALIZES ALL VALUES
[cfg.stabilityresults] = uigetdir('','Pick Results folder in stability proj');

cfg.file.subs = {'112';'113';'114'; '115'}; cfg.file.preconds = {'1';'2'};%'final';'washout'};
cfg.file.precondprefix = {'pre', ''; '_', '_'}; 
cfg.file.precond_include(1,:) = {'fromConcat_120'}; 
cfg.file.precond_exclude(1,:) = {'arm', 'PostRTMS','PreRTMS'};


%Cammie Config
cfg.file.subs = {'105';'110'; '116';'118';'121';'122'}; cfg.file.preconds = {'right';'left'};%'final';'washout'};
cfg.file.precondprefix = { '', ''};
cfg.file.precond_include(1,:) = {'vlpfc'}; 
cfg.file.precond_exclude(1,:) = {'garbag'};


%So lets find out how we'll bin up the AUCs
 cfg.regs = []; 
 cfg.regs(1).name = 'Left DLPFC';cfg.regs(1).chan = [17 18 29 30];
 cfg.regs(2).name = 'Right DLPFC';cfg.regs(2).chan = [8 9 20 21];
 cfg.regs(3).name = 'Left Parietal';cfg.regs(3).chan = [26 27];
 cfg.regs(4).name = 'Right Parietal';cfg.regs(4).chan = [23 24];
 cfg.regs(5).name = 'Centroparietal';cfg.regs(5).chan = [5 12 13 14 25];
 cfg.regs(6).name = 'Centrofrontal';cfg.regs(6).chan = [2 8 18 19 31];
 %cfg.regs(7).name = 'Global';cfg.regs(7).chan = 1:64;
 cfg.regnumber = size(cfg.regs,2);
 for ireg=1:length(cfg.regs)
        axisname{ireg} = cfg.regs(ireg).name;
 end
   
cfg.peak.target = [30, 100, 200];
cfg.peak.wiggle = [10, 30, 50]; %How far from target condition avg can be
cfg.peak.precision = cfg.peak.wiggle ./2; %How far from cond avg, each split can be
cfg.peak.width = 5;
cfg.peak.wndwnames = strread(num2str(cfg.peak.target),'%s');

cfg.numsplit= 1;
cfg.trialincr = 10;

%LOAD DATA BASED ON INCLUSION/EXCLUSION CRITERIA
data = lk_loaddata(cfg);

%FIND COMMON DENOMENATOR OF TRIALS, CONDS, SUBS
cfg.trialnumber =150;
for isub=1:size(data,1)
    for icond=1:size(data,2)
        if cfg.trialnumber > size(data(isub,icond).EEG.data,3)
            cfg.trialnumber = size(data(isub,icond).EEG.data,3);
        else; end      
    end
end
cfg.condnumber= size(data,2);
cfg.subnumber= size(data,1);


%%
%New start to reliability (before integrating AUC) - should integrate into
%load data
clear reliability
cnt=1;
cutinitialtime=1;
for isub=1:size(data,1)
    for icond=1:size(data,2)
        reliability.amp(:,:,:,icond,isub) = data(isub,icond).EEG.data(:,cutinitialtime:size(data(isub,icond).EEG.data,2),1:cfg.trialnumber);
        %electrodes x time x trials x cond x sub
        reliability.times(:,icond,isub) = data(isub,icond).EEG.times(cutinitialtime:size(data(isub,icond).EEG.data,2));
        
        
%         tablerange = ((cnt-1)*cfg.trialnumber)+1:cnt*cfg.trialnumber;
%         Table(tablerange,1) = (1:cfg.trialnumber)';
%         Table(tablerange,2) = table(permute(reliability.amp(:,:,:,icond,isub),[3 1 2 4 5]));
%         Table(tablerange,3) = cfg.file.subs(isub);
%         Table(tablerange,4) = cfg.file.preconds(icond);
%         cnt = cnt+1;

    end
end


%BASELINE CORRECT PER COREY'S REC (significantly altars some conditions and not others, SDC lower without this)
[reliability] = lk_BLC(reliability,cfg);

%FIND LATENCY OF INVDL TRIALS AND EACH SUB'S AVG
[reliability.amplat, reliability.avgamplat] =   lk_findwndw(reliability,cfg);
% Region x wndw x split x cond x sub x TI   
% Reg x wndw x cond x sub x TI - average amplitude latency

%CALC AUC FOR THESE AVG LATENCIES
reliability = lk_AUC_TI(reliability, cfg);
%Region x wndw x split x cond x sub x TI

%WAVEFORM FIGURE (CONTAINS COREY'S SAVE FIG)
iTI =10;
ireg =2;
lk_waveformplot(reliability,cfg,iTI,ireg);

ireg=2;
lk_waveformplot_cammie(reliability,cfg,ireg);
%NOTE: Code only looks at condition pre1!

%%
%CALCULATE PEARSON (DATA POINTS = REG/WNDW)
for iTI=1:floor(cfg.trialnumber/cfg.trialincr)
reliability=lk_pearson_2(reliability,cfg,iTI);
end

%CAlCULATE PEARSON (DATA POINTS = SPLIT/COND/SUB)
for iTI=1:floor(cfg.trialnumber/cfg.trialincr)
    for ireg=1:6
        for iwndw=1:3
            reliability=lk_pearson_bysplit(reliability,cfg,ireg,iwndw,iTI);
        end
    end
end

%FIND ICC FOR EACH TRIAL SPLIT
reliability = lk_varianceTI(reliability,cfg);

%PLOT EFFECT OF INCREASING TRIAL NUMBER ON ICC
figure('Position', [100, 100, 1450, 1200])
iccdim=3;%We only care about ICC between subjects
for iwndw=1:size(cfg.peak.target,2)
   for ireg = 1:size(cfg.regs,2) 
        subplot(size(cfg.peak.target,2),2,(iwndw-1)*2+1)
        plot(cfg.trialincr:cfg.trialincr:cfg.trialnumber,squeeze(reliability.ICC(:,iwndw,iccdim,:)));
        legend(cfg.regs(:).name,'Location','southeast');
        TITLE = 'ICC between %ss at %s-ms peak \n as a function of trial number';
        title(sprintf(TITLE,reliability.ICCdim{iccdim},cfg.peak.wndwnames{iwndw}));
         xlabel('Trial Number');
           end
end
%PLOT EFFECT OF INTREASING TRIAL NUMBER ON  CCC(percentage)

cccdim=2;
for iwndw=1:size(cfg.peak.target,2)
   for ireg = 1:size(cfg.regs,2) 
        subplot(size(cfg.peak.target,2),2,iwndw*2)
        plot(cfg.trialincr:cfg.trialincr:cfg.trialnumber,squeeze(reliability.finiteCCC(1,2,:,iwndw,cccdim,:)));
        %Tried plotting percent SDC, wasn't pretty.
        %plot(cfg.trialincr:cfg.trialincr:cfg.trialnumber,squeeze(mean(mean(mean(reliability.ampauc(:,iwndw,:,:,:,:),3),4),5)));

        legend(cfg.regs(:).name,'Location','northeast');
        TITLE = 'Concordance Correlation Coeffieicient In a Post-Intervention %s \n at %s-ms peak as a function of trial number';
        title(sprintf(TITLE,reliability.ICCdim{cccdim},cfg.peak.wndwnames{iwndw}));
        xlabel('Trial Number'); ylabel('CCC');
   end
end

%PLOT EFFECT OF INTREASING TRIAL NUMBER ON SDC(percentage)



sdcdim=2;
for iwndw=1:size(cfg.peak.target,2)
   for ireg = 1:size(cfg.regs,2) 
        subplot(size(cfg.peak.target,2),2,iwndw*2)
        plot(cfg.trialincr:cfg.trialincr:cfg.trialnumber,squeeze(reliability.SDC(:,iwndw,sdcdim,:)));
        %Tried plotting percent SDC, wasn't pretty.
        %plot(cfg.trialincr:cfg.trialincr:cfg.trialnumber,squeeze(mean(mean(mean(reliability.ampauc(:,iwndw,:,:,:,:),3),4),5)));

        legend(cfg.regs(:).name,'Location','northeast');
        TITLE = 'Smallest Detectable Change In a Post-Intervention %s \n at %s-ms peak as a function of trial number';
        title(sprintf(TITLE,reliability.ICCdim{sdcdim},cfg.peak.wndwnames{iwndw}));
        xlabel('Trial Number'); ylabel('Detectable AUC Change');
   end
end



%%
%PEARSON TIME - need to rewrite for AUCTI
%start with split 1 vs 2 AND cond 1 vs cond 2 in many different splits
iTI=10;
reliability=lk_pearson(reliability,cfg,iTI);


 %%
%PRESENT ICC FINDINGS FOR HIGHEST TRIAL NUMBER
figure
trialmax = size(reliability.ICC,4)
reliability.dims = {'split' 'condition' 'subject'};
C = reliability.ICC(:,:,3,trialmax);%We only display ICC between subjects because we WANT trivial ICC values between conditions and splits
subplot(2,1,1);
imagesc(C', 'CDataMapping','scaled')
colorbar
colormap jet
title (['ICC across various ' reliability.dims{3} 's at ' num2str(trialmax*cfg.trialincr) ' trials.']);
set(gca,'XTickLabel',axisname);
set(gca,'YTick',1:4,'YTickLabel', cfg.peak.wndwnames);
   
C = reliability.SDC(:,:,2,trialmax);%We only display ICC between subjects because we WANT trivial ICC values between conditions and splits
subplot(2,1,2);
imagesc(C', 'CDataMapping','scaled')
colorbar
colormap jet
TITLE = 'Smallest Detectable Change In a Post-Intervention %s at %d trials \n (Results in arbitrary units of AUC)';
title(sprintf(TITLE,reliability.ICCdim{sdcdim},trialmax*cfg.trialincr));
set(gca,'XTickLabel',axisname);
set(gca,'YTick',1:4,'YTickLabel', cfg.peak.wndwnames);
   


%%
%Put this on back burner for now! For project we just need pre
% NOW THAT WE HAVE SDC, TEST ON DATA TO SEE IF SIG
cfg.file.postconds = {'post'};
cfg.file.precond_include = {'120_post' 'fromConcat_120'}; 
cfg.file.precond_exclude = {'arm' 'PreRTMS' '115_120'};%Last iexlucsion is because of a 5 GB file for some reason in data

%So I call on load data using the inclusion and exclusion criteria
datapost = lk_loaddata(cfg);
%datapost = lk_normalize(datapost); - %We don't use this normalization
%anymore

datapost = lk_simplessAUC(datapost,cfg);
    
clear reliabilitypost
reliabilitypost = lk_binFromRegionsAUC(datapost,cfg);    


baselineavg = mean(reliability.AUC,4);%average across conditions pre1 and pre2


change = squeeze(reliabilitypost.AUC - baselineavg); %This matrix is of change between pre(avg) and post for each reg, wndw, split, sub

%So this loop (which averages together splits) says that none of our four
%subjects have significant findings
for isub=1:length(subs)
    mean(change(:,:,:,isub),3) ./ reliability.SDC(:,:,2)
    
end
    

%And when I do not average over splits but look at each independently: same
%story... mostly...
for isplit=1:numsplit
for isub=1:length(subs)
    change(:,:,isplit,isub) ./ reliability.SDC(:,:,2)
    
end
end

squeeze(change(1,4,1,:,:))

%Let's try group SDC (divide by square root of n)
mean(mean(change(:,:,:,:),3),4) ./ (reliability.SDC(:,:,2)/(length(subs)^.5))


%%
%QUALITY CONTROL CODE
%Make artificial data of random numbers between 0 and 1
QC.AUC = rand(6,4,2,2,5)
QC.aucdim = reliability.aucdim;
%Create correlation in sigdim
sigdim = 4;
for idim=1:size(QC.AUC,sigdim)
QC.AUC(:,:,:,:,idim)=QC.AUC(:,:,:,:,idim)+idim;
end
QC = lk_variance(QC,cfg);



%Here I compare AUC calculations to raw data...looks fine
 mean(reliability.AUC(3,3,:,:,:),5)

%This should take data for literally ALL conditions and subjects
    %specificed at the top of wrapper
    %getauc(cfg,data) -THIS IS THE NEXT PART TO WORK ON: Take the data in
    %each cell within data and parcel up by 1)split 2)TEP component, then average across each of these and fill an array 
