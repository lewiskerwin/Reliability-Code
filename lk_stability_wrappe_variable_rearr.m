%% WRAPPER FOR STABILITY CODE
% EDITED 11/03
% ---------------------------------
close all
[cfg] = spTMS_start();      % INITIALIZES ALL VALUES

% ---------------------------------
% INPUT VALUES FOR CODE
cfg.file.subs = {'112';'113';'114'; '115'}; cfg.file.preconds = {'1';'2'};%'final';'washout'};
cfg.file.precond_include(1,:) = {'fromConcat_120'}; 
cfg.file.precond_exclude(1,:) = {'arm' 'PostRTMS' 'PreRTMS'};

%So lets find out how we'll bin up the AUCs
 cfg.regs = [];
%  These ones are new, but for QC I'm using Corey's
%  cfg.regs(1).name = 'Left DLPFC';cfg.regs(1).chan = [17 18 29 30];
%  cfg.regs(2).name = 'Right DLPFC';cfg.regs(2).chan = [8 9 20 21];
%  cfg.regs(3).name = 'Left Parietal';cfg.regs(3).chan = [26 27];
%  cfg.regs(4).name = 'Right Parietal';cfg.regs(4).chan = [23 24];
%  cfg.regs(5).name = 'Occipital';cfg.regs(5).chan = [49 50 51];
%  cfg.regs(6).name = 'Central';cfg.regs(6).chan = 1:7;
 
 cfg.regs(1).name = 'Left DLPFC';cfg.regs(1).chan = [17 18 29 30];
 cfg.regs(2).name = 'Right DLPFC';cfg.regs(2).chan = [8 9 20 21];
 cfg.regs(3).name = 'Left Parietal';cfg.regs(3).chan = [26 27];
 cfg.regs(4).name = 'Right Parietal';cfg.regs(4).chan = [23 24];
 cfg.regs(5).name = 'Centroparietal';cfg.regs(5).chan = [5 12 13 14 25];
 cfg.regs(6).name = 'Centrofrontal';cfg.regs(6).chan = [2 8 18 19 31];
 %cfg.regs(7).name = 'Global';cfg.regs(7).chan = 1:64;
 for ireg=1:length(cfg.regs)
        axisname{ireg} = cfg.regs(ireg).name;
 end
   
cfg.peak.target = [50, 100, 200];
cfg.peak.wiggle = 20;
cfg.peak.width = 5;
cfg.peak.wndwnames = strread(num2str(cfg.peak.target),'%s');

cfg.numsplit=2;
cfg.trialincr = 10;

%LOAD DATA BASED ON INCLUSION/EXCLUSION CRITERIA
data = lk_loaddata(cfg);


%FIND LOWEST # TRIALS
cfg.trialnumber =150;
for isub=1:size(data,1)
    for icond=1:size(data,2)
        if cfg.trialnumber > size(data(isub,icond).EEG.data,3)
            cfg.trialnumber = size(data(isub,icond).EEG.data,3);
        else; end      
    end
end

%%
%New start to reliability (before integrating AUC) - should integrate into
%load data
clear reliability
cutinitialtime=5;
for isub=1:size(data,1)
    for icond=1:size(data,2)
        reliability.amp(:,:,:,icond,isub) = data(isub,icond).EEG.data(:,cutinitialtime:size(data(isub,icond).EEG.data,2),1:cfg.trialnumber);
        %electrodes x time x trials x cond x sub
        reliability.times(:,icond,isub) = data(isub,icond).EEG.times(cutinitialtime:size(data(isub,icond).EEG.data,2));
    end
end


%FIND PEAK AND WINDOWS


