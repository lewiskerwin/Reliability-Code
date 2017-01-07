function [stats] = lk_halfsample_thenpeak(reliability,cfg,icomparison)

rng(0,'twister');

%CYCLE THROUGH TRIAL NUMBERS
for iTI = 1:floor(cfg.trialnumber/cfg.trialincr)
    cfg.trialmax = iTI*cfg.trialincr; %number of trials we're looking at here
    splitlength = cfg.trialmax/cfg.numsplit; %numsplit is set to 2 for code to work
    
    cfg.bootnumber= iTI; %Have exactly one boot per ten trials (i.e per one block)
    cfg.sampleperboot = cfg.trialincr/2; % For each boot, take 50%
    cfg.itnumber=100; %100 interations
    bootlength = cfg.trialincr; %Always 10 with half-sampling
    %featureddata = reliability.(cfg.feature{feature});
    
    switch icomparison
        
        %REARRANGE DATA TO PREPARE FOR SORTING BY COMPARISON OF INTEREST
        case 1
            
            prebindata = squeeze(reliability.amp(:,:,1:cfg.trialmax,:,:));
            
            
            %PRE-BIN DATA FOR SPLIT HALF - rearranges all data to do split half
        case 2
            clear prebindata
            splitlength = cfg.trialmax/cfg.numsplit;
            splitrange = 1:splitlength; % keep basic and update in loops below
            
            for icond = 1:cfg.condnumber
                for isplit = 1:cfg.numsplit
                    temp = squeeze(reliability.amp(:,:,splitrange+(splitlength*(isplit-1)),icond,:));
                    prebindata(:,:,splitrange+(splitlength*(icond-1)),isplit,:) =temp;
                    %Now "condition" 1 has only 1st half and "condition" 2 has 2nd half
                end
            end
            
            %PRE-BIN DATA FOR ALT BOOTSTRAPPING
        case 3
            clear prebindata
            altsplitrange = (0:cfg.numsplit:cfg.trialmax-cfg.numsplit)+1;
            
            for icond = 1:cfg.condnumber
                for isplit = 1:cfg.numsplit
                    temp = squeeze(reliability.amp(:,:,(altsplitrange+isplit-1),icond,:));
                    prebindata(:,:,(altsplitrange+icond-1),isplit,:) =temp;
                    %Now "condition" 1 has only odds and "condition" 2 has only evens
                end
            end
    end
    % ELEC x TIME X TRIALS X CONDS X SUBS
    %so now prebin data is sorted so that you can split into the two
    
    
    
    %MAKE 100 ITERATIONS WITH UNIQUE TRIAL ASSIGNMENT
    clear samplekey
    for iit = 1:cfg.itnumber
        for iboot = 1:cfg.bootnumber
            samplekey(iit,:,iboot) = datasample([1:bootlength],5,'Replace',false) + ((iboot-1)*bootlength);%use for every boot, reg, wndw
        end
    end
    samplekey = reshape(samplekey, [cfg.itnumber, 5*cfg.bootnumber]);
    % 100 ITERATIONS x iTI/2 TRIALS
    
    
    %CYCLE THROUGH ITERATIONS - THIS ALLOWS ME TO PUT REG AND WINDW IN
    %FUNCTION wndwsortfirst
    for iit =1:cfg.itnumber
        sorted = squeeze(mean(prebindata(:,:,samplekey(iit,:),:,:),3));
        %CHAN X TIME X COND/SPLIT/ALT X SUB
        
        
        %FIND LATENCY, AMPLITUDE, AND TWO TYPES OF AUC (FOR THIS IT AND TI)
        
        [peakdata] = lk_findwndw_sortfirst(sorted,cfg);
        
        %NOW RUN STATS ON THIS PEAK DATA
        clear stats
        for ireg = 1:cfg.regnumber
            for iwndw = 1:cfg.wndwnumber
                for ifeature = 1:size(cfg.feature,2) %lat = 1 max =2 cauc = 3 sauc = 4
                    statmat = peakdata.(cfg.feature{ifeature});
                    statmat = squeeze(statmat(ireg,iwndw,:,:))';
                    [allit.(cfg.feature{ifeature}).pearson(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).ttest(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).CCC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).ICC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).SDC(ireg,iwndw,iit)] = lk_stats(statmat,cfg);
                    %FEATURE . REG x WNDW X iteration
                end
            end
        end
    end
    
    %FIND AVG AND STD OF EACH STAT AND FEATURE (reg and wndw at once)
    for ifeature = 1:size(cfg.feature,2) %lat = 1 max =2 cauc = 3 sauc = 4
        for istat = 1:size(cfg.stat,2)
            stats.(cfg.feature{ifeature}).(cfg.stat{istat}).mean(:,:,iTI) = mean(allit.(cfg.feature{ifeature}).pearson(:,:,:),3);
            % feature . statistic . reg x wndw x TI
            stats.(cfg.feature{ifeature}).(cfg.stat{istat}).std(:,:,iTI) = std(allit.(cfg.feature{ifeature}).pearson(:,:,:),0,3);
            % feature . statistic . reg x wndw x TI
        end
    end
    
end
    
end