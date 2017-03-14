%THIS ONE USES AN 'ALLTRIALKEY' THAT RETAINS INDEXES IN FULL ARRAY OF ALL
%TRIALS

function [stats] = lk_halfsample(data,cfg)

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
    %featureddata = data.(cfg.feature{feature});
    
    %CYCLE THROUGH COMPARISONS
    for icomparison =1:size(cfg.comparison,2)
        switch cfg.comparison{icomparison}
        
        case 'cond'
            for idist = 1:2;
                alltrialkey(iTI,icomparison,idist,1:iTI*cfg.trialincr) = (1:cfg.trialmax)+((idist-1)*cfg.trialnumber);
                %TI x comparison x distribution x trial
            end
            
        case 'split'
            splitlength = cfg.trialmax/cfg.numsplit;
            splitrange = 1:splitlength; % keep basic and update in loops below
            for idist = 1:2; 
                alltrialkey(iTI,icomparison,idist,1:iTI*cfg.trialincr) = ...
                    [splitrange+((idist-1)*splitlength) splitrange+((idist-1)*splitlength)+cfg.trialnumber];     
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
%permuted = permute(data.amp(:,:,:,:,:),[1 2 5 4 3]);
dimensions = size(data.amp);
reshaped = reshape(data.amp,dimensions(1),dimensions(2),dimensions(3)*dimensions(4),dimensions(5));

for iTI = 1:floor(cfg.trialnumber/cfg.trialincr);
    %dimensions = size(data.amp(:,:,1:iTI*cfg.trialincr,:,:));
    % trialspersub = dimensions(3)*dimensions(4);
    %data.ampcat(:,:,1:iTI*cfg.trialincr*cfg.condnumber,:)=...
    %reshape(data.amp(:,:,1:iTI*cfg.trialincr,:,:),dimensions(1),dimensions(2),trialspersub,dimensions(5))
    for icomparison = 1:size(cfg.comparison,2)
        for iit = 1:cfg.itnumber
            clear sorted
                
                trials = squeeze(iterationtrialkey(iTI,icomparison,:,:,iit));
                trials = trials(:,1:(iTI*5));
                sorted(:,:,1,:) = mean(reshaped(:,:,trials(1,:),:),3);
                sorted(:,:,2,:) = mean(reshaped(:,:,trials(2,:),:),3);
                %elec x ms x dist x sub
                
                [peakdata] = lk_findwndw_sortfirst(sorted,cfg);
                %feature . reg x wndw x dist x sub 
                     
                %NOW RUN STATS ON THIS PEAK DATA
                for ireg = 1:cfg.regnumber
                    for iwndw = 1:cfg.wndwnumber
                        for ifeature = 1:size(cfg.feature,2)
                            statmat = peakdata.(cfg.feature{ifeature});
                            statmat = squeeze(statmat(ireg,iwndw,:,:))';
                            [allit.(cfg.feature{ifeature}).pearson(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).tp(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).CCC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).ICC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).SDC(ireg,iwndw,iit)] = lk_stats(statmat,cfg);
                            
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


end
    


