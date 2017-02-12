%% WRAPPER FOR STABILITY CODE
% EDITED 11/03
% ---------------------------------
close all
[cfg] = spTMS_start();      % INITIALIZES ALL VALUES
[cfg.stabilityresults] = uigetdir('','Pick Results folder in stability proj');

cfg.file = [];
switch cfg.ProjectName
    case 'rTMS'
        %Corey Config old
        cfg.file.subs = {'112';'113';'114'; '115';}; cfg.file.preconds = {'1';'2'};%'final';'washout'};
        cfg.file.subprefix = [];
        cfg.file.precondprefix = {'pre', ''; '_', '_'};
        cfg.file.precond_include(1,:) = {'fromConcat_120'};
        cfg.file.precond_exclude(1,:) = {'arm', 'PostRTMS','PreRTMS'};
        cfg.file.day = {'tp1';'tp2'};
    
    case 'rtms' %New folder within allresults
        cfg.file.subs = {'116';'117';'118'; '119';'120';'121';'122';}; cfg.file.preconds = {'1';'2'};%'final';'washout'};
        cfg.file.subprefix = 'rtms_';
        cfg.file.precondprefix = {'pre', ''; '_', '_'};
        cfg.file.precond_include = [];
        cfg.file.precond_exclude(1,:) = {'arm', 'PostRTMS','PreRTMS'};
        cfg.file.day = {'tp1';'tp2'};
        
    case 'Stability'
        %My Config
        cfg.file.subs = {'112';'113';'114'; '115';}; cfg.file.preconds = {'1';'2'};%'final';'washout'};
        cfg.file.subprefix = [];
        cfg.file.precondprefix = {'pre', ''; '_', '_'};
        cfg.file.precond_include(1,:) = {'fromConcat_120'};
        cfg.file.precond_exclude(1,:) = {'arm', 'PostRTMS','PreRTMS'};
        cfg.file.day = {'tp1';'tp2'};
        
    case 'vlpfc_TBS'
        %Cammie Config
        cfg.file.subs = {'105';'110'; '116';'118';'121';'122'}; cfg.file.preconds = {'right';'left'};
        cfg.file.subprefix = [];
        cfg.file.precondprefix = { '', ''};
        cfg.file.precond_include(1,:) = {'vlpfc'};
        cfg.file.precond_exclude(1,:) = {'garbag'};
        

end

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
  
cfg.peak.target = [30, 60, 110, 200];
cfg.peak.wiggle = [15, 15, 35, 55]; %How far from target condition avg can be
cfg.peak.precision = cfg.peak.wiggle ./2; %How far from cond avg, each split can be
cfg.peak.width = [5, 5, 10, 15];
cfg.peak.wndwnames = strread(num2str(cfg.peak.target),'%s');
cfg.wndwnumber = size(cfg.peak.target,2);

cfg.numsplit= 2;
cfg.trialincr = 10;
cfg.itnumber=2; %10 interations can increase to 100
cfg.sampleperboot = cfg.trialincr/1; % For each boot, take 50%



%fieldnames(data); - can use this for higher versatility
cfg.feature = {'amplat', 'ampmax', 'ampcauc', 'ampsauc'};
cfg.stat = {'pearson', 'tp', 'CCC', 'ICC', 'SDC'};


%LOAD DATA BASED ON INCLUSION/EXCLUSION CRITERIA
% [tempdata, cfg] = lk_loaddata(cfg); % Need to make cd() work better
% cfg.totaltrialnumber = cfg.trialnumber*cfg.condnumber*cfg.daynumber;
% cfg.TInumber = floor(cfg.trialnumber/cfg.trialincr);

[tempdata,cfg] = lk_loaddatatp(cfg);
cfg.totaltrialnumber = cfg.trialnumber*cfg.condnumber*cfg.daynumber;
cfg.TInumber = floor(cfg.trialnumber/cfg.trialincr);
cfg.TItocompare = [1,2,4,8];

if isempty(cfg.file.day) 
    cfg.comparison = {'alt','split','cond', 'timepoint','TI'};
    cfg.comparisonlabel = {'Odd vs Even Trials','Split 1 vs 2','Condition 1 vs 2','Day 1 vs 2', ['X Trials vs ' num2str(cfg.trialnumber)]};
else
    cfg.comparison = {'alt','split','cond','TI'}; 
    cfg.comparisonlabel = {'Odd vs Even Trials','Split 1 vs 2','Condition 1 vs 2', ['X Trials vs ' num2str(cfg.trialnumber)]};
end
cfg.compnumber = size(cfg.comparison,2);

%%
%NOW CONVERT TO SINGLE MATRIX 'DATA'
% clear data
% cnt=1;
% cutinitialtime=1;
% for isub=1:size(tempdata,1)
%     for icond=1:size(tempdata,2)
%         data.amp(:,:,:,icond,isub) = tempdata(isub,icond).EEG.data(:,cutinitialtime:size(tempdata(isub,icond).EEG.data,2),1:cfg.trialnumber);
%         %electrodes x time x trials x cond x sub
%         data.times(:,icond,isub) = tempdata(isub,icond).EEG.times(cutinitialtime:size(tempdata(isub,icond).EEG.data,2));
%     end
% end
% cfg.alltimes = data.times(:,1,1); 


