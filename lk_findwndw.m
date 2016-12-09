function [amplat, avgamplat] = lk_findwndw(reliability,cfg)

clear lat amplat

for iTI = 1:cfg.trialnumber/cfg.trialincr
    
    
    for ireg = 1:size(cfg.regs,2)
        for isub = 1:size(cfg.file.subs)
            
            %These are the arrays of peak locations and peak amplitudes that are near each PEAK
            
            for iPEAK = 1:length(cfg.peak.target) %Go through each PEAK (e.g. 50, 100 200)
                %Find peaks of all splits and conds combined
                wider= 0;
                clear loc; peak = [];
                alltimes = reliability.times(:,1,isub);
                while 1
                    targettimerange = [cfg.peak.target(iPEAK)-cfg.peak.wiggle(iPEAK)-wider, cfg.peak.target(iPEAK)+cfg.peak.wiggle(iPEAK)+wider];
                    targettimeidx = find( alltimes >= targettimerange(1) & alltimes <= targettimerange(2));
                    targetdata = double(abs(mean(mean(mean(reliability.amp(cfg.regs(ireg).chan,targettimeidx,1:iTI*floor(cfg.trialnumber/cfg.trialincr),:,isub),1),3),4)'));
                    %temporarily took out smoothing
                    %targetdata = smooth(double(abs(mean(mean(reliability.amp(cfg.regs(ireg).chan,targettimeidx,:,icond,isub),1),3)')),5);
                    [peak, loc] = findpeaks(targetdata);
                    if isempty(peak) wider = wider +5;
                    else break; end
                end
                [bestpeak, bestidx] = max(peak);
                bestloc = loc(bestidx);
                avgamplat(ireg,iPEAK,isub,iTI) = bestloc-1 + (cfg.peak.target(iPEAK)-cfg.peak.wiggle(iPEAK));
                
                %Now find peak latencies for each individual split
                %based off avg
                for icond = 1:size(cfg.file.preconds)
                    
                    for isplit = 1:cfg.numsplit
                        splitrange = ((isplit-1)*iTI*cfg.trialincr/cfg.numsplit)+1:isplit*iTI*cfg.trialincr/cfg.numsplit;
                        
                        wider= 0;
                        clear loc; peak = [];
                        alltimes = reliability.times(:,icond,isub);
                        while 1
                            newpeaktarget = avgamplat(ireg,iPEAK,isub,iTI);
                            targettimerange = [newpeaktarget-cfg.peak.precision(iPEAK)-wider, newpeaktarget+cfg.peak.precision(iPEAK)+wider];
                            targettimeidx = find( alltimes >= targettimerange(1) & alltimes <= targettimerange(2));
                            targetdata = smooth(double(abs(mean(mean(reliability.amp(cfg.regs(ireg).chan,targettimeidx,splitrange,icond,isub),1),3)')),10);
                            [peak, loc] = findpeaks(targetdata);
                            if isempty(peak) wider = wider +5;
                            else break; end
                        end
                        [bestpeak, bestidx] = max(peak);
                        bestloc = loc(bestidx);
                        
                        amplat(ireg,iPEAK,isplit,icond,isub,iTI) = bestloc-1 + (newpeaktarget-cfg.peak.precision(iPEAK));
                        %QC
                        %plot(targettimerange(1):targettimerange(2),targetdata)
                    end
                    
                    %Now delcare new latencies (one is added here because the
                    %index of peak #150 is 1 so the index of best peak is one
                    %more than its distance from the bottom of targettimerange
                    
                end
            end
        end
    end
end

end