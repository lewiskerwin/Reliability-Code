function [stats] = lk_halfsample(reliability,cfg,feature,comparison)

rng(0,'twister');

%CYCLE THROUGH TRIAL NUMBERS
for iTI = 1:floor(cfg.trialnumber/cfg.trialincr) 
trialmax = iTI*cfg.trialincr; %number of trials we're looking at here
splitlength = trialmax/cfg.numsplit; %numsplit is set to 2 for code to work

cfg.bootnumber= iTI; %Have exactly one boot per ten trials (i.e per one block)
cfg.sampleperboot = cfg.trialincr/2; % For each boot, take 50% 
cfg.itnumber=100; %100 interations
bootlength = cfg.trialincr; %Always 10 with half-sampling
featureddata = reliability.(cfg.featuretoplot{feature});
    
    switch comparison
        
        %PRE-BIN DATA FOR COND:
        case 1
            
            prebindata = squeeze(featureddata(:,:,1:trialmax,:,:,iTI));% This is the line that will differ cond vs split
            
            
        %PRE-BIN DATA FOR SPLIT HALF - rearranges all data to do split half
        case 2
            clear prebindata
            splitlength = trialmax/cfg.numsplit;
            splitrange = 1:splitlength; % keep basic and update in loops below
            
            for icond = 1:cfg.condnumber
                for isplit = 1:cfg.numsplit
                    temp = squeeze(featureddata(:,:,splitrange+(splitlength*(isplit-1)),icond,:,iTI));
                    prebindata(:,:,splitrange+(splitlength*(icond-1)),isplit,:) =temp;
                    %Now "condition" 1 has only 1st half and "condition" 2 has 2nd half
                end
            end
            
        %PRE-BIN DATA FOR ALT BOOTSTRAPPING
        case 3
            clear prebindata
            altsplitrange = (0:cfg.numsplit:trialmax-cfg.numsplit)+1;
            
            for icond = 1:cfg.condnumber
                for isplit = 1:cfg.numsplit
                    temp = squeeze(featureddata(:,:,(altsplitrange+isplit-1),icond,:,iTI));
                    prebindata(:,:,(altsplitrange+icond-1),isplit,:) =temp;
                    %Now "condition" 1 has only odds and "condition" 2 has only evens
                end
            end
            
    end
    
   %HALF-SAMPLE AT 100 ITERATIONS
   clear samplekey
    for iit = 1:cfg.itnumber
       for iboot = 1:cfg.bootnumber
            samplekey(iit,:,iboot) = datasample([1:bootlength],5,'Replace',false) + ((iboot-1)*bootlength);%use for every boot, reg, wndw
       end
   end
   samplekey = reshape(samplekey, [cfg.itnumber, 5*cfg.bootnumber]);
    
   %RUN STATS ON EACH ITERATION (FOR EACH REG/WNDW COMBO)
    for ireg =1:cfg.regnumber
        for iwndw = 1:cfg.wndwnumber
           
            for iit=1:cfg.itnumber
                statmat = squeeze(mean(prebindata(ireg,iwndw,samplekey(iit,:),:,:),3))';
                [pearson(iit), ttest(iit), CCC(iit), ICC(iit), SDC(iit)] = lk_stats(statmat,cfg);
            end
            stats.pearson(ireg,iwndw,iTI) = mean(pearson);
            stats.pearsons(ireg,iwndw,iTI) = std(pearson);
            stats.ttest(ireg,iwndw,iTI) = mean(ttest);
            stats.ttests(ireg,iwndw,iTI) = std(ttest);
            stats.CCC(ireg,iwndw,iTI) = mean(CCC);
            stats.CCCs(ireg,iwndw,iTI) = std(CCC);
            stats.ICC(ireg,iwndw,iTI) = mean(ICC);
            stats.ICCs(ireg,iwndw,iTI) = std(ICC);
            stats.SDC(ireg,iwndw,iTI) = mean(SDC);
            stats.SDCs(ireg,iwndw,iTI) = std(SDC);
            stats.SDCp(ireg,iwndw,iTI) = stats.SDC(ireg,iwndw,iTI)./mean(mean(mean(prebindata(ireg,iwndw,:,:,:))));
            
            
        end
    end
end
end