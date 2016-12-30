%% WRAPPER FOR STABILITY CODE
% EDITED 11/03
% ---------------------------------
close all
[cfg] = spTMS_start();      % INITIALIZES ALL VALUES
[cfg.stabilityresults] = uigetdir('','Pick Results folder in stability proj');

cfg.file = [];
switch cfg.project{:}
    case 'rTMS'
        %Corey Config
        cfg.file.subs = {'112';'113';'114'; '115';}; cfg.file.preconds = {'1';'2'};%'final';'washout'};
        cfg.file.precondprefix = {'pre', ''; '_', '_'};
        cfg.file.precond_include(1,:) = {'fromConcat_120'};
        cfg.file.precond_exclude(1,:) = {'arm', 'PostRTMS','PreRTMS'};
        
    case 'vlpfc_TBS'
        %Cammie Config
        cfg.file.subs = {'105';'110'; '116';'118';'121';'122'}; cfg.file.preconds = {'right';'left'};%'final';'washout'};
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

%fieldnames(reliability); - can use this for higher versatility
cfg.featuretoplot = {'ampauc', 'amplat'};
cfg.comparisontoplot = {'cond', 'split', 'alt'};

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
    end
end

%BASELINE CORRECT PER COREY'S REC (significantly altars some conditions and not others, SDC lower without this)
%[reliability] = lk_BLC(reliability,cfg);

%FIND LATENCY OF INVDL TRIALS AND EACH SUB'S AVG
[reliability.amplat, reliability.avgamplat, reliability.ampauc, reliability.ampmax] = lk_findwndw(reliability,cfg);
% Region x wndw x split x cond x sub x TI   
% Reg x wndw x cond x sub x TI - average amplitude latencys

%%
%QC to ensure integral of avg = avg of integral
ireg=1; iwndw=2; iTI=8;
for isub = 1:cfg.subnumber
    for icond = 1:cfg.condnumber
        %First avg of integral
        AofI(icond,isub) = mean(reliability.ampauc(ireg,iwndw,:,icond,isub,iTI),3);
        % conds x subs
        
        %now integral of avg
        AofA(:,icond,isub) = mean(mean(reliability.amp(cfg.regs(ireg).chan,:,:,icond,isub),1),3);
        %time x conds x subs
        alltimes = reliability.times(:,icond,isub);
        targetidx = find(alltimes == reliability.avgamplat(ireg,iwndw,isub,iTI));
        peakrangeidx = targetidx - cfg.peak.width(iwndw) : targetidx + cfg.peak.width(iwndw);
        IofA(icond,isub) = trapz(peakrangeidx,AofA(peakrangeidx,icond,isub));
        %conds x subs
    end
end

%%

%CALC AUC FOR THESE AVG LATENCIES (NOW DONE IN CODE ABOVE)
%reliability = lk_AUC_TI(reliability, cfg);
%Region x wndw x trial x cond x sub x TI - each trial may have different
%latency window at different TI values


%CALCULATE AUC STATISTICS WITH BOOTSTRAPPING 
cfg.bootnumber =10; %Number of bins ("boots") that each data point will be divided into which will be sorted and allocated randomly
cfg.itnumber= 100; %Number of iterations

feature= 1; %amp = 1 lat =2

comparison = 1; %Compare two conditions
[reliability.([cfg.featuretoplot{feature} cfg.comparisontoplot{comparison}])] = lk_bootstrap(reliability,cfg,feature,comparison);

comparison = 2; %Compare split half (requires numsplit to be 2 to catch all data)
[reliability.([cfg.featuretoplot{feature} cfg.comparisontoplot{comparison}])] = lk_bootstrap(reliability,cfg,feature,comparison);

comparison = 3; %Compares odds vs even trials (requires numsplit to be 2 to catch all data)
[reliability.([cfg.featuretoplot{feature} cfg.comparisontoplot{comparison}])] = lk_bootstrap(reliability,cfg,feature,comparison);