% May want to QC since results kinda disconcerting: lots of latency
% differences... also the average of latencies is not the latency of
% averages...Maybe check that this is the case on the scale of all trials?
% (i.e. all 100 averaged gives what latency(chekc with CANVAS) and avg of
% latencies of all 100 individually? variance of latencies individuall?
% if different (or high variances) this at least tells em why there's so
% much disagreement between splits here
[reliability.amplat] =   lk_findwndw(reliability,cfg);
% Region x wndw x split x cond x sub x TI


%CALC AUC FOR THESE WINDOWS
reliability = lk_AUC_TI(reliability, cfg);
%Region x wndw x split x cond x sub x TI




%%
%FILL RELIABILITY.AUC TO MAKE EQUAL TO DATA - I don't need to run earlier
%to parcel findwndw into individual latencies... but might help so I can
%write for reliability instead of data
%6x3x107x2x4
%reliability.AUC = zeros(size(cfg.regs,2),size(cfg.peak.wndw,1),150,size(cfg.file.preconds,1),size(cfg.file.subs,1));

[cfg.peak.wndw, cfg.peak.wndwnames] = lk_findwndwfromdata(data,cfg);

data = lk_AUC_data(data,cfg);


clear reliability
for isub=1:size(data,1)
    for icond=1:size(data,2)
        reliability.ampauc_bytrial(:,:,:,icond,isub) = data(isub,icond).EEG.AUC(:,:,1:cfg.trialnumber);
    end
end


% %FILL RELIABILITY.AUCTI (trial increment)-THis code only takes avg over
% all trials for each condition
% for itrial=1:cfg.trialnumber
%    reliability.ampaucTI(:,:,itrial,:,:)= mean(reliability.ampauc(:,:,1:itrial,:,:),3);
% end


%BIN AUC ACROSS TRIALS INTO n SPLITS
for iTI=1:cfg.trialnumber/cfg.trialincr%Increase trial
    splitlength = floor(iTI*cfg.trialincr/cfg.numsplit);
    for isplit =1:cfg.numsplit %Go through each split
        splitrange = (isplit-1)*(iTI*cfg.trialincr/cfg.numsplit)+1:(isplit)*(iTI*cfg.trialincr/cfg.numsplit);
        reliability.ampauc(:,:,isplit,:,:,iTI) = mean(reliability.ampauc_bytrial(:,:,splitrange,:,:),3);
    end
end
%%
%Label the dimensions of AUC
reliability.AUCdim{1} = 'region';
reliability.AUCdim{2} = 'window';
reliability.AUCdim{3} = 'split';
reliability.AUCdim{4} = 'condition';
reliability.AUCdim{5} = 'subject';

%FIND ICC FOR EACH TRIAL SPLIT
reliability = lk_varianceTI(reliability,cfg);

%PLOT EFFECT OF INCREASING TRIAL NUMBER ON ICC
figure('Position', [100, 100, 1450, 1200])
iccdim=3;%We only care about ICC between subjects
for iwndw=1:size(cfg.peak.wndw,1)
   for ireg = 1:size(cfg.regs,2) 
        subplot(size(cfg.peak.wndw,1),2,(iwndw-1)*2+1)
        plot(cfg.trialincr:cfg.trialincr:cfg.trialnumber,squeeze(reliability.ICC(:,iwndw,iccdim,:)));
        legend(cfg.regs(:).name,'Location','southeast');
        TITLE = 'ICC between %ss at %s-ms peak \n as a function of trial number';
        title(sprintf(TITLE,reliability.ICCdim{iccdim},cfg.peak.wndwnames{iwndw}));
         xlabel('Trial Number');
           end
end

sdcdim=2;
for iwndw=1:size(cfg.peak.wndw,1)
   for ireg = 1:size(cfg.regs,2) 
        subplot(size(cfg.peak.wndw,1),2,iwndw*2)
        plot(cfg.trialincr:cfg.trialincr:cfg.trialnumber,squeeze(reliability.SDC(:,iwndw,sdcdim,:)));
        legend(cfg.regs(:).name,'Location','northeast');
        TITLE = 'Smallest Detectable Change In a Post-Intervention %s \n at %s-ms peak as a function of trial number';
        title(sprintf(TITLE,reliability.ICCdim{sdcdim},cfg.peak.wndwnames{iwndw}));
        xlabel('Trial Number'); ylabel('Detectable AUC Change');
   end
end



%%
%Older binning that didn't do trial increment
cfg.numsplit = 2;
reliability = lk_binFromRegionsAUC(data,cfg);



%PEARSON TIME - need to rewrite for AUCTI
%start with split 1 vs 2 AND cond 1 vs cond 2 in many different splits
reliability=lk_pearson(reliability,cfg);

%You can play with numer of splits for this function
%numsplit = 3;
%reliability = lk_binFromRegionsAUC(data,cfg,numsplit,wndw,subs,conds);

%This gives a data point for every region-window combo
reliability=lk_pearson_2(reliability,cfg);

%for single subjects
reliability = lk_singlepearson(reliability,data,cfg,1)

%%
%FIND VARIANCE, SEM, SDC and ICC LOOKING AT ONE REGION-WINDOW AT A TIME

 reliability = lk_variance(reliability, cfg);
 
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
   

%PRESENT ICC FINDINGS FOR ALL TRIAL NUMBERS
for itrial = cfg.trialincr:cfg.trialincr:cfg.trialnumber
    C = reliability.ICC(:,:,3,itrial);%We only display ICC between subjects because we WANT trivial ICC values between conditions and splits
    subplot(5,5,(itrial/cfg.trialincr))
    imagesc(C, 'CDataMapping','scaled')
    colorbar
    colormap jet
    title (['ICC across various ' reliability.dims{3} 's'])
   % set(gca,'YTickLabel', cfg.regs.name);
    %set(gca,'XTick',1:4,'XTickLabel', wndwNames);
end

    
    C= reliability.SDC(:,3,1)
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
%This code is designed to present the saem finddings for all dimensions

%Define common axes for different comparisons
for idim=1:length(reliability.dims)

MIN(1,idim) = min(min(reliability.ICC(:,:,idim)))
MAX(1,idim) = max(max(reliability.ICC(:,:,idim)))

MIN(2,idim) = min(min(reliability.SDC(:,:,idim)))
MAX(2,idim) = max(max(reliability.SDC(:,:,idim)))
end

clear yname
for ireg=1:length(cfg.regs)
   
    yname{ireg} = cfg.regs(ireg).name
    
end


figure
for subploti=1:length(reliability.dims)
    
    if subploti == 3
        %Plot ICC
        subplot(1,3,subploti)
        C = reliability.ICC(:,:,subploti);
        imagesc(C, 'CDataMapping','scaled')
        colorbar
        colormap jet
        title (['ICC across various ' reliability.dims{subploti} 's'])
        set(gca,'YTickLabel', yname);
        set(gca,'XTick',1:4,'XTickLabel', wndwNames);
    else
        %Plot SDC
        subplot(1,3,subploti)
        C = reliability.SDC(:,:,subploti);
        imagesc(C, 'CDataMapping','scaled')
        colorbar
        title (['Smallest detectable change between two ' reliability.dims{subploti} 's'])
        caxis manual
        caxis([min(MIN(2,:)) max(MAX(2,:))]);
        set(gca,'YTickLabel', yname);
        set(gca,'XTick',1:4,'XTickLabel', wndwNames);
    end
    
end

%%
%QUALITY CONTROL CODE
%Make artificial data of random numbers between 0 and 1
QC.AUC = rand(6,4,2,2,5)
QC.AUCdim = reliability.AUCdim;
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
