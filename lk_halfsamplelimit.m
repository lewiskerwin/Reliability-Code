%THIS ONE USES AN 'ALLTRIALKEY' THAT RETAINS INDEXES IN FULL ARRAY OF ALL
%TRIALS

function [cfg,stats,data] = lk_halfsamplelimit(data,cfg)

rng(0,'twister');

cfg.bootnumber = (cfg.trialnumber*cfg.condnumber) / cfg.bootlength; 
%Divide total number of trials in biggest comparison (day vs day) by bootlength

clear halfsampleidx
%CYCLE THROUGH TRIAL NUMBERS 
%MUST CYCLE THROUGH TI BECAUSE SPLITS CHANGE AS FUNCTION OF TI
cfg.alltrialkey = zeros(cfg.trialnumber/cfg.trialincr,size(cfg.comparison,2),2,cfg.trialnumber*cfg.daynumber*cfg.condnumber/2);
for iTI = 1:floor(cfg.trialnumber/cfg.trialincr)
    cfg.trialmax = iTI*cfg.trialincr; %number of trials we're looking at here
    splitlength = cfg.trialmax/cfg.numsplit; %numsplit is set to 2 for code to work
    
    cfg.trialperdist = cfg.trialmax*cfg.condnumber*cfg.daynumber/2;%not relevant to this revision
    
    %CYCLE THROUGH COMPARISONS
    for icomparison =1:cfg.compnumber-1 %-1 b/c not including TI here
        switch cfg.comparison{icomparison}
            
            case 'alt'
                alternates = (0:cfg.numsplit:cfg.trialmax-cfg.numsplit)+1;
                %Get odds for all conditions and days with matrix addition!
                altsplitrange = alternates + cfg.trialnumber*(cfg.conditionforalt-1);
                for idist = 1:2;
                    cfg.alltrialkey(iTI,icomparison,idist,1:splitlength) =...
                        altsplitrange+(idist-1);
                end
                
            case 'split'
                splitrange = 1:splitlength + cfg.trialnumber*(cfg.conditionforsplit-1); % keep basic and update in loops below
                %ADD CFG HERE THAT RAISES SIZE. VARIABLE SHOULD BE HOW MANY
                %CONDS PER DIST (2 now with 2 days)
                for idist = 1:2;
                    cfg.alltrialkey(iTI,icomparison,idist,1:splitlength) = ...
                        splitrange+((idist-1)*splitlength);
                end
                
            case 'cond'
                for idist = 1:2;
                    condrange = (1:cfg.trialmax) + cfg.trialnumber*cfg.condnumber*(cfg.dayforcond-1);
                    cfg.alltrialkey(iTI,icomparison,idist,1:cfg.trialmax)  = condrange +((idist-1)*cfg.trialnumber);
                    %TI x comparison x distribution x trial
                end
                
                
            case 'day'
                %if ~exist(cfg.file.day{:}) break; else end;%If only one day, then don't do comparison between days
                dayrange = reshape((1:cfg.trialmax)' + (0:cfg.trialnumber:cfg.totaltrialnumber/cfg.daynumber-cfg.trialnumber),1,[]);
                for idist = 1:2;
                    cfg.alltrialkey(iTI,icomparison,idist,1:cfg.trialmax*cfg.condnumber) = dayrange + ((idist-1)*cfg.trialnumber*2);
                end
        end


        
    end
end



%MAKE 100 ITERATIONS WITH UNIQUE TRIAL ASSIGNMENT (USE iTI rather than
%indexing iboot)
%I dont' think I need iTI here!
clear halfsampleidx iterationtrialkey nonconcatidx peaktoavg
for iit = 1:cfg.itnumber
    for iboot = 1:cfg.bootnumber
        bootrange=[1:cfg.bootlength]+cfg.bootlength*(iboot-1);
        nonconcatidx(:,iboot) = datasample([bootrange],cfg.sampleperboot,'Replace',false);
      
    end
    halfsampleidx(iit,:) = reshape(nonconcatidx,[1 cfg.sampleperboot*cfg.bootnumber]);
    iterationtrialkey(:,:,:,:,iit) = cfg.alltrialkey(:,:,:,halfsampleidx(iit,:));
    %TI x comparison x dist x trial x it
end

%SHOW HOW EVENLY SAMPLING REPRESENTS TRIALS
iTI = 1;
cfg.trialmax = iTI*cfg.trialincr;
cfg.trialperdist= cfg.trialmax/2;
clear representation;
for itrial =1:cfg.trialperdist
    representation(itrial) = sum(sum(halfsampleidx(:,:)==itrial));
end
figure
bar(1:cfg.trialperdist,representation)
xticklabels(1:cfg.trialperdist);
xlabel('Trial');ylabel('frequency in iterations');



%CONCATENATE DATA SO THAT TRIAL KEY CAN BE APPLIED
dimensions = size(data.amp);
reshaped = reshape(data.amp,dimensions(1),dimensions(2),dimensions(3)*dimensions(4)*dimensions(5),dimensions(6));
%electrodes x time x trials x sub

%THIS CODE WORKS :@D for multiple days: reshaped(1,100,1,1) =reshaped(1,100,201,1)


%APPLY TRIAL KEY AND AVERAGE THE TRIALS TOGETHER
for iTIsubtractor = 1:cfg.TInumber
    iTI = cfg.TInumber+1-iTIsubtractor;
    
   cfg.trialmax = iTI*cfg.trialincr; %number of trials we're looking at here
    %cfg.trialperdist = cfg.trialmax*cfg.condnumber*cfg.daynumber/2;
    %trialperit = cfg.trialperdist/2;

    for icomparison = 1:cfg.compnumber-1 %-1 here because we don't cycle through for TI comparison
        clear peaktoavg allit
       
        switch icomparison
            case 1 %'alt'     
                trialperit = cfg.trialmax/(cfg.numsplit)*(cfg.sampleperboot/cfg.bootlength);
            case 2 %'split'     
                trialperit = cfg.trialmax/(cfg.numsplit)*(cfg.sampleperboot/cfg.bootlength);
            case 3 %'cond'     
                trialperit = cfg.trialmax*(cfg.sampleperboot/cfg.bootlength);
            case 4% 'day'    
                trialperit = cfg.trialmax*cfg.condnumber*(cfg.sampleperboot/cfg.bootlength);
        end

        
        for iit = 1:cfg.itnumber
            clear sorted trials
                
                trials = squeeze(iterationtrialkey(iTI,icomparison,:,:,iit));
                trials = trials(:,1:trialperit);
                sorted(:,:,1,:) = mean(reshaped(:,:,trials(1,:),:),3);
                sorted(:,:,2,:) = mean(reshaped(:,:,trials(2,:),:),3);
                %elec x ms x dist x sub
                
                %~~~ Eliminate this for loop by changing below function to
                %include feature in matrix
                [peakdata] = lk_findwndw_sortfirst(sorted,cfg); 
                %feature . reg x wndw x dist x sub 
                for ifeature = 1:size(cfg.feature,2)
                    peaktoavg(iit, ifeature, :,:,:,:) = peakdata.(cfg.feature{ifeature});
                    % it x feature x reg x wndw x dist x sub (don't need TI
                    % here since it's within a TI
                end
                     
                %NOW RUN STATS ON THIS PEAK DATA
                for ireg = 1:cfg.regnumber
                    for iwndw = 1:cfg.wndwnumber
                        for ifeature = 1:size(cfg.feature,2)
                            statmat = peakdata.(cfg.feature{ifeature});
                            statmat = squeeze(statmat(ireg,iwndw,:,:))';
                            [allit.(cfg.feature{ifeature}).pearson(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).tp(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).CCC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).ICC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).SDC(ireg,iwndw,iit)] =...
                             lk_stats(statmat,cfg);
                            
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
                stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).sem(:,:,iTI) =  ...
                    stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).std(:,:,iTI)/sqrt(cfg.itnumber);
            end
            
            data.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).mean(:,:,:,:,iTI) = squeeze(mean(peaktoavg(:, ifeature, :,:,:,:),1));
            %feature . comparison . reg x wndw x dist x sub x TI
            data.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).std(:,:,:,:,iTI) = squeeze(std(peaktoavg(:, ifeature,:,:,:,:),1));
            data.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).sem(:,:,:,:,iTI) = ...
                data.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).std(:,:,:,:,iTI)/sqrt(cfg.itnumber);
            %SAVE A MAT FOR MT QUANTIFICATION
            if (iTI == cfg.TInumber & icomparison == 3)
                data.(cfg.feature{ifeature}).MTcomp.mean(:,:,:,:,cfg.dayforcond) = data.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).mean(:,:,:,:,iTI);
                data.(cfg.feature{ifeature}).MTcomp.sem(:,:,:,:,cfg.dayforcond) = data.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).sem(:,:,:,:,iTI);
                %feature . reg x wndw x dist x sub x day
             else; end
        end
        
        %NOW SAVE ITERATIONS IF THE COMPARISON IS COND vs COND (FOR CAMMIE
        %MULTIPLE DAYS WILL NOT BE LUMPED TOGETHER)
        if icomparison ==3
            dims = size(peaktoavg);
            
            if strcmp(cfg.ProjectName, 'vlpfc_TBS')
                trialcomparisondata(:,:,:,:,:,iTI) = peaktoavg(:,:, :,:,1,:); %CHange to 2 to observe left side!
            else
                trialcomparisondata(:,:,:,:,:,iTI) = reshape(peaktoavg(:,:, :,:,:,:),dims(1),dims(2),dims(3),dims(4),dims(5)*dims(6));
            end
           %it x feature  x(not comparison b/c only one icomp) x reg x wndw x conds(concatenated) x TI
        
            %POSSIBLY HERE I CAN COUNT DOWN AND COMPARE EACH TI WITH 120 (OR
            %MAXIMUM)
            for iit = 1:cfg.itnumber %have to re-enter this loop because must finish all iterations on multiple TI
                for ireg = 1:cfg.regnumber
                    for iwndw = 1:cfg.wndwnumber
                        for ifeature = 1:size(cfg.feature,2)
                            clear statmat
                            statmat(:,1) = trialcomparisondata(iit,ifeature,ireg,iwndw,:,iTI);
                            statmat(:,2) = trialcomparisondata(iit,ifeature,ireg,iwndw,:,cfg.TInumber);
                            [allit.(cfg.feature{ifeature}).pearson(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).day(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).CCC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).ICC(ireg,iwndw,iit), allit.(cfg.feature{ifeature}).SDC(ireg,iwndw,iit)] = lk_stats(statmat,cfg);
                            
                        end
                    end
                end
            end
            
            %NOW AS BEFORE APPLY STATS TO THIS
            for ifeature = 1:size(cfg.feature,2) %lat = 1 max =2 cauc = 3 sauc = 4
                for istat = 1:size(cfg.stat,2)
                    stats.(cfg.feature{ifeature}).TI.(cfg.stat{istat}).mean(:,:,iTI) = mean(allit.(cfg.feature{ifeature}).(cfg.stat{istat}),3);
                    % feature . comparison(TI here) . statistic . reg x wndw x TI
                    stats.(cfg.feature{ifeature}).TI.(cfg.stat{istat}).std(:,:,iTI) = std(allit.(cfg.feature{ifeature}).(cfg.stat{istat}),0,3);
                    % feature . comparison(TI here) . statistic . reg x wndw x TI
                    stats.(cfg.feature{ifeature}).TI.(cfg.stat{istat}).sem(:,:,iTI) = ...
                        stats.(cfg.feature{ifeature}).TI.(cfg.stat{istat}).std(:,:,iTI)/sqrt(cfg.itnumber);
                end
            end
        else %i.e. if this icomparison is not condition vs condition 
        end
        
    end
    
   
    
end
%NOW THAT WE'VE DONE ALL TRIAL INTERVALS, LOAD THEM INTO ONE BIG DATA
%MATRIX (MAY BE ABLE TO MAKE MORE EFFICIENT)
for ifeature = 1:size(cfg.feature,2)
   
    data.(cfg.feature{ifeature}).TI.mean = permute(squeeze(mean(trialcomparisondata(:, ifeature, :,:,:,:),1)),[1 2 4 3]);
    %feature . comparison(TI in this case) . reg x wndw x dist(iTI here) x
    %conditions (all subs concatenated)
    data.(cfg.feature{ifeature}).TI.std = permute(squeeze(std(trialcomparisondata(:, ifeature, :,:,:,:),1)),[1 2 4 3]);
    data.(cfg.feature{ifeature}).TI.sem = data.(cfg.feature{ifeature}).TI.std / sqrt(cfg.itnumber);
   
end


end
    