%ALT CODE FOR MULTIPLE TIMEPOINTS
clear data
cnt=1;
cutinitialtime=1;
for isub=1:cfg.subnumber
    for iday =1:cfg.daynumber
        for icond=1:cfg.condnumber
            data.amp(:,:,:,icond,iday,isub) = tempdata(isub,iday,icond).EEG.data(:,cutinitialtime:size(tempdata(isub,iday,icond).EEG.data,2),1:cfg.trialnumber);
            %electrodes x time x trials x cond x day x sub
            data.times(:,icond,iday,isub) = tempdata(isub,iday,icond).EEG.times(cutinitialtime:size(tempdata(isub,iday,icond).EEG.data,2));
        end
    end
end
cfg.alltimes = data.times(:,1,1); 

clear stats
tic
[stats,data] = lk_halfsampletp(data,cfg);
toc %takes an hour for 5 subs with 100 iterations, with only 1 it
 
 
 
% [stats,data] = lk_halfsampletp_forcammie(data,cfg);


%[data.amplat, data.avgamplat, data.ampauc, data.ampmax] = lk_findwndwtp(data,cfg);
%%

% %HALFSAMPLE THEN FIND PEAKS THEN RUN STATITSICS
% cfg.bootlength =10; %Number of bins ("boots") that each data point will be divided into which will be sorted and allocated randomly
%cfg.itnumber= 10; %Number of iterations
% for icomparison =1:size(cfg.comparison,2)  
%     stats = lk_halfsample_sortfirst(data,cfg,icomparison);
% end
% %comparison = 4; - FOR TP1 VS TP2

% %WAVEFORM FIGURE (CONTAINS COREY'S SAVE FIG)
iTI =1;
ireg =1;
isub=1;
icond=1;
lk_waveformplot3(data,cfg,iTI,ireg,isub,icond);


%PLOT EFFECT OF INCREASING TRIAL NUMBER ON CCC
ifeature = 3; %Adjust here
icomparison = 1; %and here
lk_plotregbystat(stats,cfg,ifeature,icomparison);


lk_plotregbycomp(stats,cfg,ifeature,istat);

%TO MAKE THIS LINE WORK WE NEED TO HAVE LK_HALFSAMPLE RECORD AVERAGED
%LATENCY, AMP AND AUC AS WELL AS CALCULATING STATS (SIMILAR TO THE "FOR
%CAMMIE" VERSION).
lk_plotTIbar(data,stats,cfg,ifeature,istat);


%%
%PEARSON TIME - need to rewrite for AUCTI
%start with split 1 vs 2 AND cond 1 vs cond 2 in many different splits
iTI=10;
data=lk_pearson(data,cfg,iTI);


 %%
%PRESENT ICC FINDINGS FOR HIGHEST TRIAL NUMBER
figure
trialmax = size(data.ICC,4)
data.dims = {'split' 'condition' 'subject'};
C = data.ICC(:,:,3,trialmax);%We only display ICC between subjects because we WANT trivial ICC values between conditions and splits
subplot(2,1,1);
imagesc(C', 'CDataMapping','scaled')
colorbar
colormap jet
title (['ICC across various ' data.dims{3} 's at ' num2str(trialmax*cfg.trialincr) ' trials.']);
set(gca,'XTickLabel',axisname);
set(gca,'YTick',1:4,'YTickLabel', cfg.peak.wndwnames);
   
C = data.SDC(:,:,2,trialmax);%We only display ICC between subjects because we WANT trivial ICC values between conditions and splits
subplot(2,1,2);
imagesc(C', 'CDataMapping','scaled')
colorbar
colormap jet
TITLE = 'Smallest Detectable Change In a Post-Intervention %s at %d trials \n (Results in arbitrary units of AUC)';
title(sprintf(TITLE,data.ICCdim{sdcdim},trialmax*cfg.trialincr));
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
    
clear datapost
datapost = lk_binFromRegionsAUC(datapost,cfg);    


baselineavg = mean(data.AUC,4);%average across conditions pre1 and pre2


change = squeeze(datapost.AUC - baselineavg); %This matrix is of change between pre(avg) and post for each reg, wndw, split, sub

%So this loop (which averages together splits) says that none of our four
%subjects have significant findings
for isub=1:length(subs)
    mean(change(:,:,:,isub),3) ./ data.SDC(:,:,2)
    
end
    

%And when I do not average over splits but look at each independently: same
%story... mostly...
for isplit=1:numsplit
for isub=1:length(subs)
    change(:,:,isplit,isub) ./ data.SDC(:,:,2)
    
end
end

squeeze(change(1,4,1,:,:))

%Let's try group SDC (divide by square root of n)
mean(mean(change(:,:,:,:),3),4) ./ (data.SDC(:,:,2)/(length(subs)^.5))


%%
%QUALITY CONTROL CODE
%Make artificial data of random numbers between 0 and 1
QC.AUC = rand(6,4,2,2,5)
QC.aucdim = data.aucdim;
%Create correlation in sigdim
sigdim = 4;
for idim=1:size(QC.AUC,sigdim)
QC.AUC(:,:,:,:,idim)=QC.AUC(:,:,:,:,idim)+idim;
end
QC = lk_variance(QC,cfg);



%Here I compare AUC calculations to raw data...looks fine
 mean(data.AUC(3,3,:,:,:),5)

%This should take data for literally ALL conditions and subjects
    %specificed at the top of wrapper
    %getauc(cfg,data) -THIS IS THE NEXT PART TO WORK ON: Take the data in
    %each cell within data and parcel up by 1)split 2)TEP component, then average across each of these and fill an array 
