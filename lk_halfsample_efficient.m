function [stats] = lk_halfsample_thenpeak(reliability,cfg,icomparison)

rng(0,'twister');

    cfg.bootnumber= cfg.trialnumber/cfg.trialincr; %Have exactly one boot per ten trials (i.e per one block)


clear halfsampleidx
%CYCLE THROUGH TRIAL NUMBERS 
%MUST CYCLE THROUGH TI BECAUSE SPLITS CHANGE AS FUNCTION OF TI
alltrialkey = zeros(cfg.trialnumber/cfg.trialincr,size(cfg.comparison,2),2,cfg.trialnumber);
for iTI = 1:floor(cfg.trialnumber/cfg.trialincr)
    cfg.trialmax = iTI*cfg.trialincr; %number of trials we're looking at here
    splitlength = cfg.trialmax/cfg.numsplit; %numsplit is set to 2 for code to work
    
    cfg.sampleperboot = cfg.trialincr/2; % For each boot, take 50%
    cfg.itnumber=100; %100 interations
    bootlength = cfg.trialincr; %Always 10 with half-sampling
    %featureddata = reliability.(cfg.feature{feature});
    
    %CYCLE THROUGH COMPARISONS
    for icomparison =1:size(cfg.comparison,2)
        switch cfg.comparison{icomparison}
        
        case 'cond'
            for idist = 1:2;
                alltrialkey(iTI,icomparison,idist,1:iTI*cfg.trialincr) = (1:cfg.trialmax)+((idist-1)*cfg.trialmax);
                %TI x comparison x distribution x trial
            end
            
        case 'split'
            splitlength = cfg.trialmax/cfg.numsplit;
            splitrange = 1:splitlength; % keep basic and update in loops below
            for idist = 1:2; 
                alltrialkey(iTI,icomparison,idist,1:iTI*cfg.trialincr) = ...
                    [splitrange+((idist-1)*splitlength) splitrange+((idist-1)*splitlength)+cfg.trialmax];     
            end
            
        case 'alt'
            altsplitrange = (0:cfg.numsplit:cfg.trialmax-cfg.numsplit)+1;
            for idist = 1:2; 
                alltrialkey(iTI,icomparison,idist,1:iTI*cfg.trialincr) =...
                    [altsplitrange+(idist-1) altsplitrange+(idist-1)+cfg.trialmax];     
            end
           
        end
    end
    
end

    %MAKE 100 ITERATIONS WITH UNIQUE TRIAL ASSIGNMENT (USE iTI rather than
    %indexing iboot)
  %I dont' think I need iTI here!

for iit = 1:cfg.itnumber
   for iboot = 1:cfg.bootnumber
   bootrange=[1:bootlength]+bootlength*(iboot-1);
       nonconcatidx(:,iboot) = datasample([bootrange],cfg.sampleperboot,'Replace',false);
   
   end
   halfsampleidx(iit,:) = reshape(nonconcatidx,[1 cfg.sampleperboot*cfg.bootnumber]);
   iterationtrialkey(:,:,:,:,iit) = alltrialkey(:,:,:,halfsampleidx(iit,:));
   %TI x comparison x dist x trial x it
end


%now that we have key
%AVERAGE TOGETHER TRIALS
permuted = permute(reliability.amp(:,:,:,:,:),[1 2 5 4 3]);
reshape(relability.amp
for iTI = 1:floor(cfg.trialnumber/cfg.trialincr);
    dimensions = size(reliability.amp(:,:,1:iTI*cfg.trialincr,:,:));
    trialspersub = dimensions(3)*dimensions(4);
    reliability.ampcat(:,:,1:iTI*cfg.trialincr*cfg.condnumber,:)=...
        reshape(reliability.amp(:,:,1:iTI*cfg.trialincr,:,:),dimensions(1),dimensions(2),trialspersub,dimensions(5))
    
    
    for icomparison = 1:size(cfg.comparison,2)
        for idist = 1:2
            for iit = 1:cfg.itnumber
                trials = squeeze(iterationtrialkey(iTI,icomparison,idist,:,iit));
                trials(trials==0) = [];
               % reliability.amp(:,:,trials,:)
                
                
            end
        end
    end
end
          

iterationtrialkey(iTI,icomparison,idist,:,iit

  for iTI =1:cfg.trialnumber/cfg.trialincr
      for iit = 1:cfg.itnumber
          %halfsampleidx(iit,:) =   datasample([1:bootlength],cfg.sampleperboot,'Replace',false)+ ((iTI-1)*bootlength);
          %Now that I have a table of indeces for each iteration, I just
          %need to make a new matrix with dimension for iteration where
          %each iteration (for given TI, comparison, distribution) has a particular vector of trials. 
          alltrialkey(iTI,:,:,halfsampleidx(iit,:))
          
          %Then Look of the waveforms for each of these (WILL NEED LOOP)
          %and average over each to get avg waveform (do NOT LOOP reg,
          %wndw, sub)
      end
  end

%NOW THAT ALL TI SAMPLED, REARRANGE
halfsampleidx = reshape(halfsampleidx, [cfg.itnumber, cfg.sampleperboot*cfg.bootnumber]);
    %iteration x 50trialidx 

    
    
    %%%%%%%%

alltrialkey(:,:,:,halfsampleidx(:,:))    
    
    %CYCLE THROUGH ITERATIONS - THIS ALLOWS ME TO PUT REG AND WINDW IN
    %FUNCTION wndwsortfirst
    for iit =1:cfg.itnumber
        sorted = squeeze(mean(prebindata(:,:,samplekey(iit,:),:,:),3));
        %CHAN X TIME X COND/SPLIT/ALT X SUB
        
        
        %FIND LATENCY, AMPLITUDE, AND TWO TYPES OF AUC (FOR THIS IT AND TI)
        [peakdata] = lk_findwndw_sortfirst(sorted,cfg);
        
        %NOW RUN STATS ON THIS PEAK DATA
        for ireg = 1:cfg.regnumber
            for iwndw = 1:cfg.wndwnumber
                for ifeature = 1:size(cfg.feature,2) %lat = 1 max =2 cauc = 3 sauc = 4
                    statmat = peakdata.(cfg.feature{ifeature});
                    statmat = squeeze(statmat(ireg,iwndw,:,:))';
                    [allit.(cfg.feature{ifeature}).pearson(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).tp(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).CCC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).ICC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).SDC(ireg,iwndw,iit)] = lk_stats(statmat,cfg);
                    %FEATURE . REG x WNDW X iteration
                end
            end
        end
    end
    
    %NOW ITERATIONS ALL DONE, FIND AVG AND STD OF EACH STAT AND FEATURE (reg and wndw at once)
    for ifeature = 1:size(cfg.feature,2) %lat = 1 max =2 cauc = 3 sauc = 4
        for istat = 1:size(cfg.stat,2)
            stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).mean(:,:,iTI) = mean(allit.(cfg.feature{ifeature}).(cfg.stat{istat}),3);
            % feature . statistic . reg x wndw x TI
            stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).std(:,:,iTI) = std(allit.(cfg.feature{ifeature}).(cfg.stat{istat}),0,3);
            % feature . statistic . reg x wndw x TI
        end
    end
    
end
    
end