% %WAVEFORM FIGURE (CONTAINS COREY'S SAVE FIG)
 iTI =6;
ireg =3;
isub=2;
lk_waveformplot2(reliability,cfg,iTI,ireg,isub);




%PLOT EFFECT OF INCREASING TRIAL NUMBER ON CCC
figure('Position', [100, 100, 1450, 1200])

%DEFINE PARTS OF STRUCTURE TO PLOT
%fieldnames(reliability); - can use this for higher versatility
comparisonlabel = {'Condition 1 vs 2', 'Split 1 vs 2', 'Odd vs Even Trials'};
feature = 1; %Adjust here
comparison=1; %and here
fctoplot = [cfg.featuretoplot{feature} cfg.comparisontoplot{comparison}];
stattoplot(:)= {'CCC','pearson','ICC'};
statlabel(:) = {'Concordance Correlation Coefficient', 'Pearson Coefficient', 'Intraclass Correlation Coefficient'}';
featurelabel(:) = {'Area Under Curve', 'Peak Latency'};
width=length(stattoplot);


% %Below 3 lines unnecessary prob.
% statnames = fieldnames(reliability.ampauccond);
% for istat = 1:width
% stattoplotidx(istat) = strmatch(stattoplot(istat), statnames, 'exact')
% end

colorstring = 'ymcrgb';
Legend= 0;
timetoplot = (cfg.trialincr:cfg.trialincr:cfg.trialnumber)';


for istat = 1:width
    
comparisonlabeled =0;
datatoplot_allreg = reliability.(fctoplot).(stattoplot{istat});
errortoplot_allreg = reliability.(fctoplot).([stattoplot{istat} 's']);

for iwndw=1:size(cfg.peak.target,2)
    subplot(size(cfg.peak.target,2),width,(iwndw-1)*width+istat)
    
    hold on
    for ireg = 1:cfg.regnumber
        datatoplot = squeeze(datatoplot_allreg(ireg,iwndw,:));
        errortoplot = squeeze(errortoplot_allreg(ireg,iwndw,:));
        %line = plot(timetoplot,datatoplot,'-o');
        %ALTERNATIVE LINE IF WE WANNA SEE ERROR
        line(ireg) = shadedErrorBar(timetoplot,datatoplot,errortoplot,{['-o' colorstring(ireg)],'markerfacecolor',colorstring(ireg)},1);
    end
    hold off
    
    %Add "odd vs even" only on top row of graphs
    if iwndw==1
        %Top middle gets special AUC vs LAT
        if istat == (floor(width/2)+1)
            TITLE = '%s in %s \n %s \n %s-ms peak';
            title(sprintf(TITLE,featurelabel{feature},comparisonlabel{comparison},statlabel{istat},cfg.peak.wndwnames{iwndw}));
        else
            TITLE = '%s \n %s-ms peak';
            title(sprintf(TITLE,statlabel{istat},cfg.peak.wndwnames{iwndw}));
        end
    else
        TITLE = '%s-ms peak';
        title(sprintf(TITLE,cfg.peak.wndwnames{iwndw}));

    end
   
    
    xlabel('Trial Number'); %ylabel(statlabel{istat});
    
    if strcmp(stattoplot{istat}, 'SDC') axis( [0 cfg.trialnumber 0 200]);
    else axis( [0 cfg.trialnumber 0 1]);
    end
    box off; grid on;

    
    
end

end
subplot(4,3,8);
plotposa = get(gca,'Position');
subplot(4,3,11);%go to middle bottom
plotposb = get(gca,'Position');
hL = legend([line.mainLine],cfg.regs(:).name,'Orientation','horizontal','box','off');
onebelow = plotposb(2)-(plotposa(2)-plotposb(2));
legpos = [plotposb(1) onebelow+0.05 0.2 0.2];
        set(hL,'Position', legpos,'box','off');

Date = datestr(today('datetime'));
fname = [cfg.project{:} '_' fctoplot '_' [stattoplot{:}] '_' Date];
cd = cfg.stabilityresults;
ckSTIM_saveFig(fname,10,10,300,'',4,[10 8]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%WRAPPER STOPS HERE%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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
