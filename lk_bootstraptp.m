function [stats] = lk_bootstraptp(reliability,cfg,feature,comparison)

for iTI = 1:floor(cfg.trialnumber/cfg.trialincr)
trialmax = iTI*cfg.trialincr;
splitlength = trialmax/cfg.numsplit;
bootlength = floor(trialmax/cfg.bootnumber);%Depends on iTI
featureddata = reliability.(cfg.featuretoplot{feature});
    
    switch comparison
        
        %PRE-BIN DATA FOR COND:
        case 1
            
            prebindata = squeeze(featureddata(:,:,:,:,:,iTI));% This is the line that will differ cond vs split
            
            
        %PRE-BIN DATA FOR SPLIT HALF - rearranges all data to do split half
        case 2
            clear prebindata
            trialmax = iTI*cfg.trialincr;
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
            
            trialmax = iTI*cfg.trialincr;
            altsplitrange = (0:cfg.numsplit:trialmax-cfg.numsplit)+1;
            
            for icond = 1:cfg.condnumber
                for isplit = 1:cfg.numsplit
                    temp = squeeze(featureddata(:,:,(altsplitrange+isplit-1),icond,:,iTI));
                    prebindata(:,:,(altsplitrange+icond-1),isplit,:) =temp;
                    %Now "condition" 1 has only odds and "condition" 2 has only evens
                end
            end
            
    end
    
    %BOOTSTRAP (economize by only doing one reg winddw at time)
    for ireg =1:cfg.regnumber
        for iwndw = 1:cfg.wndwnumber
            
            %break AUC into boots
            for iboot= 1:cfg.bootnumber
                bootrange = (iboot-1)*bootlength+1:bootlength*iboot; %Ten blocks of trials per condition
                %Or for splits, this will be ten blocks of trials in each
                %split! So bootrange is the same, but for different splits I'll have to rearrange input table
                binneddata(iboot,:,:) = squeeze(mean(prebindata(ireg,iwndw,bootrange,:,:),3));
            end
            
            clear pearson ttest CCC ICC SDC statmat
            
            %ENTER ITERATION
            rng(0,'twister');
            bootsignature = randi([1 cfg.bootnumber],1,cfg.bootnumber,cfg.itnumber);
            for iit=1:cfg.itnumber %100 itereations
                
                statmat = squeeze(mean(binneddata(bootsignature(:,iit),:,:),1))';
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
            stats.SDCp(ireg,iwndw,iTI) = stats.SDC(ireg,iwndw,iTI)./mean(mean(mean(binneddata)));
            
            
        end
    end
end
end