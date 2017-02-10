%THIS ONE USES AN 'ALLTRIALKEY' THAT RETAINS INDEXES IN FULL ARRAY OF ALL
%TRIALS

function [stats, data] = lk_halfsampletp_forcammie(data,cfg)

rng(0,'twister');

cfg.bootnumber= cfg.trialnumber*cfg.condnumber*cfg.tpnumber/(2*cfg.trialincr); %Have exactly one boot per ten trials (i.e per one block)

clear halfsampleidx
%CYCLE THROUGH TRIAL NUMBERS
%MUST CYCLE THROUGH TI BECAUSE SPLITS CHANGE AS FUNCTION OF TI
alltrialkey = zeros(cfg.trialnumber/cfg.trialincr,size(cfg.comparison,2),2,cfg.trialnumber*cfg.tpnumber*cfg.condnumber/2);
for iTI = 1:floor(cfg.trialnumber/cfg.trialincr)
    cfg.trialmax = iTI*cfg.trialincr; %number of trials we're looking at here
    splitlength = cfg.trialmax/cfg.numsplit; %numsplit is set to 2 for code to work
    
    cfg.trialperdist = cfg.trialmax*cfg.condnumber*cfg.tpnumber/2;
    cfg.sampleperboot = cfg.trialincr/2; % For each boot, take 50%
    cfg.itnumber=100; %100 interations
    bootlength = cfg.trialincr; %Always 10 with half-sampling
    %featureddata = data.(cfg.feature{feature});
    
    %CYCLE THROUGH COMPARISONS
    for icomparison =1:size(cfg.comparison,2)
        switch cfg.comparison{icomparison}
            
            case 'cond'
                for idist = 1:2;
                    condrange = reshape((1:cfg.trialmax)' + (0:cfg.tpnumber-1)*(cfg.trialnumber*cfg.condnumber),1,[]);
                    alltrialkey(iTI,icomparison,idist,1:cfg.trialperdist)  = condrange +((idist-1)*cfg.trialnumber);
                    %TI x comparison x distribution x trial
                end
                
            case 'split'
                splitlength = cfg.trialmax/cfg.numsplit;
                splitrange = reshape((1:splitlength)'+(0:cfg.trialnumber:cfg.totaltrialnumber-cfg.trialnumber),1,[]); % keep basic and update in loops below
                %ADD CFG HERE THAT RAISES SIZE. VARIABLE SHOULD BE HOW MANY
                %CONDS PER DIST (2 now with 2 tps)
                for idist = 1:2;
                    alltrialkey(iTI,icomparison,idist,1:cfg.trialperdist) = ...
                        splitrange+((idist-1)*splitlength);
                end
                
            case 'alt'
                alternates = (0:cfg.numsplit:cfg.trialmax-cfg.numsplit)+1;
                %Get odds for all conditions and tps with matrix addition!
                altsplitrange = reshape(alternates' + (0:cfg.trialnumber:cfg.totaltrialnumber-cfg.trialnumber),1,[]);
                for idist = 1:2;
                    alltrialkey(iTI,icomparison,idist,1:cfg.trialperdist) =...
                        altsplitrange+(idist-1);
                end
                
                
                
            case 'timepoint'
                if cfg.tpnumber>1
                    tprange = reshape((1:cfg.trialmax)' + (0:cfg.trialnumber:cfg.totaltrialnumber/cfg.tpnumber-cfg.trialnumber),1,[]);
                    for idist = 1:2;
                        alltrialkey(iTI,icomparison,idist,1:cfg.trialperdist) = tprange +((idist-1)*cfg.trialnumber*2);
                    end
                else break
                end
        end
    end
end



%MAKE 100 ITERATIONS WITH UNIQUE TRIAL ASSIGNMENT (USE iTI rather than
%indexing iboot)
%I dont' think I need iTI here!
clear halfsampleidx iterationtrialkey nonconcatidx
for iit = 1:cfg.itnumber
    for iboot = 1:cfg.bootnumber
        bootrange=[1:bootlength]+bootlength*(iboot-1);
        nonconcatidx(:,iboot) = datasample([bootrange],cfg.sampleperboot,'Replace',false);
        
    end
    halfsampleidx(iit,:) = reshape(nonconcatidx,1, cfg.sampleperboot*cfg.bootnumber);
    iterationtrialkey(:,:,:,:,iit) = alltrialkey(:,:,:,halfsampleidx(iit,:));
    %TI x comparison x dist x trial x it
end


%CONCATENATE DATA SO THAT TRIAL KEY CAN BE APPLIED
dimensions = size(data.amp);
switch size(dimensions,2)
    case 5
         
        %Unique to cammie's code, this looks at onlh the right sided data.
        reshaped = data.amp(:,:,:,1,:);
     
        %NOTE BELWO LINE IS FOR CAMMIES CODE WHERE CONDITONS ARE TOTALLY
        %DIFFERENT
        %reshaped = reshape(data.amp,dimensions(1),dimensions(2),dimensions(3),dimensions(4)*dimensions(5));
        %electrodes x time x trials x data points (sub and condition
        %concatenated)

    case 6
        reshaped = reshape(data.amp,dimensions(1),dimensions(2),dimensions(3)*dimensions(4)*dimensions(5),dimensions(6));
end
%electrodes x time x trials(all conditions and tps concatenated) x sub

%THIS CODE WORKS :@D for multiple tps: reshaped(1,100,1,1) =reshaped(1,100,201,1)


%APPLY TRIAL KEY AND AVERAGE THE TRIALS TOGETHER - HERE's WHERE DIFF FOR
%CAMMIE
icomparison = 1; %For this each timepoint is a data point
trialperit = cfg.TItocompare*cfg.trialincr*cfg.condnumber*cfg.tpnumber/2/2; %Divide once for half sampling and another to break data into two dist

% for iTI = 1:length(TItocompare)
%     clear trials
%    cfg.trialmax = TItocompare(iTI)*cfg.trialincr; %number of trials we're looking at here
%     cfg.trialperdist = cfg.trialmax*cfg.condnumber*cfg.tpnumber/2;
%     trialperit(iTI) = cfg.trialperdist/2; %for cammie code this is an array because need to reference two TIs at once
%     trials = squeeze(iterationtrialkey(:,icomparison,:,:,:));
%                 trials = trials(:,1:trialperit);
% end
%for icomparison = 1:size(cfg.comparison,2)
clear allit peakdata peaktoavg
for iit = 1:cfg.itnumber
    clear sorted
    for iTI=1:length(cfg.TItocompare)
        clear itrials
        itrials = squeeze(iterationtrialkey(cfg.TItocompare(iTI),icomparison,:,:,iit));
        itrials = itrials(:,1:trialperit(iTI));
        sorted(:,:,iTI,:) = mean(reshaped(:,:,itrials(1,:),:),3);
        %UNIQUE TO CAMMIE, WE'RE ONLY PICKING RIGHT SIDED DATA HERE
        %(itrials(1,:))
        
        %Elec x time x TI x sub
    end
    
    
    [peakdata] = lk_findwndw_sortfirst(sorted,cfg);
    %iteration x feature . reg x wndw x dist(TI in this case) x sub
    
    %ADD THESE AVERAGED PEAK DATA TO A MATRIX THAT WE WILL LATER AVG ACROSS
    %ITERATIONS
    for ifeature = 1:size(cfg.feature,2)
        peaktoavg(iit, ifeature, :,:,:,:) = peakdata.(cfg.feature{ifeature});
    end
    
    %NOW RUN STATS ON THIS PEAK DATA
    for iTI = 1:length(cfg.TItocompare)-1
        for jTI = iTI+1:length(cfg.TItocompare)
           
            for ireg = 1:cfg.regnumber
                for iwndw = 1:cfg.wndwnumber
                    for ifeature = 1:size(cfg.feature,2)
                        allregstatmat = peakdata(iit).(cfg.feature{ifeature});
                        statmat = squeeze(allregstatmat(ireg,iwndw,[iTI jTI],:))';
                        % 2 TIs (iTI and jTI) x n subs
                        [allit.(cfg.feature{ifeature}).pearson(ireg,iwndw,iit,iTI,jTI), allit.(cfg.feature{ifeature}).tp(ireg,iwndw,iit,iTI,jTI), allit.(cfg.feature{ifeature}).CCC(ireg,iwndw,iit,iTI,jTI), allit.(cfg.feature{ifeature}).ICC(ireg,iwndw,iit,iTI,jTI), allit.(cfg.feature{ifeature}).SDC(ireg,iwndw,iit,iTI,jTI)] = lk_stats(statmat,cfg);
                    end
                end
            end
            
            
        end
    end
    
end


%NOW ITERATIONS ALL DONE, FIND AVG AND STD OF EACH STAT AND FEATURE (reg and wndw at once)
for ifeature = 1:size(cfg.feature,2) %lat = 1 max =2 cauc = 3 sauc = 4
    for istat = 1:size(cfg.stat,2)
        stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).mean = mean(allit.(cfg.feature{ifeature}).(cfg.stat{istat}),3);
        % feature . statistic . reg x wndw x TI
        stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).std = std(allit.(cfg.feature{ifeature}).(cfg.stat{istat}),0,3);
        % feature . statistic . reg x wndw x TI
    end
    
    data.(cfg.feature{ifeature}) = [];
    data.(cfg.feature{ifeature}).mean = squeeze(mean(peaktoavg(:, ifeature, :, :,:,:),1));
    %feature . reg x wndw x dist(TI in this case) x sub
    data.(cfg.feature{ifeature}).std = squeeze(std(peaktoavg(:, ifeature, :, :,:,:),1));
    
end


%end
%end


end



